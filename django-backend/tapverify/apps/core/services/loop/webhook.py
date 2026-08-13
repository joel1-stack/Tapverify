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

    Real IPN payloads mirror the process-request success body:
      data.serviceTransactionStatus, data.response, responseDetails fields.
    """
    client = LoopClient()

    signature = headers.get('X-Loop-Signature', '') or headers.get('x-loop-signature', '')
    if getattr(settings, 'LOOP_IPN_SECRET', ''):
        raw_body = headers.get('raw_body', '')
        if raw_body and not client.verify_signature(raw_body, signature):
            logger.warning("Loop IPN signature mismatch")
            return None
    elif signature:
        logger.warning("IPN secret not configured; accepting Loop callback unsigned")

    inner = payload.get('data') or {}
    response = inner.get('response') or {}
    details = response.get('responseDetails') or {}

    status = str(
        inner.get('serviceTransactionStatus')
        or payload.get('status')
        or payload.get('result')
        or ''
    ).upper()
    status = status.replace(' ', '_')

    success_statuses = ('COMPLETED', 'SUCCESS', 'PAID', 'APPROVED', 'SUCCESSFUL')
    failed_statuses = ('FAILED', 'DECLINED', 'CANCELLED', 'TIMEOUT', 'REVERSED')

    return {
        'valid': bool(details.get('transferRefNo') or payload.get('reference')),
        'reference': payload.get('reference') or inner.get('txnReference')
                     or response.get('transactionRef') or details.get('transactionRef'),
        'status': 'success' if status in success_statuses else (
            'failed' if status in failed_statuses else status.lower()
        ),
        'transfer_status': details.get('transferStatus'),
        'amount': payload.get('amount') or inner.get('amount'),
        'receipt_number': details.get('transferRefNo')
                          or response.get('transactionRef')
                          or payload.get('receipt_number'),
        'transfer_order_id': details.get('transferOrderId') or response.get('transferOrderId'),
        'phone': payload.get('phone') or payload.get('phone_number') or payload.get('msisdn'),
        'raw': payload,
    }
