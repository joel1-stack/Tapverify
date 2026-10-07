"""TapVerify V1 API + member payment pages.

Secretary API (Bearer token):
    POST /api/auth/otp/                      request login code
    POST /api/auth/verify/                   verify code, get token
    POST /api/auth/register/                 create account, then send OTP
    GET  /api/me/                            session check + profile
    GET  /api/collections/                   my collections + stats
    POST /api/collections/                   create + notify everyone
    GET  /api/collections/<id>/              live list
    POST /api/collections/<id>/remind-unpaid/
    GET  /api/collections/<id>/export.csv
    POST /api/members/<id>/mark-paid/        {method: cash|other}
    POST /api/members/<id>/remind/
    POST /api/members/<id>/stk-push/         request M-Pesa STK push

Public (no login - the member experience):
    GET  /p/<pay_code>/                      member payment page (HTML)
    GET  /api/p/<pay_code>/                  payment info (JSON)
    POST /api/p/<pay_code>/pay/              start M-Pesa payment (STK Push)
    POST /api/webhooks/mpesa/                Daraja STK result
    POST /api/webhooks/sasapay/              payment notifications
"""
import csv
import logging
import random
from datetime import date, timedelta
from decimal import Decimal, InvalidOperation

from django.conf import settings
from django.http import HttpResponse
from django.shortcuts import render
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Collection, LoginOTP, Member, Payment, Secretary, new_token
from .services import sms
from .services.mpesa import get_mpesa_client, parse_callback
from .services.sasapay import get_sasapay_client
from .utils import normalize_ke_phone, parse_members_text

logger = logging.getLogger(__name__)

OTP_TTL_MINUTES = 10


# ── Serialization helpers ────────────────────────────────────────────────────

def member_dict(m):
    return {
        'id': m.id,
        'name': m.name,
        'phone': m.phone,
        'status': m.status,
        'paid_at': m.paid_at.isoformat() if m.paid_at else None,
        'paid_method': m.paid_method,
        'paid_amount': str(m.paid_amount) if m.paid_amount is not None else None,
        'amount_mismatch': m.amount_mismatch,
        'transaction_ref': m.transaction_ref,
        'reminders_sent': m.reminders_sent,
        'pay_link': sms.member_pay_link(m),
    }


def collection_dict(c, with_members=False):
    data = {
        'id': c.id,
        'title': c.title,
        'amount': str(c.amount),
        'due_date': c.due_date.isoformat() if c.due_date else None,
        'payout_method': c.payout_method,
        'payout_details': payout_details(c),
        'auto_detect': c.auto_detect,
        'created_at': c.created_at.isoformat(),
        **c.stats(),
    }
    if with_members:
        data['members'] = [member_dict(m) for m in c.members.all()]
    return data


def payout_details(c):
    if c.payout_method == c.TILL:
        return {'till_number': c.till_number}
    if c.payout_method == c.PAYBILL:
        return {'paybill_number': c.paybill_number,
                'paybill_account': c.paybill_account}
    if c.payout_method == c.PERSONAL:
        return {'personal_phone': c.personal_phone}
    return {'bank_details': c.bank_details}


def get_owned_collection(request, pk):
    return Collection.objects.filter(pk=pk, secretary=request.user).first()


# ── Auth ─────────────────────────────────────────────────────────────────────

def start_otp(phone):
    """Create a fresh OTP for [phone] and try to SMS it.

    Shared by the login and create-account flows so both behave identically.
    """
    code = f'{random.randint(0, 999999):06d}'
    LoginOTP.objects.create(
        phone=phone, code=code,
        expires_at=timezone.now() + timedelta(minutes=OTP_TTL_MINUTES))
    ok, _, error = sms.send_sms(phone, sms.build_otp_sms(code))
    payload = {'sent': ok}
    if not ok:
        logger.warning('OTP SMS to %s failed: %s', phone, error)
    if settings.DEBUG or settings.AFRICASTALKING_SANDBOX:
        # Sandbox numbers never receive real SMS - expose the code so the
        # flow stays testable. Never included in production.
        payload['dev_code'] = code
    return payload


def secretary_dict(s):
    return {'phone': s.phone, 'name': s.name, 'group_name': s.group_name}


class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = normalize_ke_phone(request.data.get('phone', ''))
        if not phone:
            return Response({'error': 'Enter a valid Kenyan phone number'},
                            status=status.HTTP_400_BAD_REQUEST)
        return Response(start_otp(phone))


class RegisterView(APIView):
    """Create Account: name + phone + group name, then send the login OTP."""

    permission_classes = [AllowAny]

    def post(self, request):
        name = (request.data.get('name') or '').strip()
        phone = normalize_ke_phone(request.data.get('phone', ''))
        group_name = (request.data.get('group_name') or '').strip()
        if not name:
            return Response({'error': 'Enter your full name'},
                            status=status.HTTP_400_BAD_REQUEST)
        if not phone:
            return Response({'error': 'Enter a valid Kenyan phone number'},
                            status=status.HTTP_400_BAD_REQUEST)
        secretary, _ = Secretary.objects.get_or_create(phone=phone)
        secretary.name = name
        fields = ['name']
        if group_name:
            secretary.group_name = group_name
            fields.append('group_name')
        secretary.save(update_fields=fields)
        return Response(start_otp(phone))


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        phone = normalize_ke_phone(request.data.get('phone', ''))
        code = str(request.data.get('code', '')).strip()
        if not phone or not code:
            return Response({'error': 'Phone and code are required'},
                            status=status.HTTP_400_BAD_REQUEST)
        otp = (LoginOTP.objects.filter(phone=phone, used=False)
               .order_by('-created_at').first())
        if not otp or not otp.is_valid or otp.code != code:
            return Response({'error': 'Wrong or expired code'},
                            status=status.HTTP_400_BAD_REQUEST)
        otp.used = True
        otp.save(update_fields=['used'])
        secretary, _ = Secretary.objects.get_or_create(phone=phone)
        secretary.auth_token = new_token()
        secretary.save(update_fields=['auth_token'])
        return Response({
            'token': secretary.auth_token,
            'phone': phone,
            'name': secretary.name,
            'group_name': secretary.group_name,
        })


class MeView(APIView):
    def get(self, request):
        return Response(secretary_dict(request.user))


# ── Collections ──────────────────────────────────────────────────────────────

class CollectionsView(APIView):
    def get(self, request):
        collections = Collection.objects.filter(secretary=request.user)
        return Response([collection_dict(c) for c in collections])

    def post(self, request):
        data = request.data
        title = (data.get('title') or '').strip()
        if not title:
            return Response({'error': 'Title is required'},
                            status=status.HTTP_400_BAD_REQUEST)
        try:
            amount = Decimal(str(data.get('amount', '')))
            if amount <= 0:
                raise InvalidOperation
        except (InvalidOperation, TypeError):
            return Response({'error': 'Enter a valid amount'},
                            status=status.HTTP_400_BAD_REQUEST)

        payout_method = data.get('payout_method')
        if payout_method not in dict(Collection.PAYOUT_METHODS):
            return Response({'error': 'Choose how people will send money'},
                            status=status.HTTP_400_BAD_REQUEST)

        members = parse_members_text(data.get('members_text', ''))
        if not members:
            return Response({'error': 'Add at least one valid phone number'},
                            status=status.HTTP_400_BAD_REQUEST)

        due_date = None
        raw_due_date = (data.get('due_date') or '').strip()
        if raw_due_date:
            try:
                due_date = date.fromisoformat(raw_due_date)
            except ValueError:
                return Response({'error': 'Due date must be YYYY-MM-DD'},
                                status=status.HTTP_400_BAD_REQUEST)

        collection = Collection.objects.create(
            secretary=request.user,
            title=title,
            amount=amount,
            due_date=due_date,
            payout_method=payout_method,
            till_number=(data.get('till_number') or '').strip(),
            paybill_number=(data.get('paybill_number') or '').strip(),
            paybill_account=(data.get('paybill_account') or '').strip(),
            personal_phone=normalize_ke_phone(data.get('personal_phone', ''))
                             or (data.get('personal_phone') or '').strip(),
            bank_details=(data.get('bank_details') or '').strip(),
        )
        for m in members:
            Member.objects.create(collection=collection, **m)

        sent, failed = 0, []
        for member in collection.members.all():
            ok, _, error = sms.send_sms(
                member.phone, sms.build_invite_sms(collection, member))
            if ok:
                sent += 1
            else:
                failed.append({'phone': member.phone, 'error': error})

        return Response(
            {**collection_dict(collection, with_members=True),
             'notify': {'sent': sent, 'failed': failed}},
            status=status.HTTP_201_CREATED)


class CollectionDetailView(APIView):
    def get(self, request, pk):
        collection = get_owned_collection(request, pk)
        if not collection:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        return Response(collection_dict(collection, with_members=True))


class RemindUnpaidView(APIView):
    def post(self, request, pk):
        collection = get_owned_collection(request, pk)
        if not collection:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        sent = 0
        for member in collection.members.filter(status=Member.UNPAID):
            ok, _, _ = sms.send_sms(
                member.phone, sms.build_reminder_sms(collection, member))
            if ok:
                sent += 1
            member.reminders_sent += 1
            member.save(update_fields=['reminders_sent'])
        return Response({'sent': sent})


class CollectionExportView(APIView):
    def get(self, request, pk):
        collection = get_owned_collection(request, pk)
        if not collection:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        response = HttpResponse(content_type='text/csv')
        filename = f'tapverify-{collection.title.replace(" ", "-")}.csv'
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        writer = csv.writer(response)
        writer.writerow(['Name', 'Phone', 'Status', 'Paid At', 'Method',
                         'Amount', 'Transaction Ref'])
        for m in collection.members.all():
            writer.writerow([
                m.name, m.phone, m.status.upper(),
                m.paid_at.strftime('%Y-%m-%d %H:%M') if m.paid_at else '',
                m.paid_method, m.paid_amount or '', m.transaction_ref,
            ])
        return response


# ── Members ──────────────────────────────────────────────────────────────────

class MarkPaidView(APIView):
    def post(self, request, pk):
        member = Member.objects.filter(
            pk=pk, collection__secretary=request.user).first()
        if not member:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        method = request.data.get('method')
        if method not in ('cash', 'other'):
            return Response({'error': 'Method must be cash or other'},
                            status=status.HTTP_400_BAD_REQUEST)
        member.mark_paid(method=method, amount=member.collection.amount)
        return Response(member_dict(member))


class RemindMemberView(APIView):
    def post(self, request, pk):
        member = Member.objects.filter(
            pk=pk, collection__secretary=request.user).first()
        if not member:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        ok, _, error = sms.send_sms(
            member.phone, sms.build_reminder_sms(member.collection, member))
        if ok:
            member.reminders_sent += 1
            member.save(update_fields=['reminders_sent'])
        return Response({'sent': ok, 'error': None if ok else error})


# ── Member payment experience (public) ───────────────────────────────────────

def pay_page(request, pay_code):
    """The page a member opens from the SMS link. No login, no app."""
    member = Member.objects.filter(pay_code=pay_code).select_related('collection').first()
    if not member:
        return render(request, 'core/pay_page.html',
                      {'not_found': True}, status=404)
    return render(request, 'core/pay_page.html', {
        'not_found': False,
        'pay_code': pay_code,
        'title': member.collection.title,
        'amount': f'{member.collection.amount:,.0f}',
        'member_name': member.name,
        'member_phone': member.phone,
        'already_paid': member.status == Member.PAID,
        'payout_method': member.collection.payout_method,
        'payout_details': payout_details(member.collection),
    })


class PayInfoView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pay_code):
        member = Member.objects.filter(pay_code=pay_code).first()
        if not member:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        c = member.collection
        return Response({
            'title': c.title,
            'amount': str(c.amount),
            'member_name': member.name,
            'status': member.status,
            'payout_method': c.payout_method,
            'payout_details': payout_details(c),
        })


def start_member_stk(member, phone=None):
    """Start a Daraja STK Push for this member and record a pending Payment.

    Returns (ok, result_dict, error_string).
    """
    client = get_mpesa_client()
    if not client.configured:
        return False, {}, 'M-Pesa credentials are not configured yet'
    phone = normalize_ke_phone(phone or '') or member.phone
    result = client.stk_push(
        phone=phone,
        amount=member.collection.amount,
        account_reference=member.pay_code,
        description='TapVerify',
    )
    if not result.get('success'):
        logger.warning('STK push failed for %s: %s', phone, result.get('error'))
        return False, result, result.get('error') or 'Could not start payment'
    Payment.objects.create(
        member=member,
        collection=member.collection,
        phone=phone,
        amount=member.collection.amount,
        reference=result.get('checkout_request_id', ''),
        status=Payment.UNMATCHED,
        raw={'state': 'stk_pending',
             'checkout_request_id': result.get('checkout_request_id', '')},
    )
    logger.info('STK push sent to %s for "%s" (%s)',
                phone, member.collection.title, member.pay_code)
    return True, result, None


class PayStartView(APIView):
    """Start an M-Pesa payment for this member (STK Push or SasaPay)."""
    permission_classes = [AllowAny]

    def post(self, request, pay_code):
        member = Member.objects.filter(pay_code=pay_code).select_related('collection').first()
        if not member:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        if member.status == Member.PAID:
            return Response({'paid': True})

        if settings.PAYMENT_RAIL == 'mpesa':
            ok, result, error = start_member_stk(
                member, request.data.get('phone'))
            if not ok:
                return Response({'error': error},
                                status=status.HTTP_502_BAD_GATEWAY)
            return Response({
                'paid': False,
                'stk': True,
                'message': result.get('customer_message'),
                'checkout_request_id': result.get('checkout_request_id'),
            })

        phone = normalize_ke_phone(request.data.get('phone', '')) or member.phone
        client = get_sasapay_client()
        result = client.create_checkout(
            phone=phone,
            amount=member.collection.amount,
            reference=member.pay_code,
            description=f'{member.collection.title} | TapVerify',
        )
        if not result.get('success'):
            return Response(
                {'error': result.get('error') or result.get('message')
                 or 'Could not start payment'},
                status=status.HTTP_502_BAD_GATEWAY)
        if settings.SASAPAY_MOCK_MODE:
            # Sandbox demo: no real money moves, so confirm instantly.
            member.mark_paid(method='auto', amount=member.collection.amount,
                             transaction_ref=result.get('checkout_request_id', ''))
            return Response({'paid': True, 'mock': True})
        return Response({
            'paid': False,
            'checkout_url': result.get('checkout_url'),
            'checkout_request_id': result.get('checkout_request_id'),
        })


class MemberStkPushView(APIView):
    """The treasurer asks Daraja to prompt this member's phone (STK Push)."""

    def post(self, request, pk):
        member = Member.objects.filter(
            pk=pk, collection__secretary=request.user).first()
        if not member:
            return Response({'error': 'Not found'},
                            status=status.HTTP_404_NOT_FOUND)
        if member.status == Member.PAID:
            return Response({'paid': True})
        phone = request.data.get('phone') if isinstance(request.data, dict) else None
        ok, result, error = start_member_stk(member, phone)
        if not ok:
            return Response({'error': error},
                            status=status.HTTP_502_BAD_GATEWAY)
        return Response({
            'sent': True,
            'message': result.get('customer_message'),
            'checkout_request_id': result.get('checkout_request_id'),
        })


# ── SasaPay webhook: automatic payment detection ────────────────────────────

class SasaPayWebhookView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        client = get_sasapay_client()
        result = client.verify_webhook(request.data, request.headers)
        if result['status'] != 'success':
            logger.info('SasaPay webhook ignored: %s', result.get('result_description'))
            return Response({'ok': True, 'ignored': True})

        member = self._match_member(result)
        amount = self._parse_amount(result.get('amount'))
        payment = Payment.objects.create(
            member=member,
            collection=member.collection if member else None,
            phone=result.get('phone') or '',
            amount=amount,
            reference=result.get('reference') or '',
            transaction_code=result.get('receipt_number') or '',
            status=Payment.MATCHED if member else Payment.UNMATCHED,
            raw=request.data,
        )
        if member and member.status != Member.PAID:
            member.mark_paid(
                method='auto',
                amount=amount or member.collection.amount,
                transaction_ref=payment.transaction_code,
            )
            sms.send_sms(member.phone,
                         sms.build_payment_confirmation_sms(member.collection, member))
            logger.info('Auto-marked paid: %s in "%s"',
                        member.phone, member.collection.title)
        return Response({'ok': True, 'matched': bool(member)})

    def _match_member(self, result):
        reference = (result.get('reference') or '').strip()
        if reference:
            member = Member.objects.filter(pay_code=reference).first()
            if member:
                return member
        phone = normalize_ke_phone(result.get('phone') or '')
        if phone:
            # Direct Till/Paybill payment: match the unpaid member by phone
            # in the most recent auto-detect collection.
            return (Member.objects.filter(
                        phone=phone, status=Member.UNPAID,
                        collection__payout_method__in=Collection.AUTO_DETECT_METHODS)
                    .order_by('-collection__created_at').first())
        return None

    @staticmethod
    def _parse_amount(raw):
        try:
            return Decimal(str(raw)) if raw is not None else None
        except (InvalidOperation, TypeError):
            return None


# ── Daraja M-Pesa webhook: STK Push results ──────────────────────────────────

class MpesaWebhookView(APIView):
    """Where the Vercel relay (tapverify.vercel.app/api/mpesa/callback)
    forwards Daraja STK Push results. No login: Safaricom calls this."""

    permission_classes = [AllowAny]

    def post(self, request):
        parsed = parse_callback(request.data)
        if not parsed['checkout_request_id']:
            logger.warning('M-Pesa callback without CheckoutRequestID: %s',
                           request.data)
            return Response({'ResultCode': 0, 'ResultDesc': 'Accepted'})

        pending = (Payment.objects
                   .filter(reference=parsed['checkout_request_id'])
                   .order_by('-created_at').first())
        member = pending.member if pending else None
        if member is None and parsed.get('account_reference'):
            member = Member.objects.filter(
                pay_code=parsed['account_reference']).first()

        if parsed['success']:
            amount = self._amount(parsed.get('amount'))
            if member is not None:
                paid_amount = amount or member.collection.amount
                if pending:
                    pending.transaction_code = parsed['receipt']
                    pending.status = Payment.MATCHED
                    pending.raw = {**(pending.raw or {}),
                                   'callback': request.data}
                    pending.save(update_fields=['transaction_code', 'status', 'raw'])
                else:
                    Payment.objects.create(
                        member=member,
                        collection=member.collection,
                        phone=parsed.get('phone') or member.phone,
                        amount=paid_amount,
                        reference=parsed['checkout_request_id'],
                        transaction_code=parsed['receipt'],
                        status=Payment.MATCHED,
                        raw={'callback': request.data},
                    )
                if member.status != Member.PAID:
                    member.mark_paid(method='auto', amount=paid_amount,
                                     transaction_ref=parsed['receipt'])
                    sms.send_sms(
                        member.phone,
                        sms.build_payment_confirmation_sms(
                            member.collection, member))
                    logger.info('STK payment confirmed: %s -> "%s" (%s)',
                                member.phone, member.collection.title,
                                parsed['receipt'])
            else:
                Payment.objects.create(
                    phone=str(parsed.get('phone') or ''),
                    amount=self._amount(parsed.get('amount')),
                    reference=parsed['checkout_request_id'],
                    transaction_code=parsed['receipt'],
                    status=Payment.UNMATCHED,
                    raw={'callback': request.data},
                )
                logger.warning('STK payment with no member match: %s',
                               parsed['checkout_request_id'])
        else:
            if pending:
                pending.raw = {**(pending.raw or {}),
                               'callback': request.data,
                               'state': 'stk_failed'}
                pending.save(update_fields=['raw'])
            logger.info('STK push failed (%s): %s',
                        parsed['result_code'], parsed['result_desc'])

        # Daraja expects this exact shape to stop retrying.
        return Response({'ResultCode': 0, 'ResultDesc': 'Accepted'})

    @staticmethod
    def _amount(raw):
        try:
            return Decimal(str(raw)) if raw is not None else None
        except (InvalidOperation, TypeError):
            return None
