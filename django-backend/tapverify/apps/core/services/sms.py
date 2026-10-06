"""SMS sending (Sozuri primary, Africa's Talking fallback) + all V1 templates.

Message wording follows the V1 product documentation exactly:
invites per payout method, reminders, OTP codes, payment confirmations.
"""
import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

PROD_URL = 'https://api.africastalking.com/version1/messaging'
SANDBOX_URL = 'https://api.sandbox.africastalking.com/version1/messaging'

_SUCCESS_TOKENS = {'success', 'ok', 'sent', 'accepted', 'processed'}


def _messaging_url():
    return SANDBOX_URL if settings.AFRICASTALKING_SANDBOX else PROD_URL


def _sozuri_outcome(data, status_code):
    """Interpret a Sozuri response -> (ok, message_id, error).

    Real shape observed: {"messageData": {...}, "recipients": [{"messageId",
    "to", "status": "sent", "statusCode": "11", ...}]}
    """
    if not isinstance(data, dict):
        return (status_code == 200), None, (None if status_code == 200 else f'http_{status_code}')
    # Carrier-facing result lives on the first recipient.
    recipients = data.get('recipients')
    if isinstance(recipients, list) and recipients and isinstance(recipients[0], dict):
        first = recipients[0]
        status = str(first.get('status') or '').lower()
        ok = status in _SUCCESS_TOKENS
        if ok:
            return True, first.get('messageId'), None
        return False, first.get('messageId'), str(
            first.get('status') or data.get('message') or data.get('error') or 'failed')
    # Nested payload, e.g. {"data": {...}}
    blob = data.get('data') if isinstance(data.get('data'), dict) else {}
    status = str(data.get('status') or blob.get('status') or '').lower()
    msg_id = (data.get('messageId') or data.get('message_id')
              or blob.get('messageId') or blob.get('message_id')
              or data.get('id') or blob.get('id'))
    if data.get('success') is True or status in _SUCCESS_TOKENS:
        return True, msg_id, None
    if status and status not in _SUCCESS_TOKENS:
        return False, msg_id, str(data.get('message') or data.get('error') or status)
    # No recognisable status field: trust HTTP status, keep body for logs.
    if status_code == 200:
        return True, msg_id, None
    return False, msg_id, str(data.get('message') or data.get('error') or f'http_{status_code}')


def send_sozuri(to, message):
    """Send one SMS through Sozuri. Returns (ok, message_id, error)."""
    endpoint = settings.SOZURI_ENDPOINT
    api_key = settings.SOZURI_API_KEY
    if not endpoint or not api_key:
        logger.warning('Sozuri not configured - SMS to %s skipped', to)
        return False, None, 'not_configured'
    payload = {
        'project': settings.SOZURI_PROJECT,
        'apiKey': api_key,
        'from': settings.SOZURI_FROM,
        'to': to,
        'message': message,
        'channel': 'sms',
        'type': settings.SOZURI_TYPE,
    }
    try:
        resp = requests.post(
            endpoint,
            json=payload,
            headers={'Accept': 'application/json'},
            timeout=30,
        )
        try:
            data = resp.json()
        except ValueError:
            data = {}
        logger.info('Sozuri response %s: %s', resp.status_code, str(data)[:500])
        return _sozuri_outcome(data, resp.status_code)
    except Exception as e:  # noqa: BLE001
        logger.exception('Sozuri SMS send failed')
        return False, None, str(e)


def send_africastalking(to, message):
    """Send one SMS through Africa's Talking. Returns (ok, message_id, error)."""
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


def send_sms(to, message):
    """Send one SMS via the configured provider. Returns (ok, message_id, error)."""
    provider = (settings.SMS_PROVIDER or '').lower()
    if provider == 'sozuri':
        ok, msg_id, error = send_sozuri(to, message)
        if error == 'not_configured':
            return send_africastalking(to, message)
        return ok, msg_id, error
    return send_africastalking(to, message)


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
