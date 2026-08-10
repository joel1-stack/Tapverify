from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404, render
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
import logging

from .models import Workspace, Staff, Member, VerificationEvent, MpesaTransaction, PaymentReminder
from .serializers import (
    WorkspaceSerializer, StaffSerializer, MemberSerializer, MemberListSerializer,
    VerificationEventSerializer, VerifyRequestSerializer, ReceiptSerializer,
    MpesaTransactionSerializer, PaymentReminderSerializer
)
from .services import AfricasTalkingSMSService, build_receipt_sms, build_reminder_sms

logger = logging.getLogger(__name__)


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

        import hashlib
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

        if data.get('event_type') == 'payment_cash' or data.get('event_type') == 'payment_mpesa':
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


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def mpesa_callback(request):
    data = request.data

    receipt = data.get('mpesaReceiptNumber') or data.get('receipt_number') or data.get('TransID')
    phone = data.get('phoneNumber') or data.get('phone') or data.get('MSISDN')
    amount = data.get('amount') or data.get('TransAmount')
    account_ref = data.get('accountReference') or data.get('BillRefNumber') or data.get('reference')
    result_code = data.get('resultCode') or data.get('ResultCode')

    if not receipt or not phone:
        return Response({'error': 'Missing required fields'}, status=400)

    phone = str(phone).replace('+', '').strip()
    if phone.startswith('0'):
        phone = '254' + phone[1:]

    workspace = None
    if account_ref:
        try:
            workspace = Workspace.objects.get(account_number=account_ref)
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
        account_reference=account_ref or '',
        raw_callback=data,
        is_matched=bool(member)
    )

    if member and workspace and str(result_code) == '0':
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
