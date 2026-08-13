"""
Loop (NCBA) API client — Request to Pay.

Integration point for the hackathon. The real sandbox endpoint, auth and
field names go here. Everything else in the app already calls through this
module via LoopRail.
"""
import hashlib
import hmac
import logging

import requests
from django.conf import settings

logger = logging.getLogger(__name__)


class LoopAPIError(Exception):
    """Raised when Loop returns an error response."""


class LoopClient:
    SANDBOX_URL = "https://sandbox.looponline.co.ke"
    PRODUCTION_URL = "https://api.looponline.co.ke"

    def __init__(self):
        self.base_url = getattr(settings, 'LOOP_BASE_URL', self.SANDBOX_URL).rstrip('/')
        self.api_key = getattr(settings, 'LOOP_API_KEY', '')
        self.merchant_id = getattr(settings, 'LOOP_MERCHANT_ID', '')
        self.ipn_secret = getattr(settings, 'LOOP_IPN_SECRET', '')

    # ── Wire these to the sandbox contract from the briefing ──
    REQUEST_TO_PAY_PATH = "/api/v1/request-to-pay"
    STATUS_PATH = "/api/v1/transactions/{reference}/status"
    SIGNATURE_HEADER = "X-Loop-Signature"

    def _headers(self):
        return {
            # Verify the auth type at the briefing: Bearer / API key / Basic
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    def request_to_pay(self, phone, amount, reference, description=''):
        """
        Trigger an M-Pesa prompt (STK push) to `phone`.

        phone    : '2547...' (confirm the format Loop expects)
        amount   : shillings. Confirm whether Loop wants cents.
        reference: unique ref (PaymentLink.token).
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
                self.base_url + self.REQUEST_TO_PAY_PATH,
                json=payload,
                headers=self._headers(),
                timeout=30,
            )
            return self._parse_response(resp)
        except requests.RequestException as e:
            logger.exception("Loop request_to_pay network error")
            return {'success': False, 'error': str(e)}

    def check_status(self, reference):
        try:
            resp = requests.get(
                self.base_url + self.STATUS_PATH.format(reference=reference),
                headers=self._headers(),
                timeout=15,
            )
            data = self._safe_json(resp)
            return {
                'success': resp.status_code in (200, 201),
                'status': data.get('status', 'unknown'),
                'receipt_number': data.get('receipt_number') or data.get('mpesa_receipt'),
            }
        except requests.RequestException as e:
            logger.exception("Loop status check network error")
            return {'success': False, 'error': str(e)}

    def verify_signature(self, payload, signature):
        """
        Verify the IPN is genuinely from Loop (HMAC-SHA256 of raw body).
        Fill in the exact algorithm/format from the briefing.
        """
        if not self.ipn_secret:
            return False
        if not signature:
            return False
        expected = hmac.new(
            self.ipn_secret.encode(),
            payload.encode('utf-8'),
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(expected, signature)

    @staticmethod
    def _safe_json(resp):
        try:
            return resp.json()
        except ValueError:
            return {}

    def _parse_response(self, resp):
        data = self._safe_json(resp)
        if resp.status_code in (200, 201):
            return {
                'success': True,
                'transaction_id': data.get('transaction_id') or data.get('id'),
                'status': data.get('status'),
                'message': data.get('message'),
                'raw': data,
            }
        logger.warning(f"Loop error {resp.status_code}: {data}")
        return {
            'success': False,
            'status_code': resp.status_code,
            'error': data.get('message') or data.get('error') or f'HTTP {resp.status_code}',
            'raw': data,
        }
