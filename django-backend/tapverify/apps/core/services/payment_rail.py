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
    """Loop API integration — Request to Pay + IPN."""

    SANDBOX_URL = "https://sandbox.looponline.co.ke"
    PRODUCTION_URL = "https://api.looponline.co.ke"

    def __init__(self):
        self.base_url = getattr(settings, 'LOOP_BASE_URL', self.SANDBOX_URL)
        self.api_key = getattr(settings, 'LOOP_API_KEY', '')
        self.merchant_id = getattr(settings, 'LOOP_MERCHANT_ID', '')
        self.ipn_secret = getattr(settings, 'LOOP_IPN_SECRET', '')

    def _headers(self):
        return {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    def initiate_payment(self, phone, amount, reference, description=''):
        """
        Request to Pay — sends M-Pesa prompt to the member's phone.
        POST /api/v1/request-to-pay
        """
        payload = {
            'amount': float(amount),
            'phone': phone,
            'merchant_id': self.merchant_id,
            'reference': reference,
            'description': description or f'TapVerify payment {reference}',
            'callback_url': f'{settings.RECEIPT_BASE_URL}/api/v1/webhooks/loop/',
        }

        try:
            resp = requests.post(
                f"{self.base_url}/api/v1/request-to-pay",
                json=payload,
                headers=self._headers(),
                timeout=30
            )
            data = resp.json()
            return {
                'success': resp.status_code in [200, 201],
                'transaction_id': data.get('transaction_id') or data.get('id'),
                'status': data.get('status'),
                'message': data.get('message'),
            }
        except Exception as e:
            logger.exception("Loop payment initiation failed")
            return {'success': False, 'error': str(e)}

    def verify_webhook(self, payload, headers):
        """
        Verify Loop IPN callback.
        Loop sends: {reference, status, amount, receipt_number, phone, ...}
        """
        # In production, verify signature from headers
        # signature = headers.get('X-Loop-Signature')
        # if not self._verify_signature(payload, signature):
        #     return {'valid': False, 'error': 'Invalid signature'}

        status = payload.get('status', '').upper()
        return {
            'valid': True,
            'reference': payload.get('reference'),
            'status': 'success' if status in ('SUCCESS', 'COMPLETED', 'PAID') else 'failed',
            'amount': payload.get('amount'),
            'receipt_number': payload.get('receipt_number') or payload.get('mpesa_receipt'),
            'phone': payload.get('phone') or payload.get('phone_number'),
            'raw': payload,
        }

    def check_status(self, reference):
        """
        GET /api/v1/transactions/{reference}/status
        """
        try:
            resp = requests.get(
                f"{self.base_url}/api/v1/transactions/{reference}/status",
                headers=self._headers(),
                timeout=15
            )
            data = resp.json()
            return {
                'status': data.get('status', 'unknown'),
                'reference': reference,
                'receipt_number': data.get('receipt_number'),
            }
        except Exception as e:
            logger.exception("Loop status check failed")
            return {'status': 'error', 'reference': reference, 'error': str(e)}

    def get_rail_name(self):
        return 'loop'


def get_payment_rail(rail_name=None):
    """Factory — returns the configured payment rail."""
    rail = rail_name or getattr(settings, 'ACTIVE_PAYMENT_RAIL', 'loop')
    rails = {
        'payhero': PayHeroRail,
        'loop': LoopRail,
    }
    rail_class = rails.get(rail, LoopRail)
    return rail_class()
