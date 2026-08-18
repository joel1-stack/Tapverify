"""
SasaPay Checkout rail (Kenya).

Contract (from the SasaPay API docs, wired per the TapVerify plan, Aug 2026):

  - OAuth token:
        GET {base}/oauth/v1/generate?grant_type=client_credentials
        Authorization: Basic base64(CLIENT_ID:SECRET)
  - Create checkout: POST {base}/api/v1/checkout/create with merchant code,
    account number, payment reference, transaction code, amount and the
    callback URL. Returns CheckoutRequestID + CheckoutUrl (the link you send
    the worker by SMS).
  - Callback signature: header `X-SasaPay-Signature` is an HMAC-SHA512 of the
    canonical string
        transaction_code-merchant_code-account_number-payment_reference-amount
    keyed with the SasaPay client secret.

Credentials come from settings/.env (never hard-coded):
SASAPAY_BASE_URL, SASAPAY_CLIENT_ID, SASAPAY_CLIENT_SECRET, SASAPAY_MERCHANT_CODE,
SASAPAY_ACCOUNT_NUMBER, SASAPAY_CALLBACK_URL.
"""
import base64
import hashlib
import hmac
import logging
import time
import uuid

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

SANDBOX_URL = "https://sandbox.sasapay.app"


class SasaPayError(Exception):
    """Raised when SasaPay returns an error."""


class SasaPayClient:
    def __init__(self):
        self.base_url = getattr(settings, 'SASAPAY_BASE_URL', SANDBOX_URL).rstrip('/')
        self.client_id = getattr(settings, 'SASAPAY_CLIENT_ID', '')
        self.client_secret = getattr(settings, 'SASAPAY_CLIENT_SECRET', '')
        self.merchant_code = getattr(settings, 'SASAPAY_MERCHANT_CODE', '')
        self.account_number = getattr(settings, 'SASAPAY_ACCOUNT_NUMBER', '')
        self.callback_url = getattr(settings, 'SASAPAY_CALLBACK_URL',
                                    f'{self.base_url}/api/v1/webhooks/sasapay/')
        self._access_token = None
        self._token_expires_at = 0

    # ── Step 1 — OAuth bearer token ───────────────────────────────────────
    def get_access_token(self, force=False):
        """Cached OAuth2 bearer token; SasaPay returns it as JSON on GET."""
        now = time.time()
        if not force and self._access_token and now < self._token_expires_at:
            return self._access_token
        basic = base64.b64encode(
            f"{self.client_id}:{self.client_secret}".encode('utf-8')
        ).decode('ascii')
        try:
            resp = requests.get(
                f"{self.base_url}/oauth/v1/generate",
                params={'grant_type': 'client_credentials'},
                headers={
                    'Authorization': f'Basic {basic}',
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
                timeout=30,
            )
        except requests.RequestException as e:
            logger.exception("SasaPay token network error")
            raise SasaPayError(f"SasaPay token request failed: {e}")
        data = resp.json() if resp.text else {}
        token = data.get('access_token') or data.get('token') \
            or data.get('data', {}).get('token') or data.get('accessToken')
        if resp.status_code >= 400 or not token:
            logger.warning("SasaPay token error %s: %s", resp.status_code, data)
            raise SasaPayError(
                f"Could not obtain SasaPay access token ({resp.status_code}). "
                "Check client id/secret and the OAuth endpoint."
            )
        self._access_token = token
        expires_in = data.get('expires_in') or data.get('expiresIn') or 3600
        try:
            expires_in = int(expires_in)
            if expires_in > 10_000_000:  # ms
                expires_in //= 1000
        except (TypeError, ValueError):
            expires_in = 3600
        self._token_expires_at = now + expires_in - 60
        return token

    def _headers(self):
        return {
            'Authorization': f'Bearer {self.get_access_token()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    # ── Step 2 — create the checkout ──────────────────────────────────────
    def create_checkout(self, phone, amount, reference, description=''):
        """Create a SasaPay Checkout and return {CheckoutRequestID, CheckoutUrl}.

        The CheckoutUrl is what the worker taps from the SMS; the callback is
        signed with X-SasaPay-Signature so TapVerify can verify the proof.
        """
        if not self.client_id or not self.client_secret:
            return {'success': False, 'error': 'SasaPay client credentials not configured'}
        if not self.merchant_code:
            return {'success': False, 'error': 'SasaPay merchant code not configured'}
        payload = {
            'MerchantCode': self.merchant_code,
            'AccountNumber': self.account_number,
            'TransactionCode': reference or str(uuid.uuid4()).upper()[:16],
            'PaymentReference': reference,
            'Amount': f"{amount:.2f}",
            'PhoneNumber': phone,
            'CallbackURL': self.callback_url,
            'Description': description or 'TapVerify collection',
        }
        url = getattr(settings, 'SASAPAY_CHECKOUT_URL',
                      f"{self.base_url}/api/v1/checkout/create")
        try:
            resp = requests.post(url, json=payload, headers=self._headers(), timeout=30)
            data = resp.json() if resp.text else {}
        except requests.RequestException as e:
            logger.exception("SasaPay checkout network error")
            return {'success': False, 'error': str(e)}
        if resp.status_code >= 400:
            logger.warning("SasaPay checkout HTTP %s: %s", resp.status_code, data)
            return {
                'success': False,
                'http_code': resp.status_code,
                'message': data.get('message') or data.get('status') or 'checkout failed',
                'raw': data,
            }
        return {
            'success': True,
            'checkout_request_id': data.get('CheckoutRequestID')
                                   or data.get('checkoutRequestId')
                                   or data.get('data', {}).get('CheckoutRequestID'),
            'checkout_url': data.get('CheckoutUrl')
                            or data.get('checkoutUrl')
                            or data.get('data', {}).get('CheckoutUrl'),
            'message': data.get('message'),
            'raw': data,
        }

    # ── Step 3 — verify the webhook signature ─────────────────────────────
    def verify_signature(self, payload, signature):
        """Verify X-SasaPay-Signature (HMAC-SHA512).

        Canonical message:
            transaction_code-merchant_code-account_number-payment_reference-amount
        """
        if not self.client_secret or not signature:
            return False
        tx_code = payload.get('transaction_code') or payload.get('TransactionCode') or ''
        merchant = payload.get('merchant_code') or payload.get('MerchantCode') or ''
        account = payload.get('account_number') or payload.get('AccountNumber') or ''
        reference = payload.get('payment_reference') or payload.get('PaymentReference') or ''
        amount = payload.get('amount') or payload.get('Amount') or ''
        message = f"{tx_code}-{merchant}-{account}-{reference}-{amount}"
        expected = hmac.new(
            self.client_secret.encode('utf-8'),
            message.encode('utf-8'),
            hashlib.sha512,
        ).hexdigest()
        return hmac.compare_digest(expected, signature.lower())

    def verify_webhook(self, payload, headers):
        """Normalized webhook verification used by the payment_rail facade."""
        signature = (headers.get('X-SasaPay-Signature') or headers.get('X-SASAPAY-SIGNATURE') or '')
        valid = self.verify_signature(payload, signature)
        return {
            'valid': valid,
            'reference': payload.get('payment_reference') or payload.get('PaymentReference'),
            'status': 'success' if valid and payload.get('payment_status') in ('success', 'COMPLETED') else 'pending',
            'amount': payload.get('amount') or payload.get('Amount'),
            'receipt_number': payload.get('transaction_code') or payload.get('TransactionCode'),
            'phone': payload.get('phone_number') or payload.get('PhoneNumber'),
        }

    def check_status(self, reference):
        """SasaPay status is delivered via callback; inquiry is the stored record."""
        return {'status': 'callback', 'reference': reference}

    def get_rail_name(self):
        return 'sasapay'