"""
Africa's Talking USSD handler for TapVerify.

Customers without smartphones dial *384*123# to:
  1. Check payment status
  2. View payment history
  3. Request payment link via SMS
  4. View payment history

Endpoint: POST /ussd/
"""
import logging

from django.http import HttpResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

from ..models import Member, PaymentTask, StreakRecord

logger = logging.getLogger(__name__)


def _format_ussd_response(text, is_end=False):
    """Format USSD response. CON = continue menu, END = final message."""
    prefix = "END" if is_end else "CON"
    return f"{prefix} {text}"


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

    # Parse menu selection
    parts = text.split('*') if text else []
    current_input = parts[-1] if parts else ''

    # Main menu
    if text == '':
        return HttpResponse(
            _format_ussd_response(
                "Welcome to TapVerify\n"
                "1. Check Revenue\n"
                "2. My Payment History\n"
                "3. Pay Now\n"
                "4. History"
            )
        )

    # Option 1: Check Status
    if current_input == '1':
        pending = PaymentTask.objects.filter(
            member=member,
            state__in=['created', 'notified', 'pending'],
        ).select_related('collection').first()

        if pending:
            due = pending.collection.due
            due_str = due.strftime('%d %b %Y') if hasattr(due, 'strftime') else str(due)
            return HttpResponse(
                _format_ussd_response(
                    f"Pending: {pending.collection.title}\n"
                    f"Amount: Ksh {int(pending.amount)}\n"
                    f"Due: {due_str}",
                    is_end=True
                )
            )
        else:
            return HttpResponse(
                _format_ussd_response(
                    "All payments up to date.",
                    is_end=True
                )
            )

    # Option 2: My Streak
    elif current_input == '2':
        try:
            streak = StreakRecord.objects.get(
                member=member,
                collection_type='welfare',
            )
            next_badge = ''
            if streak.current_streak < 3:
                next_badge = f"\nNext badge: Bronze at 3 months"
            elif streak.current_streak < 6:
                next_badge = f"\nNext badge: Silver at 6 months"
            elif streak.current_streak < 12:
                next_badge = f"\nNext badge: Gold at 12 months"

            return HttpResponse(
                _format_ussd_response(
                    f"Streak: {streak.current_streak} months\n"
                    f"Best: {streak.longest_streak} months\n"
                    f"Total paid: Ksh {int(streak.total_paid)}\n"
                    f"Contributions: {streak.total_contributions}"
                    f"{next_badge}",
                    is_end=True
                )
            )
        except StreakRecord.DoesNotExist:
            return HttpResponse(
                _format_ussd_response(
                    "No payment history yet.\n"
                    "Pay your first order to start!",
                    is_end=True
                )
            )

    # Option 3: Pay Now — send payment link via SMS
    elif current_input == '3':
        from ..services.africastalking import AfricasTalkingService

        pending = PaymentTask.objects.filter(
            member=member,
            state__in=['created', 'notified', 'pending'],
            checkout_url__isnull=False,
        ).exclude(checkout_url='').select_related('collection').first()

        if pending and pending.checkout_url:
            at = AfricasTalkingService()
            msg = (
                f"Pay {pending.collection.title} Ksh {int(pending.amount)}:\n"
                f"{pending.checkout_url}\n"
                f"Due: {pending.collection.due.strftime('%d %b %Y')}"
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
                    "No pending payments.",
                    is_end=True
                )
            )

    # Option 4: History
    elif current_input == '4':
        recent = PaymentTask.objects.filter(
            member=member,
            state='completed',
        ).select_related('collection').order_by('-paid_at')[:3]

        if not recent:
            return HttpResponse(
                _format_ussd_response(
                    "No payment history.",
                    is_end=True
                )
            )

        lines = []
        for tx in recent:
            month = tx.paid_at.strftime('%b %Y') if tx.paid_at else 'Unknown'
            lines.append(f"{month}: Ksh {int(tx.amount)} OK")

        return HttpResponse(
            _format_ussd_response("\n".join(lines), is_end=True)
        )

    # Invalid choice
    else:
        return HttpResponse(
            _format_ussd_response(
                "Invalid choice. Try again.",
                is_end=True
            )
        )
