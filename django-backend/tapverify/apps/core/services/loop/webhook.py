"""
Loop IPN webhook helpers.

Views.py calls LoopRail.verify_webhook() which delegates here. Fill in the
exact payload field names and signature format from the briefing.
"""
import logging

from django.conf import settings

from .client import LoopClient

logger = logging.getLogger(__name__)


def parse_ipn(payload, headers):
    """
    Normalize a Loop IPN callback into a dict the app can act on.

    Returns None if the payload is invalid / untrusted.
    """
    client = LoopClient()

    signature = headers.get(client.SIGNATURE_HEADER, '')
    if getattr(settings, 'LOOP_IPN_SECRET', ''):
        raw_body = headers.get('raw_body', '')
        if raw_body and not client.verify_signature(raw_body, signature):
            logger.warning("Loop IPN signature mismatch")
            return None
    elif signature:
        logger.warning("IPN secret not configured; accepting Loop callback unsigned")

    status = str(payload.get('status', '') or payload.get('result', '')).upper()
    status = status.replace(' ', '_')

    success_statuses = ('SUCCESS', 'COMPLETED', 'PAID', 'APPROVED', 'SUCCESSFUL')
    failed_statuses = ('FAILED', 'DECLINED', 'CANCELLED', 'TIMEOUT', 'REVERSED')

    return {
        'valid': bool(payload.get('reference')),
        'reference': payload.get('reference'),
        'status': 'success' if status in success_statuses else (
            'failed' if status in failed_statuses else status.lower()
        ),
        'amount': payload.get('amount') or payload.get('amount_value'),
        'receipt_number': payload.get('receipt_number') or payload.get('mpesa_receipt') or payload.get('trans_id'),
        'phone': payload.get('phone') or payload.get('phone_number') or payload.get('msisdn'),
        'raw': payload,
    }
