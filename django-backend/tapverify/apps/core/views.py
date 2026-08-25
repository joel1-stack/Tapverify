from django.conf import settings
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib import messages
from django.http import JsonResponse
from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from django.shortcuts import get_object_or_404, render, redirect
from django.db.models import Sum, Count, Q
from django.utils import timezone
from datetime import timedelta
import logging
import hashlib
import json

from .models import Workspace, Staff, Member, VerificationEvent, MpesaTransaction, PaymentReminder, PaymentLink, Collection, PaymentTask
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

        # SasaPay: fire the checkout link to the member's phone
        payment_result = None
        if data.get('event_type') == 'payment_sasapay' and data.get('payment_link_token'):
            rail = get_payment_rail()
            payment_result = rail.initiate_payment(
                phone=member.phone,
                amount=data['amount'],
                reference=data['payment_link_token'],
                description=f'{workspace.name} - {member.name}',
            )
            event.notes = f"{event.notes} SasaPay: {payment_result.get('message') or 'initiated'}".strip()

        if data.get('event_type') in ('payment_cash', 'payment_mpesa', 'payment_sasapay'):
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
# PAYMENT LINKS — Member pays on their own phone
# ───────────────────────────────────────────────

class PaymentLinkCreateView(generics.GenericAPIView):
    """
    POST /api/v1/payment-link/create/
    Creates a payment link so the MEMBER can pay on their own phone via SasaPay.
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
    Initiates SasaPay checkout for the member.
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
        'available_rails': ['sasapay'],
    })


# ───────────────────────────────────────────────
# WEB DASHBOARD VIEWS
# ───────────────────────────────────────────────

def web_login_view(request):
    if request.user.is_authenticated:
        return redirect('web-dashboard')

    if request.method == 'POST':
        phone = request.POST.get('phone', '').strip()
        pin = request.POST.get('pin', '').strip()

        if not phone or not pin:
            return render(request, 'core/login.html', {'error': 'Phone and PIN are required.'})

        try:
            staff = Staff.objects.select_related('workspace', 'user').get(
                phone=phone, pin_code=pin, is_active=True
            )
        except Staff.DoesNotExist:
            return render(request, 'core/login.html', {'error': 'Invalid phone or PIN.'})

        if staff.user:
            user = staff.user
        else:
            user, _ = User.objects.get_or_create(
                username=phone,
                defaults={'first_name': staff.name}
            )
            staff.user = user
            staff.save(update_fields=['user'])

        login(request, user)
        return redirect('web-dashboard')

    return render(request, 'core/login.html', {'error': None})


@login_required
def web_logout_view(request):
    logout(request)
    return redirect('web-login')


@login_required
def dashboard_view(request):
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace
    collections = Collection.objects.filter(workspace=workspace, closed=False)
    members = Member.objects.filter(workspace=workspace, is_active=True)
    recent_events = VerificationEvent.objects.filter(
        workspace=workspace
    ).select_related('member', 'verifier').order_by('-created_at')[:10]

    total_members = members.count()
    active_members = members.filter(is_active=True).count()
    total_outstanding = members.aggregate(total=Sum('balance_due'))['total'] or 0

    total_collected = VerificationEvent.objects.filter(
        workspace=workspace,
        event_type__startswith='payment',
        status='approved'
    ).aggregate(total=Sum('amount'))['total'] or 0

    today = timezone.now().date()
    collected_today = VerificationEvent.objects.filter(
        workspace=workspace,
        event_type__startswith='payment',
        status='approved',
        created_at__date=today
    ).aggregate(total=Sum('amount'))['total'] or 0

    total_target = total_members * workspace.monthly_amount if total_members > 0 else 0
    collection_rate = round((total_collected / total_target * 100) if total_target > 0 else 0, 1)

    collections_data = []
    for col in collections:
        total = col.tasks.count()
        paid = col.paid_count
        progress = round((paid / total * 100) if total > 0 else 0)
        collections_data.append({
            'id': col.id,
            'title': col.title,
            'type': col.type,
            'get_type_display': col.get_type_display(),
            'amount': col.amount,
            'due': col.due,
            'paid_count': paid,
            'total_members': total,
            'progress': progress,
        })

    hour = timezone.now().hour
    if hour < 12:
        greeting = 'Good morning'
    elif hour < 17:
        greeting = 'Good afternoon'
    else:
        greeting = 'Good evening'

    recent_events_data = []
    for ev in recent_events:
        recent_events_data.append({
            'member_name': ev.member.name,
            'event_type': ev.event_type,
            'get_event_type_display': ev.get_event_type_display(),
            'amount': ev.amount,
            'created_at': ev.created_at,
        })

    context = {
        'greeting': greeting,
        'active_collections': collections.count(),
        'open_collections': collections.count(),
        'total_collected': total_collected,
        'collected_today': collected_today,
        'total_pending': total_outstanding,
        'pending_count': members.filter(balance_due__gt=0).count(),
        'collection_rate': collection_rate,
        'collections': collections_data,
        'recent_events': recent_events_data,
        'total_members': total_members,
        'active_members': active_members,
        'total_outstanding': total_outstanding,
    }
    return render(request, 'core/dashboard.html', context)


@login_required
def create_collection_view(request):
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace
    members = Member.objects.filter(workspace=workspace, is_active=True).order_by('name')

    if request.method == 'POST':
        title = request.POST.get('title', '').strip()
        collection_type = request.POST.get('type', 'welfare')
        amount = request.POST.get('amount', '0')
        due = request.POST.get('due', '')
        rail = request.POST.get('rail', 'sasapay')
        message_template = request.POST.get('message', '')
        member_ids = request.POST.getlist('members')

        if not all([title, amount, due, member_ids]):
            messages.error(request, 'Please fill all required fields and select at least one member.')
            return render(request, 'core/create_collection.html', {'members': members})

        from django.utils.dateparse import parse_datetime
        due_dt = parse_datetime(due)
        if due_dt is None:
            from datetime import datetime
            due_dt = datetime.strptime(due, '%Y-%m-%d')
            due_dt = timezone.make_aware(due_dt)

        collection = Collection.objects.create(
            workspace=workspace,
            title=title,
            type=collection_type,
            amount=amount,
            due=due_dt,
            rail=rail,
            message=message_template,
        )

        selected_members = Member.objects.filter(id__in=member_ids, workspace=workspace, is_active=True)
        for member in selected_members:
            msg = message_template.replace('{name}', member.name).replace(
                '{amount}', str(amount)).replace(
                '{type}', collection.get_type_display()).replace(
                '{due_date}', due_dt.strftime('%d %b %Y'))

            task = PaymentTask.objects.create(
                collection=collection,
                member=member,
                amount=amount,
                state='created',
            )

            payment_link = PaymentLink.objects.create(
                workspace=workspace,
                member=member,
                amount=amount,
                description=f'{title} — {workspace.name}',
            )

        messages.success(request, f'Collection "{title}" created with {len(member_ids)} members.')
        return redirect('web-collection-detail', collection_id=collection.id)

    return render(request, 'core/create_collection.html', {'members': members})


@login_required
def collection_detail_view(request, collection_id):
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace
    collection = get_object_or_404(Collection, id=collection_id, workspace=workspace)
    tasks = PaymentTask.objects.filter(
        collection=collection
    ).select_related('member').order_by('member__name')

    total_members = tasks.count()
    paid_count = collection.paid_count
    pending_count = tasks.filter(state__in=['created', 'notified', 'pending']).count()
    overdue_count = 0
    for task in tasks:
        if task.state in ('created', 'notified', 'pending') and collection.due < timezone.now():
            overdue_count += 1

    progress = round((paid_count / total_members * 100) if total_members > 0 else 0)

    base_url = settings.RECEIPT_BASE_URL
    tasks_data = []
    all_links = []
    for task in tasks:
        payment_link = PaymentLink.objects.filter(
            workspace=workspace, member=task.member, status='pending'
        ).order_by('-created_at').first()

        if task.state in ('completed', 'verified', 'streak', 'badge', 'reward'):
            status_class = 'paid'
        elif task.state in ('created', 'notified', 'pending') and collection.due < timezone.now():
            status_class = 'overdue'
        else:
            status_class = 'pending'

        link_url = f"{base_url}/p/{payment_link.token}" if payment_link else None
        if link_url:
            all_links.append({'name': task.member.name, 'url': link_url})

        tasks_data.append({
            'id': task.id,
            'member': task.member,
            'state': task.state,
            'amount': task.amount,
            'paid_at': task.paid_at,
            'status_class': status_class,
            'payment_link': payment_link,
            'payment_link_url': link_url,
        })

    context = {
        'collection': collection,
        'tasks': tasks_data,
        'total_members': total_members,
        'paid_count': paid_count,
        'pending_count': pending_count,
        'overdue_count': overdue_count,
        'progress': progress,
        'all_links_json': json.dumps(all_links),
    }
    return render(request, 'core/collection_detail.html', context)


@login_required
def members_view(request):
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace

    if request.method == 'POST':
        action = request.POST.get('action')
        if action == 'add_member':
            name = request.POST.get('name', '').strip()
            phone = request.POST.get('phone', '').strip()
            contribution = request.POST.get('monthly_contribution', '500')

            if name and phone:
                if Member.objects.filter(workspace=workspace, phone=phone).exists():
                    messages.error(request, f'A member with phone {phone} already exists.')
                else:
                    Member.objects.create(
                        workspace=workspace,
                        name=name,
                        phone=phone,
                        monthly_contribution=contribution,
                    )
                    messages.success(request, f'{name} has been added.')
            else:
                messages.error(request, 'Name and phone are required.')

        return redirect('web-members')

    members = Member.objects.filter(
        workspace=workspace, is_active=True
    ).order_by('name')

    return render(request, 'core/members.html', {'members': members})


@login_required
def settings_view(request):
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace

    if request.method == 'POST':
        action = request.POST.get('action')
        if action == 'update_settings':
            workspace.name = request.POST.get('name', workspace.name).strip()
            workspace.type = request.POST.get('type', workspace.type)
            workspace.phone = request.POST.get('phone', workspace.phone).strip()
            workspace.till_number = request.POST.get('till_number', '') or None
            workspace.paybill_number = request.POST.get('paybill_number', '') or None
            workspace.account_number = request.POST.get('account_number', '') or None

            monthly = request.POST.get('monthly_amount')
            if monthly:
                try:
                    workspace.monthly_amount = float(monthly)
                except (ValueError, TypeError):
                    pass

            workspace.save()
            messages.success(request, 'Settings saved successfully.')

        return redirect('web-settings')

    return render(request, 'core/settings.html', {'workspace': workspace})


@login_required
def generate_links_view(request, collection_id):
    """Generate SasaPay checkout links for all pending members in a collection."""
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace
    collection = get_object_or_404(Collection, id=collection_id, workspace=workspace)

    from .services.sasapay import get_sasapay_client
    client = get_sasapay_client()

    tasks = PaymentTask.objects.filter(
        collection=collection,
        state__in=['created', 'notified'],
    ).select_related('member')

    generated = 0
    for task in tasks:
        if task.checkout_url:
            continue

        try:
            result = client.create_checkout(
                phone=task.member.phone,
                amount=task.amount,
                reference=task.payment_token,
                description=f"{collection.title} — {task.member.name}",
            )

            if result.get('success') and result.get('checkout_url'):
                task.checkout_url = result['checkout_url']
                task.provider_checkout_id = result.get('checkout_request_id', '')
                task.state = 'notified'
                task.save()
                generated += 1

                # Send checkout link via SMS
                try:
                    from .services.africastalking import AfricasTalkingService
                    at = AfricasTalkingService()
                    at.send_checkout_link(
                        task.member.phone,
                        task.member.name,
                        task.amount,
                        task.checkout_url,
                    )
                    task.sms_status = 'sent'
                    task.save(update_fields=['sms_status'])
                except Exception as e:
                    logger.error("SMS failed for task %s: %s", task.id, e)

        except Exception as e:
            logger.error("Checkout generation failed for task %s: %s", task.id, e)

    if generated > 0:
        messages.success(request, f'Generated {generated} payment links.')
    else:
        messages.info(request, 'All links already generated or no pending tasks.')

    return redirect('web-collection-detail', collection_id=collection.id)


@login_required
def remind_pending_view(request, collection_id):
    """Send SMS reminders to all pending members."""
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace
    collection = get_object_or_404(Collection, id=collection_id, workspace=workspace)

    from .services.africastalking import AfricasTalkingService
    at = AfricasTalkingService()

    pending = PaymentTask.objects.filter(
        collection=collection,
        state__in=['created', 'notified', 'pending'],
    ).select_related('member')

    sent = 0
    for task in pending:
        msg = (
            f"REMINDER: {collection.title} Ksh {int(task.amount)} "
            f"due {collection.due.strftime('%d %b')}. "
        )
        if task.checkout_url:
            msg += f"Pay: {task.checkout_url}"
        else:
            msg += "Contact your treasurer."

        ok, _, _ = at.send_sms(task.member.phone, msg)
        if ok:
            sent += 1

    messages.success(request, f'Sent {sent} reminders.')
    return redirect('web-collection-detail', collection_id=collection.id)


@login_required
def reconcile_view(request, collection_id):
    """Pull SasaPay transactions and match to unpaid tasks."""
    try:
        staff = request.user.staff
    except Staff.DoesNotExist:
        return redirect('web-login')

    workspace = staff.workspace
    collection = get_object_or_404(Collection, id=collection_id, workspace=workspace)

    from .services.sasapay import get_sasapay_client, SUCCESS_CODES
    client = get_sasapay_client()

    all_txs = client.reconcile_all(merchant_code=workspace.account_number)

    matched = 0
    for tx in all_txs:
        tx_ref = tx.get('transaction_reference', '')
        tx_code = tx.get('transaction_code', '')
        result_code = tx.get('result_code', '')

        if result_code not in SUCCESS_CODES:
            continue

        # Try match by payment_token
        try:
            task = PaymentTask.objects.get(
                payment_token=tx_ref,
                collection=collection,
                state__in=['created', 'notified', 'pending'],
            )
            task.state = 'completed'
            task.provider_tx_code = tx_code
            task.paid_at = timezone.now()
            task.save()
            matched += 1
        except PaymentTask.DoesNotExist:
            pass

        # Try match by provider_tx_code
        try:
            task = PaymentTask.objects.get(
                provider_tx_code=tx_code,
                collection=collection,
            )
            if task.state != 'completed':
                task.state = 'completed'
                task.paid_at = timezone.now()
                task.save()
                matched += 1
        except PaymentTask.DoesNotExist:
            pass

    if matched > 0:
        messages.success(request, f'Reconciliation: {matched} payments matched.')
    else:
        messages.info(request, 'No new transactions to reconcile.')

    return redirect('web-collection-detail', collection_id=collection.id)
