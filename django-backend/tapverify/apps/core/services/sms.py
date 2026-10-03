"""Africa's Talking SMS sending + all V1 message templates.

Message wording follows the V1 product documentation exactly:
invites per payout method, reminders, OTP codes, payment confirmations.
"""
import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

PROD_URL = 'https://api.africastalking.com/version1/messaging'
SANDBOX_URL = 'https://api.sandbox.africastalking.com/version1/messaging'


def _messaging_url():
    return SANDBOX_URL if settings.AFRICASTALKING_SANDBOX else PROD_URL


def send_sms(to, message):
    """Send one SMS. Returns (ok, message_id, error)."""
    username = settings.AFRICASTALKING_USERNAME
    api_key = settings.AFRICASTALKING_API_KEY
    if not username or not api_key:
        logger.warning('Africa\'s Talking not configured - SMS to %s skipped', to)
        return False, None, 'not_configured'
    payload = {
        'username': username,
        'to': to,
        'message': message,
        'from': settings.AFRICASTALKING_SENDER_ID,
    }
    try:
        resp = requests.post(
            _messaging_url(),
            data=payload,
            headers={
                'apiKey': api_key,
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
            },
            timeout=30,
        )
        data = resp.json()
        recipients = data.get('SMSMessageData', {}).get('Recipients', [])
        if not recipients:
            return False, None, 'no_recipients'
        first = recipients[0]
        ok = first.get('status') == 'Success'
        return ok, first.get('messageId'), (None if ok else first.get('status'))
    except Exception as e:  # noqa: BLE001
        logger.exception('SMS send failed')
        return False, None, str(e)


def member_pay_link(member):
    return f'{settings.PAYMENT_LINK_BASE}/p/{member.pay_code}/'


def fmt_amount(amount):
    return f'{amount:,.0f}'


# --- Templates (wording per V1 product doc) ---

def build_invite_sms(collection, member):
    link = member_pay_link(member)
    head = f'TapVerify\n{collection.title}, KES {fmt_amount(collection.amount)}\n\n'
    if collection.payout_method == collection.TILL:
        body = (f'Pay to Till: {collection.till_number}\n'
                f'(Use your full name as reference)\n')
    elif collection.payout_method == collection.PAYBILL:
        body = (f'Paybill: {collection.paybill_number}\n'
                f'Account: {collection.paybill_account or "Your Name"}\n')
    elif collection.payout_method == collection.PERSONAL:
        body = (f'Send to: {collection.personal_phone}\n'
                f'(Use your name as reference)\n')
    else:  # BANK
        body = (f'Bank: {collection.bank_details}\n'
                f'(Use your name as reference)\n')
    return f'{head}{body}\nOr pay here: {link}'


def build_reminder_sms(collection, member):
    return (
        f'Reminder from TapVerify\n'
        f'{collection.title}, KES {fmt_amount(collection.amount)} is still unpaid.\n\n'
        f'Pay here: {member_pay_link(member)}'
    )


def build_otp_sms(code):
    return f'Your TapVerify login code is {code}. It expires in 10 minutes.'


def build_payment_confirmation_sms(collection, member):
    return (
        f'Your payment of KES {fmt_amount(member.paid_amount or collection.amount)} '
        f'for {collection.title} has been received. Thank you.'
    )
