"""
Safaricom Daraja (M-Pesa) client for TapVerify.

Endpoints (sandbox base https://sandbox.safaricom.co.ke):
  - OAuth token:   GET /oauth/v1/generate?grant_type=client_credentials
                   Authorization: Basic base64(CONSUMER_KEY:CONSUMER_SECRET)
  - STK Push:      POST /mpesa/stkpush/v1/processrequest
                   BusinessShortCode, Password, Timestamp, Amount, PartyA,
                   PartyB, PhoneNumber, CallBackURL, AccountReference,
                   TransactionDesc
  - The result arrives later on CallBackURL as:
      {"Body": {"stkCallback": {"MerchantRequestID", "CheckoutRequestID",
        "ResultCode", "ResultDesc",
        "CallbackMetadata": {"Item": [{"Name", "Value"}, ...]}}}}

Credentials from settings/.env (never committed):
  MPESA_ENV (sandbox | production), MPESA_CONSUMER_KEY, MPESA_CONSUMER_SECRET,
  MPESA_PASSKEY, MPESA_SHORTCODE, MPESA_CALLBACK_URL

The callback URL is sent with EVERY STK Push request, so no portal
registration is required for STK Push itself. TapVerify sends members to
https://tapverify.vercel.app/api/mpesa/callback (a small Vercel relay) which
forwards the payload to this backend via MPESA_FORWARD_URL.
"""
import base64
import logging
import time
from decimal import ROUND_HALF_UP, Decimal

import requests
from django.conf import settings

from ..utils import normalize_ke_phone

logger = logging.getLogger(__name__)

SANDBOX_BASE = 'https://sandbox.safaricom.co.ke'
PRODUCTION_BASE = 'https://api.safaricom.co.ke'


class MpesaError(Exception):
    """Raised when Daraja cannot start a payment."""


def daraja_phone(raw):
    """Daraja wants 2547XXXXXXXX - digits only, no plus, no leading zero."""
    normalized = normalize_ke_phone(raw)
    return normalized.replace('+', '').lstrip('0') if normalized else ''


def stk_amount(value):
    """Daraja takes whole shillings only (min 1)."""
    try:
        amount = int(Decimal(str(value)).quantize(Decimal('1'), rounding=ROUND_HALF_UP))
    except Exception:
        amount = 0
    return max(amount, 1)


class MpesaClient:
    """Daraja STK Push client. Reads credentials from Django settings."""

    def __init__(self):
        env = (getattr(settings, 'MPESA_ENV', 'sandbox') or 'sandbox').lower()
        self.base_url = (
            PRODUCTION_BASE if env.startswith('prod') else SANDBOX_BASE
        ).rstrip('/')
        self.consumer_key = getattr(settings, 'MPESA_CONSUMER_KEY', '')
        self.consumer_secret = getattr(settings, 'MPESA_CONSUMER_SECRET', '')
        self.passkey = getattr(settings, 'MPESA_PASSKEY', '')
        self.shortcode = getattr(settings, 'MPESA_SHORTCODE', '174379')
        self.callback_url = getattr(settings, 'MPESA_CALLBACK_URL', '')
        self._token = None
        self._token_expires_at = 0

    @property
    def configured(self):
        return bool(self.consumer_key and self.consumer_secret and self.passkey
                    and self.shortcode and self.callback_url)

    # ── OAuth token ──────────────────────────────────────────────────────
    def get_token(self, force=False):
        now = time.time()
        if not force and self._token and now < self._token_expires_at:
            return self._token
        credentials = base64.b64encode(
            f'{self.consumer_key}:{self.consumer_secret}'.encode('utf-8')
        ).decode('ascii')
        try:
            resp = requests.get(
                f'{self.base_url}/oauth/v1/generate',
                params={'grant_type': 'client_credentials'},
                headers={'Authorization': f'Basic {credentials}'},
                timeout=30,
            )
        except requests.RequestException as e:
            logger.exception('Daraja token network error')
            raise MpesaError(f'Could not reach M-Pesa: {e}')
        data = resp.json() if resp.text else {}
        token = data.get('access_token')
        if resp.status_code >= 400 or not token:
            logger.warning('Daraja token error %s: %s', resp.status_code, data)
            raise MpesaError(
                'M-Pesa login failed. Check the consumer key and secret.')
        self._token = token
        try:
            expires_in = int(data.get('expires_in') or 3599)
        except (TypeError, ValueError):
            expires_in = 3599
        self._token_expires_at = now + expires_in - 60
        return token

    # ── STK Push ─────────────────────────────────────────────────────────
    def stk_push(self, phone, amount, account_reference, description,
                 callback_url=None):
        """Send an STK Push prompt to [phone].

        Returns {'success': True, 'checkout_request_id', 'merchant_request_id',
                 'raw'} or {'success': False, 'error', 'raw'}.
        """
        if not self.configured:
            return {'success': False, 'error': 'M-Pesa is not configured yet',
                    'raw': {}}
        daraja_number = daraja_phone(phone)
        if not daraja_number:
            return {'success': False,
                    'error': 'That phone number cannot receive M-Pesa',
                    'raw': {}}
        whole_amount = stk_amount(amount)
        timestamp = time.strftime('%Y%m%d%H%M%S')
        password = base64.b64encode(
            f'{self.shortcode}{self.passkey}{timestamp}'.encode('utf-8')
        ).decode('ascii')
        payload = {
            'BusinessShortCode': self.shortcode,
            'Password': password,
            'Timestamp': timestamp,
            'TransactionType': 'CustomerPayBillOnline',
            'Amount': whole_amount,
            'PartyA': daraja_number,
            'PartyB': self.shortcode,
            'PhoneNumber': daraja_number,
            'CallBackURL': (callback_url or self.callback_url).strip(),
            # AccountReference is capped at 12 characters by Daraja.
            'AccountReference': (account_reference or 'TapVerify')[:12],
            'TransactionDesc': (description or 'Payment')[:13],
        }
        try:
            resp = requests.post(
                f'{self.base_url}/mpesa/stkpush/v1/processrequest',
                json=payload,
                headers={
                    'Authorization': f'Bearer {self.get_token()}',
                    'Content-Type': 'application/json',
                },
                timeout=30,
            )
            data = resp.json() if resp.text else {}
        except requests.RequestException as e:
            logger.exception('Daraja STK push network error')
            return {'success': False, 'error': f'Could not reach M-Pesa: {e}',
                    'raw': {}}

        if resp.status_code >= 400 or data.get('ResponseCode'):
            message = (
                data.get('errorMessage')
                or data.get('responseDescription')
                or data.get('CustomerMessage')
                or f'M-Pesa rejected the request ({resp.status_code})'
            )
            logger.warning('Daraja STK push error %s: %s', resp.status_code, data)
            return {'success': False, 'error': message, 'raw': data}

        return {
            'success': True,
            'checkout_request_id': data.get('CheckoutRequestID', ''),
            'merchant_request_id': data.get('MerchantRequestID', ''),
            'customer_message': data.get('CustomerMessage')
                                or 'Check your phone for the M-Pesa prompt',
            'raw': data,
        }


def parse_callback(payload):
    """Normalize a Daraja STK callback body.

    Returns {'checkout_request_id', 'merchant_request_id', 'result_code',
             'result_desc', 'success', 'amount', 'receipt', 'phone'}.
    """
    body = payload or {}
    if isinstance(body.get('Body'), dict) and isinstance(body['Body'].get('stkCallback'), dict):
        cb = body['Body']['stkCallback']
    elif isinstance(body.get('stkCallback'), dict):
        cb = body['stkCallback']
    else:
        cb = body

    items = {}
    metadata = cb.get('CallbackMetadata') or {}
    for item in metadata.get('Item') or []:
        if isinstance(item, dict) and 'Name' in item:
            items[item['Name']] = item.get('Value')

    result_code = cb.get('ResultCode')
    try:
        result_code = int(result_code)
    except (TypeError, ValueError):
        result_code = -1

    return {
        'checkout_request_id': str(cb.get('CheckoutRequestID') or ''),
        'merchant_request_id': str(cb.get('MerchantRequestID') or ''),
        'result_code': result_code,
        'result_desc': str(cb.get('ResultDesc') or ''),
        'success': result_code == 0,
        'amount': items.get('Amount'),
        'receipt': str(items.get('MpesaReceiptNumber') or ''),
        'phone': items.get('PhoneNumber') or '',
        'account_reference': str(cb.get('AccountReference') or ''),
    }


# Singleton
_client = None


def get_mpesa_client():
    global _client
    if _client is None:
        _client = MpesaClient()
    return _client
