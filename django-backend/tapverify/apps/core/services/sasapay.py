"""
SasaPay Checkout API client for TapVerify.

Endpoints (from SasaPay docs):
  - OAuth token:    POST {base}/api/v1/auth/token/?grant_type=client_credentials
                    Authorization: Basic base64(CLIENT_ID:SECRET)
  - Create checkout: POST {base}/api/v1/payments/card-payments/
                    Authorization: Bearer {token}
                    Returns CheckoutRequestID + CheckoutUrl
  - Query transactions: GET {base}/api/v2/waas/transactions/?merchant_code={code}&page={n}
                    Authorization: Bearer {token}
  - Webhook:        POST {callback_url}
                    X-SasaPay-Signature: HMAC-SHA512(canonical_string, secret)

Canonical string for HMAC:
    transaction_code-merchant_code-account_number-payment_reference-amount

Success code: SP00000

Credentials from settings/.env:
  SASAPAY_BASE_URL, SASAPAY_CLIENT_ID, SASAPAY_CLIENT_SECRET,
  SASAPAY_MERCHANT_CODE, SASAPAY_ACCOUNT_NUMBER, SASAPAY_CALLBACK_URL
"""
import base64
import hashlib
import hmac
import json
import logging
import time
import uuid

import requests
from django.conf import settings

logger = logging.getLogger(__name__)

SANDBOX_URL = "https://sandbox.sasapay.app"

# SasaPay result codes
SUCCESS_CODES = ('SP00000', '0')
FAILED_CODES = ('SP01003', 'SP404', 'SP401', 'SP403', 'SP409')


class SasaPayError(Exception):
    """Raised when SasaPay returns an error."""


class SasaPayClient:
    """SasaPay Checkout API client.

    Usage:
        client = SasaPayClient()
        token = client.get_access_token()
        result = client.create_checkout(phone, amount, reference, description)
        # result = {'success': True, 'checkout_url': '...', 'checkout_request_id': '...'}
    """

    def __init__(self):
        self.base_url = getattr(settings, 'SASAPAY_BASE_URL', SANDBOX_URL).rstrip('/')
        self.client_id = getattr(settings, 'SASAPAY_CLIENT_ID', '')
        self.client_secret = getattr(settings, 'SASAPAY_CLIENT_SECRET', '')
        self.merchant_code = getattr(settings, 'SASAPAY_MERCHANT_CODE', '')
        self.account_number = getattr(settings, 'SASAPAY_ACCOUNT_NUMBER', '')
        self.callback_url = getattr(settings, 'SASAPAY_CALLBACK_URL', '')
        self._access_token = None
        self._token_expires_at = 0

    # ── OAuth2 token ──────────────────────────────────────────────────────
    def get_access_token(self, force=False):
        """Get OAuth2 bearer token via client_credentials grant.

        POST {base}/api/v1/auth/token/?grant_type=client_credentials
        Authorization: Basic base64(CLIENT_ID:SECRET)
        """
        now = time.time()
        if not force and self._access_token and now < self._token_expires_at:
            return self._access_token

        credentials = base64.b64encode(
            f"{self.client_id}:{self.client_secret}".encode('utf-8')
        ).decode('ascii')

        try:
            resp = requests.get(
                f"{self.base_url}/api/v1/auth/token/?grant_type=client_credentials",
                headers={
                    'Authorization': f'Basic {credentials}',
                    'Accept': 'application/json',
                },
                timeout=30,
            )
        except requests.RequestException as e:
            logger.exception("SasaPay token network error")
            raise SasaPayError(f"Token request failed: {e}")

        data = resp.json() if resp.text else {}
        token = (
            data.get('access_token')
            or data.get('token')
            or data.get('data', {}).get('token')
            or data.get('accessToken')
        )

        if resp.status_code >= 400 or not token:
            logger.warning("SasaPay token error %s: %s", resp.status_code, data)
            raise SasaPayError(
                f"Could not obtain token ({resp.status_code}). "
                f"Check client_id/secret. Response: {data}"
            )

        self._access_token = token
        expires_in = data.get('expires_in') or data.get('expiresIn') or 3600
        try:
            expires_in = int(expires_in)
            if expires_in > 10_000_000:
                expires_in //= 1000
        except (TypeError, ValueError):
            expires_in = 3600
        self._token_expires_at = now + expires_in - 60
        logger.info("SasaPay token obtained, expires in %ds", expires_in)
        return token

    def _auth_headers(self):
        return {
            'Authorization': f'Bearer {self.get_access_token()}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        }

    # ── Create Checkout ───────────────────────────────────────────────────
    def create_checkout(self, phone, amount, reference, description='',
                        callback_url=None):
        """Create a SasaPay Checkout payment.

        POST {base}/api/v1/payments/card-payments/

        Returns:
            {
                'success': True,
                'checkout_request_id': 'PR1234...',
                'checkout_url': 'https://sandbox.sasapay.app/...',
                'raw': {...}
            }
        """
        if not self.client_id or not self.client_secret:
            return {'success': False, 'error': 'SasaPay credentials not configured'}
        if not self.merchant_code:
            return {'success': False, 'error': 'SasaPay merchant code not configured'}

        payload = {
            'MerchantCode': self.merchant_code,
            'Amount': str(int(amount)),
            'Reference': reference or str(uuid.uuid4()).upper()[:12],
            'Description': description or 'TapVerify collection',
            'Currency': 'KES',
            'PhoneNumber': phone,
            'CallbackUrl': callback_url or self.callback_url,
            'MpesaEnabled': True,
            'AirtelEnabled': True,
            'CardEnabled': True,
            'SasaPayWalletEnabled': True,
            'RedirectEnabled': True,
        }

        try:
            resp = requests.post(
                f"{self.base_url}/api/v1/payments/card-payments/",
                json=payload,
                headers=self._auth_headers(),
                timeout=30,
            )
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

        checkout_url = (
            data.get('CheckoutUrl')
            or data.get('checkoutUrl')
            or data.get('data', {}).get('CheckoutUrl')
        )
        checkout_id = (
            data.get('CheckoutRequestID')
            or data.get('checkoutRequestId')
            or data.get('data', {}).get('CheckoutRequestID')
        )

        return {
            'success': True,
            'checkout_request_id': checkout_id,
            'checkout_url': checkout_url,
            'message': data.get('message'),
            'raw': data,
        }

    # ── Query Transactions ────────────────────────────────────────────────
    def query_transactions(self, page=1, merchant_code=None):
        """Query SasaPay transaction history.

        GET {base}/api/v2/waas/transactions/?merchant_code={code}&page={n}

        Returns list of transaction dicts with:
            - transaction_amount
            - transaction_code
            - transaction_reference
            - transaction_date
            - result_code (SP00000 = success)
            - result_description
            - reversal_status
        """
        code = merchant_code or self.merchant_code
        try:
            resp = requests.get(
                f"{self.base_url}/api/v2/waas/transactions/",
                headers=self._auth_headers(),
                params={'merchant_code': code, 'page': page},
                timeout=30,
            )
            data = resp.json() if resp.text else {}
        except requests.RequestException as e:
            logger.exception("SasaPay transaction query failed")
            return []

        if not data.get('status'):
            logger.warning("Transaction query issue: %s", data.get('message'))
            return []

        return data.get('data', [])

    def reconcile_all(self, merchant_code=None):
        """Pull ALL transaction pages for reconciliation."""
        all_txs = []
        page = 1
        while True:
            txs = self.query_transactions(page=page, merchant_code=merchant_code)
            if not txs:
                break
            all_txs.extend(txs)
            page += 1
        return all_txs

    # ── Webhook Signature Verification ────────────────────────────────────
    def verify_signature(self, payload, signature):
        """Verify X-SasaPay-Signature (HMAC-SHA512).

        Canonical string:
            transaction_code-merchant_code-account_number-payment_reference-amount
        """
        if not self.client_secret or not signature:
            return False

        tx_code = payload.get('TransactionCode') or payload.get('transaction_code') or ''
        merchant = payload.get('MerchantCode') or payload.get('merchant_code') or self.merchant_code
        account = payload.get('AccountNumber') or payload.get('account_number') or self.account_number
        reference = payload.get('Reference') or payload.get('payment_reference') or ''
        amount = payload.get('Amount') or payload.get('amount') or ''

        canonical = f"{tx_code}-{merchant}-{account}-{reference}-{amount}"
        expected = hmac.new(
            self.client_secret.encode('utf-8'),
            canonical.encode('utf-8'),
            hashlib.sha512,
        ).hexdigest()

        return hmac.compare_digest(expected, signature.lower().strip())

    def verify_webhook(self, payload, headers):
        """Normalized webhook verification for payment_rail facade."""
        signature = (
            headers.get('X-SasaPay-Signature')
            or headers.get('X-SASAPAY-SIGNATURE')
            or ''
        )
        valid = self.verify_signature(payload, signature)

        result_code = str(
            payload.get('ResultCode')
            or payload.get('result_code')
            or ''
        )
        is_success = result_code in SUCCESS_CODES

        return {
            'valid': valid,
            'reference': (
                payload.get('Reference')
                or payload.get('payment_reference')
                or payload.get('MerchantRequestID')
                or payload.get('CheckoutRequestID')
            ),
            'status': 'success' if valid and is_success else 'pending',
            'amount': payload.get('Amount') or payload.get('amount'),
            'receipt_number': (
                payload.get('TransactionCode')
                or payload.get('transaction_code')
            ),
            'phone': payload.get('PhoneNumber') or payload.get('phone_number'),
            'result_code': result_code,
            'result_description': (
                payload.get('ResultDesc')
                or payload.get('result_description')
                or ''
            ),
        }

    def check_status(self, reference):
        """Check transaction status via query API."""
        txs = self.query_transactions()
        for tx in txs:
            if tx.get('transaction_reference') == reference:
                return {
                    'status': 'success' if tx.get('result_code') in SUCCESS_CODES else 'failed',
                    'reference': reference,
                    'transaction_code': tx.get('transaction_code'),
                    'result_code': tx.get('result_code'),
                    'result_description': tx.get('result_description'),
                }
        return {'status': 'unknown', 'reference': reference}

    def get_rail_name(self):
        return 'sasapay'


# Singleton
_client = None


def get_sasapay_client():
    global _client
    if _client is None:
        _client = SasaPayClient()
    return _client
