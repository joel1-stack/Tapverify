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
    return SasaPayRail()
