"""
Africa's Talking full adapter — Bulk SMS, Airtime and USSD in one service.

Three AT products power one TapVerify flow:
  - Bulk SMS  → checkout links, reminders and receipts (feature-phone reach)
  - Airtime   → streak rewards (3-month consistency = Ksh 50 airtime)
  - USSD      → *384*123# balance checks for workers without smartphones

Credentials come from settings/.env:
AFRICASTALKING_USERNAME, AFRICASTALKING_API_KEY,
AFRICASTALKING_SENDER_ID, AFRICASTALKING_AIRTIME_PRODUCT_CODE,
AFRICASTALKING_USSD_SERVICE_CODE.
"""
import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

MESSAGING_URL = "https://api.africastalking.com/version1/messaging"
AIRTIME_URL = "https://api.africastalking.com/version1/airtime/send"
USSD_URL = "https://api.africastalking.com/version1/ussd"


class AfricasTalkingService:
    def __init__(self):
        self.username = getattr(settings, 'AFRICASTALKING_USERNAME', '')
        self.api_key = getattr(settings, 'AFRICASTALKING_API_KEY', '')
        self.sender_id = getattr(settings, 'AFRICASTALKING_SENDER_ID', 'TAPVERIFY')
        self.airtime_product = getattr(
            settings, 'AFRICASTALKING_AIRTIME_PRODUCT_CODE', 'TAPVERIFY')
        self.ussd_code = getattr(settings, 'AFRICASTALKING_USSD_SERVICE_CODE', '*384*123#')

    def _headers(self):
        return {
            'apiKey': self.api_key,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
        }

    @property
    def configured(self):
        return bool(self.username and self.api_key)

    # ── 1. Bulk SMS ──────────────────────────────────────────────────────
    def send_sms(self, to, message, sender_id=None):
        if not self.configured:
            logger.error("Africa's Talking credentials not configured")
            return False, None, "Credentials not configured"
        payload = {
            'username': self.username,
            'to': to,
            'message': message,
            'from': sender_id or self.sender_id,
        }
        try:
            resp = requests.post(MESSAGING_URL, data=payload,
                                 headers=self._headers(), timeout=30)
            data = resp.json()
            recipients = data.get('SMSMessageData', {}).get('Recipients', [])
            if recipients:
                r = recipients[0]
                ok = r.get('status') == 'Success'
                return ok, r.get('messageId'), (None if ok else f"Status: {r.get('status')}")
            return False, None, "No recipients in response"
        except Exception as e:  # noqa: BLE001
            logger.exception("SMS send failed")
            return False, None, str(e)

    def send_bulk(self, recipients, message):
        """recipients: iterable of dicts with 'phone' and 'name'."""
        results = []
        for r in recipients:
            personalized = message.replace("{name}", r.get('name', ''))
            ok, msg_id, err = self.send_sms(r['phone'], personalized)
            results.append((r['phone'], ok, msg_id, err))
        return results

    def send_checkout_link(self, phone, name, amount, checkout_url):
        message = (
            f"TapVerify — {name}, you have a payment of Ksh {amount:,.0f}.\n"
            f"Pay securely: {checkout_url}\n"
            f"Tap the link, pay with M-Pesa, Airtel or card. Receipt follows."
        )
        return self.send_sms(phone, message)

    # ── 2. Airtime rewards ───────────────────────────────────────────────
    def send_airtime(self, phone, amount_ksh, currency_code='KES'):
        """Send airtime as a streak reward."""
        if not self.configured:
            return {'success': False, 'error': 'Credentials not configured'}
        payload = {
            'username': self.username,
            'recipients': [
                {
                    'phoneNumber': phone,
                    'amount': f"{amount_ksh:.2f}",
                    'currencyCode': currency_code,
                    'productCode': self.airtime_product,
                }
            ],
        }
        try:
            resp = requests.post(AIRTIME_URL, json=payload,
                                 headers=self._headers(), timeout=30)
            data = resp.json()
            responses = data.get('Responses', data.get('responses', []))
            if responses:
                status = responses[0].get('status')
                return {
                    'success': status in ('Success', 'Queued', 'Sent'),
                    'status': status,
                    'request_id': responses[0].get('requestId'),
                    'error': responses[0].get('errorMessage'),
                }
            return {'success': False, 'error': 'No responses', 'raw': data}
        except Exception as e:  # noqa: BLE001
            logger.exception("Airtime send failed")
            return {'success': False, 'error': str(e)}

    # ── 3. USSD balance check ─────────────────────────────────────────────
    def ussd_balance(self, phone, session_id, input_='1'):
        """Feature-phone balance check on the TapVerify USSD shortcode."""
        if not self.configured:
            return {'success': False, 'error': 'Credentials not configured',
                    'text': 'END TapVerify is configuring USSD. Call or SMS instead.'}
        payload = {
            'username': self.username,
            'phoneNumber': phone,
            'sessionId': session_id,
            'serviceCode': self.ussd_code,
            'input': input_,
        }
        try:
            resp = requests.post(USSD_URL, data=payload,
                                 headers=self._headers(), timeout=30)
            data = resp.json()
            return {'success': resp.status_code == 200, 'raw': data}
        except Exception as e:  # noqa: BLE001
            logger.exception("USSD request failed")
            return {'success': False, 'error': str(e)}


def build_collection_sms(task, checkout_url=None, workspace_name='', amount=0):
    """A single worker's obligation SMS with (optionally) their checkout link."""
    msg = f"TapVerify — Obligation from {workspace_name}\nKsh {amount:,.0f}"
    if checkout_url:
        msg += f"\nPay now: {checkout_url}"
    msg += "\nReply with any question. Receipt sent after payment."
    return msg