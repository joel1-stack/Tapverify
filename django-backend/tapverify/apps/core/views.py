from django.conf import settings
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404, render
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
import logging
import hashlib

from .models import Workspace, Staff, Member, VerificationEvent, MpesaTransaction, PaymentReminder, PaymentLink
from .serializers import (
    WorkspaceSerializer, StaffSerializer, MemberSerializer, MemberListSerializer,
    VerificationEventSerializer, VerifyRequestSerializer, ReceiptSerializer,
    MpesaTransactionSerializer, PaymentReminderSerializer, PaymentLinkSerializer
)
from .services import AfricasTalkingSMSService, build_receipt_sms, build_reminder_sms, get_payment_rail

logger = logging.getLogger(__name__)


# ───────────────────────────────────────────────
# AUTH & STAFF
# ───────────────────────────────────────────────

class StaffLoginView(generics.GenericAPIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        phone = request.data.get('phone', '').strip()
        pin = request.data.get('pin', '').strip()

        if not phone or not pin:
            return Response({'error': 'Phone and PIN required'}, status=400)

        try:
            staff = Staff.objects.select_related('workspace').get(phone=phone, pin_code=pin, is_active=True)
        except Staff.DoesNotExist:
            return Response({'error': 'Invalid credentials'}, status=401)

        token = hashlib.sha256(f"{staff.id}{phone}{pin}".encode()).hexdigest()[:32]

        return Response({
            'success': True,
            'token': token,
            'staff': {
                'id': str(staff.id),
                'name': staff.name,
                'phone': staff.phone,
                'role': staff.role,
                'workspace': {
                    'id': str(staff.workspace.id),
                    'name': staff.workspace.name,
                    'type': staff.workspace.type,
                    'monthly_amount': str(staff.workspace.monthly_amount),
                }
            }
        })


# ───────────────────────────────────────────────
# MEMBERS
# ───────────────────────────────────────────────

class MemberListView(generics.ListAPIView):
    serializer_class = MemberListSerializer

    def get_queryset(self):
        workspace_id = self.request.query_params.get('workspace_id')
        q = self.request.query_params.get('q', '')

        qs = Member.objects.filter(is_active=True)
        if workspace_id:
            qs = qs.filter(workspace_id=workspace_id)
        if q:
            qs = qs.filter(Q(name__icontains=q) | Q(phone__icontains=q) | Q(member_code__iexact=q))
        return qs.order_by('name')


class MemberDetailView(generics.RetrieveAPIView):
    queryset = Member.objects.all()
    serializer_class = MemberSerializer
    lookup_field = 'id'


class MemberHistoryView(generics.ListAPIView):
    serializer_class = VerificationEventSerializer

    def get_queryset(self):
        member_id = self.kwargs.get('member_id')
        return VerificationEvent.objects.filter(member_id=member_id).order_by('-created_at')


# ───────────────────────────────────────────────
# VERIFICATION (THE CORE) — uses Payment Rail
# ───────────────────────────────────────────────

class VerifyMemberView(generics.GenericAPIView):
    serializer_class = VerifyRequestSerializer

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            return Response({'success': False, 'errors': serializer.errors}, status=400)

        data = serializer.validated_data

        try:
            workspace = Workspace.objects.get(id=data['workspace_id'], is_active=True)
        except Workspace.DoesNotExist:
            return Response({'success': False, 'error': 'Workspace not found'}, status=404)

        member = None
        if data.get('member_id'):
            try:
                member = Member.objects.get(id=data['member_id'], workspace=workspace, is_active=True)
            except Member.DoesNotExist:
                return Response({'success': False, 'error': 'Member not found'}, status=404)
        elif data.get('member_code'):
            try:
                member = Member.objects.get(member_code=data['member_code'], workspace=workspace, is_active=True)
            except Member.DoesNotExist:
                return Response({'success': False, 'error': 'Member code not found'}, status=404)
        else:
            return Response({'success': False, 'error': 'member_id or member_code required'}, status=400)

        verifier = None
        staff_phone = request.data.get('verifier_phone')
        if staff_phone:
            try:
                verifier = Staff.objects.get(phone=staff_phone, workspace=workspace, is_active=True)
            except Staff.DoesNotExist:
                pass

        event = VerificationEvent.objects.create(
            workspace=workspace,
            member=member,
            verifier=verifier,
            event_type=data.get('event_type', 'payment_cash'),
            amount=data['amount'],
            verification_method=data.get('verification_method', 'manual'),
            gps_lat=data.get('gps_lat'),
            gps_lng=data.get('gps_lng'),
            notes=data.get('notes', ''),
            status='approved',
            verified_at=timezone.now()
        )

        # Loop Request-to-Pay: fire the M-Pesa prompt to the member's phone
        loop_result = None
        if data.get('event_type') == 'payment_loop' and data.get('payment_link_token'):
            rail = get_payment_rail()
            loop_result = rail.initiate_payment(
                phone=member.phone,
                amount=data['amount'],
                reference=data['payment_link_token'],
                description=f'{workspace.name} - {member.name}',
            )
            event.notes = f"{event.notes} Loop: {loop_result.get('message') or 'initiated'}".strip()

        if data.get('event_type') in ('payment_cash', 'payment_mpesa', 'payment_loop'):
            member.balance_due = max(0, member.balance_due - data['amount'])
            member.last_paid_at = timezone.now()
            member.save()

        sms_service = AfricasTalkingSMSService()
        sms_message = build_receipt_sms(event)
        success, msg_id, error = sms_service.send_sms(member.phone, sms_message)

        if success:
            event.sms_status = 'sent'
            event.sms_message_id = msg_id or ''
        else:
            event.sms_status = 'failed'
            logger.error(f"SMS failed for event {event.id}: {error}")
        event.save()

        return Response({
            'success': True,
            'event_id': str(event.id),
            'status': event.status,
            'receipt': {
                'token': event.receipt_token,
                'pin': event.receipt_pin,
                'url': f"{settings.RECEIPT_BASE_URL}/r/{event.receipt_token}",
            },
            'member': {
                'name': member.name,
                'phone': member.phone,
                'balance_due': str(member.balance_due),
            },
            'sms_status': event.sms_status,
            'timestamp': event.created_at.isoformat(),
        }, status=201)


# ───────────────────────────────────────────────
# RECEIPT PORTAL (Web)
# ───────────────────────────────────────────────

def receipt_view(request, token):
    event = get_object_or_404(VerificationEvent, receipt_token=token)

    if request.method == 'POST':
        pin = request.POST.get('pin', '').strip()
        if pin == event.receipt_pin:
            return render(request, 'core/receipt.html', {
                'event': event,
                'verified': True,
                'maps_url': f"https://www.google.com/maps?q={event.gps_lat},{event.gps_lng}" if event.gps_lat else None
            })
        else:
            return render(request, 'core/receipt_pin.html', {
                'token': token,
                'error': 'Incorrect PIN. Please check your SMS and try again.'
            })

    return render(request, 'core/receipt_pin.html', {'token': token, 'error': None})


# ───────────────────────────────────────────────
# DASHBOARD STATS
# ───────────────────────────────────────────────

class WorkspaceStatsView(generics.GenericAPIView):
    def get(self, request):
        workspace_id = request.query_params.get('workspace_id')
        if not workspace_id:
            return Response({'error': 'workspace_id required'}, status=400)

        today = timezone.now().date()
        week_ago = today - timedelta(days=7)

        events = VerificationEvent.objects.filter(workspace_id=workspace_id)

        stats = {
            'today': {
                'collections': events.filter(created_at__date=today, event_type__startswith='payment').count(),
                'revenue': events.filter(created_at__date=today, event_type__startswith='payment').aggregate(total=Sum('amount'))['total'] or 0,
            },
            'this_week': {
                'collections': events.filter(created_at__date__gte=week_ago, event_type__startswith='payment').count(),
                'revenue': events.filter(created_at__date__gte=week_ago, event_type__startswith='payment').aggregate(total=Sum('amount'))['total'] or 0,
            },
            'total_members': Member.objects.filter(workspace_id=workspace_id, is_active=True).count(),
            'pending_balance': Member.objects.filter(workspace_id=workspace_id, is_active=True).aggregate(total=Sum('balance_due'))['total'] or 0,
            'recent_events': VerificationEventSerializer(
                events.select_related('member', 'verifier').order_by('-created_at')[:10],
                many=True
            ).data
        }
        return Response(stats)


# ───────────────────────────────────────────────
# REMINDERS
# ───────────────────────────────────────────────

class SendRemindersView(generics.GenericAPIView):
    def post(self, request):
        workspace_id = request.data.get('workspace_id')
        reminder_type = request.data.get('reminder_type', 'meeting_day')
        custom_message = request.data.get('message', '')

        if not workspace_id:
            return Response({'error': 'workspace_id required'}, status=400)

        try:
            workspace = Workspace.objects.get(id=workspace_id)
        except Workspace.DoesNotExist:
            return Response({'error': 'Workspace not found'}, status=404)

        members = Member.objects.filter(workspace=workspace, is_active=True, balance_due__gt=0)

        sms_service = AfricasTalkingSMSService()
        sent_count = 0
        failed_count = 0

        for member in members:
            if custom_message:
                msg = custom_message.replace("{name}", member.name).replace("{amount}", str(member.balance_due))
            else:
                msg = build_reminder_sms(member, workspace, reminder_type, member.balance_due)

            success, msg_id, error = sms_service.send_sms(member.phone, msg)

            PaymentReminder.objects.create(
                workspace=workspace,
                member=member,
                reminder_type=reminder_type,
                amount_due=member.balance_due,
                message=msg,
                sms_sent=success,
                sms_sent_at=timezone.now() if success else None
            )

            if success:
                sent_count += 1
            else:
                failed_count += 1

        return Response({
            'success': True,
            'sent': sent_count,
            'failed': failed_count,
            'total': members.count(),
            'cost_estimate': f"Ksh {sent_count * 0.80:.0f}"
        })


# ───────────────────────────────────────────────
# M-PESA WEBHOOK (Legacy / PayHero)
# ───────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def mpesa_callback(request):
    rail = get_payment_rail('payhero')
    parsed = rail.verify_webhook(request.data, request.headers)

    if not parsed.get('valid'):
        return Response({'error': 'Invalid webhook'}, status=400)

    receipt = parsed.get('receipt_number')
    phone = parsed.get('phone')
    amount = parsed.get('amount')
    reference = parsed.get('reference')

    if not receipt or not phone:
        return Response({'error': 'Missing required fields'}, status=400)

    phone = str(phone).replace('+', '').strip()
    if phone.startswith('0'):
        phone = '254' + phone[1:]

    workspace = None
    if reference:
        try:
            workspace = Workspace.objects.get(account_number=reference)
        except Workspace.DoesNotExist:
            pass

    member = None
    if workspace:
        try:
            member = Member.objects.get(workspace=workspace, phone=phone, is_active=True)
        except Member.DoesNotExist:
            pass
    else:
        try:
            member = Member.objects.get(phone=phone, is_active=True)
            workspace = member.workspace
        except (Member.DoesNotExist, Member.MultipleObjectsReturned):
            pass

    txn = MpesaTransaction.objects.create(
        workspace=workspace,
        member=member,
        transaction_type='paybill',
        mpesa_receipt_number=receipt,
        phone_number=phone,
        amount=amount,
        account_reference=reference or '',
        raw_callback=request.data,
        is_matched=bool(member)
    )

    if member and workspace and parsed.get('status') == 'success':
        event = VerificationEvent.objects.create(
            workspace=workspace,
            member=member,
            event_type='payment_mpesa',
            amount=amount,
            verification_method='mpesa_callback',
            status='approved',
            verified_at=timezone.now()
        )
        txn.event = event
        txn.save()

        member.balance_due = max(0, member.balance_due - amount)
        member.last_paid_at = timezone.now()
        member.save()

        sms_service = AfricasTalkingSMSService()
        sms_message = build_receipt_sms(event)
        success, msg_id, error = sms_service.send_sms(member.phone, sms_message)
        if success:
            event.sms_status = 'sent'
            event.sms_message_id = msg_id or ''
            event.save()

    return Response({'success': True, 'matched': bool(member), 'transaction_id': str(txn.id)})


# ───────────────────────────────────────────────
# LOOP IPN WEBHOOK
# ───────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def loop_webhook(request):
    """
    Receive Loop IPN callback.
    Flow: verify signature → find PaymentLink by reference → create VerificationEvent → send SMS → return 200
    """
    rail = get_payment_rail('loop')

    # Pass the raw body through so the signature can be checked
    headers = request.headers.copy()
    try:
        raw = request.body.decode('utf-8')
        if raw:
            headers['raw_body'] = raw
    except Exception:
        pass

    parsed = rail.verify_webhook(request.data, headers)

    if not parsed.get('valid'):
        logger.warning("Invalid Loop IPN received")
        return Response({'error': 'Invalid webhook'}, status=400)

    reference = parsed.get('reference')
    receipt_number = parsed.get('receipt_number')
    phone = parsed.get('phone')
    amount = parsed.get('amount')
    payment_status = parsed.get('status')

    logger.info(f"Loop IPN: ref={reference} status={payment_status} receipt={receipt_number}")

    payment_link = None
    event = None
    member = None
    workspace = None

    if reference:
        try:
            payment_link = PaymentLink.objects.select_related('member', 'workspace').get(token=reference)
        except PaymentLink.DoesNotExist:
            pass

    if payment_link:
        member = payment_link.member
        workspace = payment_link.workspace

        if payment_status == 'success' and payment_link.status == 'pending':
            event = VerificationEvent.objects.create(
                workspace=workspace,
                member=member,
                event_type='payment_mpesa',
                amount=payment_link.amount,
                verification_method='mpesa_callback',
                status='approved',
                verified_at=timezone.now(),
                notes=f'Loop payment via link {payment_link.token}'
            )

            member.balance_due = max(0, member.balance_due - payment_link.amount)
            member.last_paid_at = timezone.now()
            member.save()

            payment_link.status = 'paid'
            payment_link.paid_at = timezone.now()
            payment_link.transaction_ref = receipt_number or ''
            payment_link.event = event
            payment_link.save()

            sms_service = AfricasTalkingSMSService()
            sms_message = build_receipt_sms(event)
            success, msg_id, error = sms_service.send_sms(member.phone, sms_message)
            if success:
                event.sms_status = 'sent'
                event.sms_message_id = msg_id or ''
                event.save()

    elif phone and workspace:
        try:
            member = Member.objects.get(workspace=workspace, phone=phone, is_active=True)
        except Member.DoesNotExist:
            pass

        if member and payment_status == 'success':
            event = VerificationEvent.objects.create(
                workspace=workspace,
                member=member,
                event_type='payment_mpesa',
                amount=amount,
                verification_method='mpesa_callback',
                status='approved',
                verified_at=timezone.now(),
                notes='Loop direct payment'
            )

            member.balance_due = max(0, member.balance_due - amount)
            member.last_paid_at = timezone.now()
            member.save()

            sms_service = AfricasTalkingSMSService()
            sms_message = build_receipt_sms(event)
            success, msg_id, error = sms_service.send_sms(member.phone, sms_message)
            if success:
                event.sms_status = 'sent'
                event.sms_message_id = msg_id or ''
                event.save()

    return Response({
        'success': True,
        'matched': bool(member),
        'event_id': str(event.id) if event else None,
    })


# ───────────────────────────────────────────────
# PAYMENT LINKS — Member pays on their own phone
# ───────────────────────────────────────────────

class PaymentLinkCreateView(generics.GenericAPIView):
    """
    POST /api/v1/payment-link/create/
    Creates a payment link so the MEMBER can pay on their own phone via Loop.
    """
    def post(self, request):
        workspace_id = request.data.get('workspace_id')
        member_id = request.data.get('member_id')
        amount = request.data.get('amount')

        if not all([workspace_id, member_id, amount]):
            return Response({'error': 'workspace_id, member_id, and amount required'}, status=400)

        try:
            workspace = Workspace.objects.get(id=workspace_id, is_active=True)
            member = Member.objects.get(id=member_id, workspace=workspace, is_active=True)
        except (Workspace.DoesNotExist, Member.DoesNotExist):
            return Response({'error': 'Invalid workspace or member'}, status=404)

        payment_link = PaymentLink.objects.create(
            workspace=workspace,
            member=member,
            amount=amount,
            description=f'Payment to {workspace.name}',
        )

        link_url = f"{settings.RECEIPT_BASE_URL}/p/{payment_link.token}"

        rail = get_payment_rail()
        payment_result = rail.initiate_payment(
            phone=member.phone,
            amount=amount,
            reference=payment_link.token,
            description=f'{workspace.name} - {member.name}',
        )

        if payment_result.get('success'):
            payment_link.transaction_ref = payment_result.get('transaction_id', '')
            payment_link.save()
            return Response({
                'success': True,
                'link_url': link_url,
                'token': payment_link.token,
                'amount': str(amount),
                'member': member.name,
                'status': 'payment_initiated',
            })
        else:
            return Response({
                'success': True,
                'link_url': link_url,
                'token': payment_link.token,
                'amount': str(amount),
                'member': member.name,
                'status': 'link_created',
                'message': 'Payment link created. Member can pay when ready.',
            })


def payment_link_view(request, token):
    """
    Member opens payment link on their phone.
    Shows amount + group name + PAY NOW button.
    Auto-refreshes via JS polling to show confirmation.
    """
    pl = get_object_or_404(PaymentLink, token=token)

    if pl.status == 'paid':
        event = pl.event
        return render(request, 'core/payment_success.html', {
            'payment_link': pl,
            'event': event,
        })

    if pl.is_expired:
        pl.status = 'expired'
        pl.save()
        return render(request, 'core/payment_expired.html', {
            'payment_link': pl,
        })

    return render(request, 'core/payment_link.html', {
        'payment_link': pl,
    })


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def payment_link_pay(request, token):
    """
    POST /p/<token>/pay/
    Initiates Loop Request to Pay for the member.
    """
    pl = get_object_or_404(PaymentLink, token=token, status='pending')

    if pl.is_expired:
        return Response({'error': 'Payment link expired'}, status=400)

    rail = get_payment_rail()
    result = rail.initiate_payment(
        phone=pl.member.phone,
        amount=pl.amount,
        reference=pl.token,
        description=f'{pl.workspace.name} - {pl.member.name}',
    )

    if result.get('success'):
        pl.transaction_ref = result.get('transaction_id', '')
        pl.save()
        return Response({
            'success': True,
            'message': 'M-Pesa prompt sent to your phone. Enter your PIN to complete.',
            'transaction_id': result.get('transaction_id'),
        })
    else:
        return Response({
            'success': False,
            'error': 'Could not initiate payment. Please try again.',
        }, status=400)


@api_view(['GET'])
@permission_classes([permissions.AllowAny])
def payment_link_status(request, token):
    """
    GET /p/<token>/status/
    Returns current payment status (for JS polling).
    """
    pl = get_object_or_404(PaymentLink, token=token)
    return Response({
        'status': pl.status,
        'paid_at': pl.paid_at.isoformat() if pl.paid_at else None,
    })


# ───────────────────────────────────────────────
# PAYMENT RAIL INFO
# ───────────────────────────────────────────────

@api_view(['GET'])
def payment_rail_info(request):
    """Returns which payment rail is active."""
    rail = get_payment_rail()
    return Response({
        'active_rail': rail.get_rail_name(),
        'available_rails': ['loop', 'payhero'],
    })


# ───────────────────────────────────────────────
# ADMIN / UTILITY
# ───────────────────────────────────────────────

@api_view(['POST'])
def create_workspace_demo(request):
    name = request.data.get('name', 'Demo Chama')
    phone = request.data.get('phone', '254712345678')

    ws = Workspace.objects.create(name=name, phone=phone, plan='free')
    staff = Staff.objects.create(workspace=ws, name='Demo Treasurer', phone=phone, role='treasurer', pin_code='1234')

    members = []
    for i, (n, p) in enumerate([
        ('Joel Kaunda', '254712345678'),
        ('Mary Wanjiku', '254723456789'),
        ('Peter Ochieng', '254734567890'),
        ('Grace Akinyi', '254745678901'),
        ('John Kamau', '254756789012'),
    ], 1):
        m = Member.objects.create(workspace=ws, name=n, phone=p, balance_due=500)
        members.append({'id': str(m.id), 'name': m.name, 'code': m.member_code})

    return Response({
        'workspace_id': str(ws.id),
        'staff_id': str(staff.id),
        'staff_pin': staff.pin_code,
        'members': members,
        'api_base': '/api/v1/'
    })
