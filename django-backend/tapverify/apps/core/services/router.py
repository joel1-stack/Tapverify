"""
PaymentRouter — orchestrates the full TapVerify flow.

One entrypoint drives the whole money journey:

    raise_collection()  →  create per-worker checkouts on the configured rail
                          →  deliver each checkout link over AT Bulk SMS
    verify_webhook()    →  HMAC-verified rail callback
                          →  advance the task through the 9-state lifecycle
                          →  award streak/badge (Avalanche attestation)
                          →  trigger the Airtime reward at 3-month streaks

The router is provider-agnostic: it delegates each step to a rail adapter
(SasaPay) and to the AT + Avalanche adapters, so swapping a
rail never changes the lifecycle logic.
"""
import logging
import uuid

from django.utils import timezone

from .payment_rail import get_payment_rail
from .africastalking import AfricasTalkingService, build_collection_sms
from .avalanche import AvalancheService, build_badge_attestation

logger = logging.getLogger(__name__)

RESTRICTED = ['streak', 'badge', 'reward']


class PaymentRouter:
    def __init__(self, rail_name=None):
        self.rail = get_payment_rail(rail_name)
        self.sms = AfricasTalkingService()
        self.avax = AvalancheService()

    # ── Raise a collection: checkout links + SMS to every worker ─────────
    def raise_collection(self, collection):
        """For each unpaid task, create a checkout and send the SMS link."""
        sent = 0
        for task in collection.tasks.filter(state='created'):
            reference = f"TV-{uuid.uuid4().hex[:10].upper()}"
            result = self.rail.initiate_payment(
                phone=task.member.phone,
                amount=float(task.amount),
                reference=reference,
                description=collection.title,
            )
            if not result.get('success'):
                logger.warning("checkout failed for %s: %s",
                               task.member.phone, result.get('error'))
                continue
            checkout_url = (result.get('checkout_url')
                            or result.get('url') or reference)
            task.txn_ref = reference
            task.rail = self.rail.get_rail_name()
            task.state = 'notified'
            task.save(update_fields=['txn_ref', 'rail', 'state'])

            msg = build_collection_sms(
                task, checkout_url=checkout_url,
                workspace_name=collection.workspace.name,
                amount=float(task.amount),
            )
            ok, msg_id, err = self.sms.send_sms(task.member.phone, msg)
            if ok:
                sent += 1
            else:
                logger.warning("SMS failed for %s: %s", task.member.phone, err)

        collection.sms_sent = True
        collection.save(update_fields=['sms_sent'])
        return {'checkouts': collection.tasks.filter(state='notified').count(),
                'sms_sent': sent}

    # ── Incoming rail webhook ─────────────────────────────────────────────
    def handle_webhook(self, payload, headers):
        """Verify a rail callback, then run the lifecycle + reward engine."""
        result = self.rail.verify_webhook(payload, headers)
        if not result.get('valid'):
            return {'accepted': False, 'reason': 'invalid_signature'}

        from ..models import PaymentTask
        reference = result.get('reference')
        if not reference:
            return {'accepted': False, 'reason': 'missing_reference'}

        try:
            task = PaymentTask.objects.get(txn_ref=reference)
        except PaymentTask.DoesNotExist:
            logger.warning("webhook reference not found: %s", reference)
            return {'accepted': True, 'matched': False}

        outcome = self._advance_task(task, result)
        return {'accepted': True, 'matched': True, **outcome}

    # ── Lifecycle + rewards ───────────────────────────────────────────────
    def _advance_task(self, task, result):
        task.state = 'completed'
        task.paid_at = timezone.now()
        if result.get('receipt_number'):
            task.txn_ref = f"{task.txn_ref}-{result['receipt_number']}"
        task.save()

        streak = self._compute_streak(task.member)
        bonus = {}
        if streak >= 3:
            badge = build_badge_attestation(task, task.member, streak)
            mint = self.avax.mint_badge(badge['attestation_hash'])
            if mint.get('success'):
                task.state = 'badge'
                task.save()
            bonus['badge'] = badge
            bonus['attestation'] = mint

            if streak % 3 == 0:
                airtime = self.sms.send_airtime(task.member.phone, 50)
                bonus['airtime'] = airtime
                task.state = 'reward'
                task.save()
        elif streak > 0:
            task.state = 'streak'
            task.save()

        return {'state': task.state, 'streak_months': streak, **bonus}

    @staticmethod
    def _compute_streak(member):
        """Months of on-time payment for this member (min 1 when paid)."""
        from ..models import PaymentTask
        paid = member.payment_tasks.filter(
            state__in=['completed', 'verified', 'streak', 'badge', 'reward'])
        return max(1, paid.count())


def get_router(rail_name=None):
    return PaymentRouter(rail_name)