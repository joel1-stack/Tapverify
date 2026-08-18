import requests
import logging
from django.conf import settings

logger = logging.getLogger(__name__)


class PaymentRail:
    """Abstract base class for payment rails. Implement this for any PSP."""

    def initiate_payment(self, phone, amount, reference, description=''):
        raise NotImplementedError

    def verify_webhook(self, payload, headers):
        raise NotImplementedError

    def check_status(self, reference):
        raise NotImplementedError

    def get_rail_name(self):
        raise NotImplementedError


class PayHeroRail(PaymentRail):
    """PayHero integration (existing)."""

    BASE_URL = "https://api.payhero.co.ke"

    def __init__(self):
        self.username = getattr(settings, 'PAYHERO_API_USERNAME', '')
        self.password = getattr(settings, 'PAYHERO_API_PASSWORD', '')
        self.channel_id = getattr(settings, 'PAYHERO_CHANNEL_ID', '')

    def _headers(self):
        return {
            'Authorization': f'Basic {self._basic_auth()}',
            'Content-Type': 'application/json',
        }

    def _basic_auth(self):
        import base64
        creds = f"{self.username}:{self.password}"
        return base64.b64encode(creds.encode()).decode()

    def initiate_payment(self, phone, amount, reference, description=''):
        """Initiate STK push via PayHero."""
        payload = {
            'amount': str(amount),
            'phone': phone,
            'channel_id': self.channel_id,
            'account_reference': reference,
            'callback_url': f'{settings.RECEIPT_BASE_URL}/api/v1/webhooks/mpesa/',
        }

        try:
            resp = requests.post(
                f"{self.BASE_URL}/api/v2/gateway/ stk_push",
                json=payload,
                headers=self._headers(),
                timeout=30
            )
            data = resp.json()
            return {
                'success': resp.status_code in [200, 201],
                'transaction_id': data.get('transaction_id'),
                'status': data.get('status'),
                'message': data.get('message'),
            }
        except Exception as e:
            logger.exception("PayHero payment initiation failed")
            return {'success': False, 'error': str(e)}

    def verify_webhook(self, payload, headers):
        """Verify PayHero callback (simplified for hackathon)."""
        return {
            'valid': True,
            'reference': payload.get('accountReference') or payload.get('reference'),
            'status': 'success' if payload.get('ResultCode') == '0' else 'failed',
            'amount': payload.get('amount') or payload.get('TransAmount'),
            'receipt_number': payload.get('mpesaReceiptNumber') or payload.get('TransID'),
            'phone': payload.get('phoneNumber') or payload.get('phone'),
        }

    def check_status(self, reference):
        return {'status': 'unknown', 'reference': reference}

    def get_rail_name(self):
        return 'payhero'


class LoopRail(PaymentRail):
    """Loop API integration — Request to Pay + IPN (delegates to loop package)."""

    def __init__(self):
        from .loop.client import LoopClient
        self.client = LoopClient()

    def _headers(self):
        return self.client._headers()

    def initiate_payment(self, phone, amount, reference, description=''):
        return self.client.request_to_pay(phone, amount, reference, description)

    def verify_webhook(self, payload, headers):
        from .loop.webhook import parse_ipn
        return parse_ipn(payload, headers)

    def check_status(self, reference):
        return self.client.check_status(reference)

    def get_rail_name(self):
        return 'loop'


class SasaPayRail(PaymentRail):
    """SasaPay Checkout rail — OAuth token + Checkout link + signed callback."""

    def __init__(self):
        from .sasapay import SasaPayClient
        self.client = SasaPayClient()

    def initiate_payment(self, phone, amount, reference, description=''):
        return self.client.create_checkout(phone, amount, reference, description)

    def verify_webhook(self, payload, headers):
        return self.client.verify_webhook(payload, headers)

    def check_status(self, reference):
        return self.client.check_status(reference)

    def get_rail_name(self):
        return 'sasapay'


def get_payment_rail(rail_name=None):
    """Factory — returns the configured payment rail."""
    rail = rail_name or getattr(settings, 'ACTIVE_PAYMENT_RAIL', 'loop')
    rails = {
        'payhero': PayHeroRail,
        'loop': LoopRail,
        'sasapay': SasaPayRail,
    }
    rail_class = rails.get(rail, LoopRail)
    return rail_class()
