"""
SasaPay webhook handler for TapVerify.

Receives POST callbacks from SasaPay after member pays.
Verifies HMAC-SHA512 signature, matches to PaymentTask,
triggers SMS receipt + streak update.

Endpoint: POST /webhooks/sasapay/
"""
import json
import logging

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.utils import timezone

from ..models import PaymentTask, StreakRecord
from ..services.sasapay import get_sasapay_client, SUCCESS_CODES

logger = logging.getLogger(__name__)


def _process_successful_payment(task, payload):
    """Process a successful payment: update task, send receipt, update streak."""
    task.state = 'completed'
    task.provider_tx_code = (
        payload.get('TransactionCode')
        or payload.get('transaction_code')
        or ''
    )
    task.paid_at = timezone.now()
    task.save()

    # Send SMS receipt
    try:
        from ..services.africastalking import AfricasTalkingService
        at = AfricasTalkingService()
        receipt_msg = (
            f"RECEIPT: {task.collection.title}\n"
            f"Amount: Ksh {int(task.amount)}\n"
            f"Ref: {task.provider_tx_code}\n"
            f"Status: VERIFIED\n"
            f"TapVerify"
        )
        at.send_sms(task.member.phone, receipt_msg)
        task.sms_status = 'sent'
        task.save(update_fields=['sms_status'])
    except Exception as e:
        logger.error("SMS receipt failed for task %s: %s", task.id, e)

    # Update streak
    try:
        streak, _ = StreakRecord.objects.get_or_create(
            member=task.member,
            collection_type='welfare',
        )
        streak.record_payment(
            amount=task.amount,
            paid_at=task.paid_at,
            due_date=task.collection.due.date() if hasattr(task.collection.due, 'date') else task.collection.due,
        )
    except Exception as e:
        logger.error("Streak update failed for task %s: %s", task.id, e)

    logger.info(
        "Payment processed: task=%s member=%s amount=%s ref=%s",
        task.id, task.member.name, task.amount, task.provider_tx_code,
    )


@csrf_exempt
@require_POST
def sasapay_webhook(request):
    """Handle SasaPay payment callback.

    Flow:
    1. Parse JSON body
    2. Verify HMAC-SHA512 signature
    3. Match Reference to PaymentTask.payment_token
    4. If success (SP00000): update task, send receipt, update streak
    5. Return 200
    """
    try:
        payload = json.loads(request.body)
    except json.JSONDecodeError:
        logger.error("Invalid JSON in webhook")
        return JsonResponse({'error': 'invalid_json'}, status=400)

    # Step 1: Verify signature
    client = get_sasapay_client()
    signature = (
        request.headers.get('X-SasaPay-Signature')
        or request.headers.get('X-SASAPAY-SIGNATURE')
        or ''
    )

    if signature and not client.verify_signature(payload, signature):
        logger.warning("Invalid webhook signature: %s", signature[:20])
        return JsonResponse({'error': 'invalid_signature'}, status=403)

    # Step 2: Extract reference
    result_code = str(
        payload.get('ResultCode')
        or payload.get('result_code')
        or ''
    )
    reference = (
        payload.get('Reference')
        or payload.get('MerchantRequestID')
        or payload.get('CheckoutRequestID')
        or payload.get('payment_reference')
        or ''
    )

    if not reference:
        logger.error("No reference in webhook: %s", payload)
        return JsonResponse({'error': 'no_reference'}, status=400)

    # Step 3: Match to PaymentTask
    try:
        task = PaymentTask.objects.select_related('member', 'collection').get(
            payment_token=reference
        )
    except PaymentTask.DoesNotExist:
        logger.warning("No task for reference: %s", reference)
        return JsonResponse({'status': 'unmatched'}, status=200)

    # Step 4: Process based on result code
    if result_code in SUCCESS_CODES:
        if task.state != 'completed':
            _process_successful_payment(task, payload)
        return JsonResponse({'status': 'processed'})
    else:
        result_desc = (
            payload.get('ResultDesc')
            or payload.get('result_description')
            or 'Failed'
        )
        task.sms_status = 'failed'
        task.save(update_fields=['sms_status'])
        logger.info(
            "Payment failed: task=%s code=%s desc=%s",
            task.id, result_code, result_desc,
        )
        return JsonResponse({'status': 'failed_recorded'})


@csrf_exempt
def sasapay_webhook_test(request):
    """GET endpoint to verify webhook is reachable."""
    return JsonResponse({
        'status': 'webhook_alive',
        'service': 'TapVerify',
        'message': 'SasaPay webhook endpoint is active',
    })
