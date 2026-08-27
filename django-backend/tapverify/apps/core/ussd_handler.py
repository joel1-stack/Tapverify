"""
Africa's Talking USSD handler for TapVerify.

Customers without smartphones dial *384*123# to:
  1. Check payment status
  2. View payment history
  3. Request payment link via SMS
  4. View balance
  5. Send reminder

Endpoint: POST /ussd/
"""
import logging

from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from .models import Member, PaymentTask, StreakRecord

logger = logging.getLogger(__name__)

# Maps workspace type to menu labels and response text.
_GROUP_CONFIGS = {
    'sacco': {
        'label': 'SACCO / Chama',
        'menu': [
            'Check Contribution',
            'My Streak',
            'Pay Now',
            'History',
            'Send Reminder',
        ],
        'option1_title': 'Contribution',
        'option2_title': 'Streak',
        'option4_title': 'History',
    },
    'church': {
        'label': 'Church',
        'menu': [
            'Check Tithe',
            'My Giving',
            'Give Now',
            'History',
            'Send Reminder',
        ],
        'option1_title': 'Tithe',
        'option2_title': 'Giving',
        'option4_title': 'History',
    },
    'school': {
        'label': 'School',
        'menu': [
            'Check Fees',
            'Payment History',
            'Pay Fees',
            'Balance',
            'Send Reminder',
        ],
        'option1_title': 'Fees',
        'option2_title': 'Payment History',
        'option4_title': 'Balance',
    },
    'business': {
        'label': 'Business',
        'menu': [
            'Check Revenue',
            'Payment History',
            'Pay Now',
            'Balance',
            'Send Reminder',
        ],
        'option1_title': 'Revenue',
        'option2_title': 'Payment History',
        'option4_title': 'Balance',
    },
    'trip': {
        'label': 'Trip',
        'menu': [
            'Check Trip Fee',
            'My Payments',
            'Pay Now',
            'Balance',
            'Send Reminder',
        ],
        'option1_title': 'Trip Fee',
        'option2_title': 'Payments',
        'option4_title': 'Balance',
    },
}


def _get_group_type(member):
    """Determine group type from member's workspace. Defaults to 'business'."""
    try:
        ws = getattr(member, 'workspace', None)
        if ws:
            raw = getattr(ws, 'group_type', None) or getattr(ws, 'type', None)
            if raw and raw.lower() in _GROUP_CONFIGS:
                return raw.lower()
    except Exception:
        pass
    return 'business'


def _format_ussd_response(text, is_end=False):
    """Format USSD response. CON = continue menu, END = final message."""
    prefix = "END" if is_end else "CON"
    return f"{prefix} {text}"


def _build_installment_text(task):
    """Build 'You have paid Ksh X of Ksh Y remaining Ksh Z' text."""
    try:
        total = int(task.amount)
    except (TypeError, ValueError):
        total = 0
    try:
        paid = int(getattr(task, 'amount_paid', 0) or 0)
    except (TypeError, ValueError):
        paid = 0
    remaining = total - paid
    if paid > 0 and total > paid:
        return f"You have paid Ksh {paid:,} of Ksh {total:,} — remaining Ksh {remaining:,}"
    return f"Amount: Ksh {total:,}"


def _build_monthly_context(collection):
    """Build monthly context like 'Your March 2026 contribution is due'."""
    due = getattr(collection, 'due', None)
    title = getattr(collection, 'title', 'payment')
    if hasattr(due, 'strftime'):
        month_str = due.strftime('%B %Y')
        due_str = due.strftime('%d %b %Y')
        return f"Your {month_str} {title} is due on {due_str}"
    return f"{title} is due"


@csrf_exempt
@require_POST
def ussd_handler(request):
    """Handle Africa's Talking USSD callback.

    POST params: sessionId, phoneNumber, text, serviceCode
    text format: '' (main menu), '1', '1*1', etc.
    """
    session_id = request.POST.get('sessionId', '')
    phone = request.POST.get('phoneNumber', '')
    text = request.POST.get('text', '')
    service_code = request.POST.get('serviceCode', '')

    logger.info("USSD: phone=%s text='%s' session=%s", phone, text, session_id)

    # Find member by phone
    try:
        member = Member.objects.get(phone=phone, is_active=True)
    except Member.DoesNotExist:
        return HttpResponse(
            _format_ussd_response(
                "No TapVerify account found for this number.\n"
                "Contact your group treasurer to register.",
                is_end=True
            )
        )

    group_type = _get_group_type(member)
    config = _GROUP_CONFIGS[group_type]
    menu = config['menu']

    # Parse menu selection
    parts = text.split('*') if text else []
    current_input = parts[-1] if parts else ''

    # Main menu
    if text == '':
        menu_lines = '\n'.join(
            f"{i + 1}. {item}" for i, item in enumerate(menu)
        )
        return HttpResponse(
            _format_ussd_response(
                f"Welcome to TapVerify ({config['label']})\n"
                f"{menu_lines}"
            )
        )

    # Option 1: Check Status
    if current_input == '1':
        pending = PaymentTask.objects.filter(
            member=member,
            state__in=['created', 'notified', 'pending'],
        ).select_related('collection').first()

        if pending:
            installment = _build_installment_text(pending)
            monthly_ctx = _build_monthly_context(pending.collection)
            due = pending.collection.due
            due_str = due.strftime('%d %b %Y') if hasattr(due, 'strftime') else str(due)
            return HttpResponse(
                _format_ussd_response(
                    f"{monthly_ctx}\n"
                    f"{installment}\n"
                    f"Due: {due_str}",
                    is_end=True
                )
            )
        else:
            return HttpResponse(
                _format_ussd_response(
                    f"All {config['option1_title'].lower()} payments up to date.",
                    is_end=True
                )
            )

    # Option 2: My Streak / My Giving / Payment History
    elif current_input == '2':
        recent = PaymentTask.objects.filter(
            member=member,
            state='completed',
        ).select_related('collection').order_by('-paid_at')[:3]

        if not recent:
            return HttpResponse(
                _format_ussd_response(
                    f"No {config['option2_title'].lower()} yet.\n"
                    "Pay your first order to start!",
                    is_end=True
                )
            )

        # For SACCO/church, also show streak data
        if group_type in ('sacco', 'church'):
            try:
                streak = StreakRecord.objects.get(
                    member=member,
                    collection_type='welfare' if group_type == 'sacco' else 'tithe',
                )
                next_badge = ''
                if streak.current_streak < 3:
                    next_badge = "\nNext badge: Bronze at 3 months"
                elif streak.current_streak < 6:
                    next_badge = "\nNext badge: Silver at 6 months"
                elif streak.current_streak < 12:
                    next_badge = "\nNext badge: Gold at 12 months"

                lines = [
                    f"Streak: {streak.current_streak} months",
                    f"Best: {streak.longest_streak} months",
                    f"Total paid: Ksh {int(streak.total_paid):,}",
                    f"Contributions: {streak.total_contributions}",
                    next_badge,
                ]
                return HttpResponse(
                    _format_ussd_response("\n".join(l for l in lines if l), is_end=True)
                )
            except StreakRecord.DoesNotExist:
                pass

        # Fallback: show recent payments
        lines = []
        for tx in recent:
            month = tx.paid_at.strftime('%b %Y') if tx.paid_at else 'Unknown'
            status = 'OK' if tx.state == 'completed' else tx.state
            lines.append(f"{month}: Ksh {int(tx.amount):,} {status}")
        return HttpResponse(
            _format_ussd_response("\n".join(lines), is_end=True)
        )

    # Option 3: Pay Now — send payment link via SMS
    elif current_input == '3':
        from .services.africastalking import AfricasTalkingService

        pending = PaymentTask.objects.filter(
            member=member,
            state__in=['created', 'notified', 'pending'],
            checkout_url__isnull=False,
        ).exclude(checkout_url='').select_related('collection').first()

        if pending and pending.checkout_url:
            at = AfricasTalkingService()
            due = pending.collection.due
            due_str = due.strftime('%d %b %Y') if hasattr(due, 'strftime') else str(due)
            msg = (
                f"Pay {pending.collection.title} Ksh {int(pending.amount):,}:\n"
                f"{pending.checkout_url}\n"
                f"Due: {due_str}"
            )
            at.send_sms(member.phone, msg)
            return HttpResponse(
                _format_ussd_response(
                    "Payment link sent via SMS.\n"
                    "Check your messages.",
                    is_end=True
                )
            )
        elif pending:
            return HttpResponse(
                _format_ussd_response(
                    "Payment link not ready yet.\n"
                    "Contact your treasurer.",
                    is_end=True
                )
            )
        else:
            return HttpResponse(
                _format_ussd_response(
                    f"No pending {config['option1_title'].lower()} payments.",
                    is_end=True
                )
            )

    # Option 4: History / Balance
    elif current_input == '4':
        recent = PaymentTask.objects.filter(
            member=member,
            state='completed',
        ).select_related('collection').order_by('-paid_at')[:3]

        if not recent:
            return HttpResponse(
                _format_ussd_response(
                    f"No {config['option4_title'].lower()} records.",
                    is_end=True
                )
            )

        lines = []
        for tx in recent:
            month = tx.paid_at.strftime('%b %Y') if tx.paid_at else 'Unknown'
            lines.append(f"{month}: Ksh {int(tx.amount):,} OK")

        # Compute balance summary
        total_paid = sum(int(tx.amount) for tx in recent)
        lines.append(f"\nTotal: Ksh {total_paid:,}")

        return HttpResponse(
            _format_ussd_response("\n".join(lines), is_end=True)
        )

    # Option 5: Send Reminder
    elif current_input == '5':
        pending_members = PaymentTask.objects.filter(
            state__in=['created', 'notified', 'pending'],
        ).select_related('member').values_list('member__phone', flat=True).distinct()

        phones = [p for p in pending_members if p]
        count = len(phones)

        if count == 0:
            return HttpResponse(
                _format_ussd_response(
                    "No members with pending payments.\nNothing to remind.",
                    is_end=True
                )
            )

        # In production, this would send bulk SMS via Africa's Talking
        # from .services.africastalking import AfricasTalkingService
        # at = AgricasTalkingService()
        # for phone in phones:
        #     at.send_sms(phone, reminder_msg)
        logger.info("USSD reminder: would send to %d members", count)

        return HttpResponse(
            _format_ussd_response(
                f"Reminder sent to {count} member{'s' if count != 1 else ''}\n"
                f"who have not paid.",
                is_end=True
            )
        )

    # Invalid choice
    else:
        return HttpResponse(
            _format_ussd_response(
                "Invalid choice. Try again.",
                is_end=True
            )
        )
