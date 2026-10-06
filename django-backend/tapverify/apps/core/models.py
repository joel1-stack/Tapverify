"""
TapVerify V1 models.

One user type: the Secretary (the person collecting money).
A Collection has Members (people who should pay) and Payments
(incoming money notifications, matched or unmatched).
"""
import secrets

from django.db import models
from django.utils import timezone


def new_pay_code():
    return secrets.token_urlsafe(6).replace('-', '').replace('_', '')[:8]


def new_token():
    return secrets.token_hex(32)


class Secretary(models.Model):
    """The person who collects money. Identified by phone number only."""

    phone = models.CharField(max_length=20, unique=True)
    auth_token = models.CharField(max_length=64, unique=True, null=True, blank=True)
    name = models.CharField(max_length=120, blank=True)
    group_name = models.CharField(max_length=120, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name or self.phone


class LoginOTP(models.Model):
    """One-time login code sent by SMS. Valid for 10 minutes, single use."""

    phone = models.CharField(max_length=20, db_index=True)
    code = models.CharField(max_length=6)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def is_valid(self):
        return not self.used and timezone.now() < self.expires_at


class Collection(models.Model):
    """A money collection, e.g. 'September Welfare - KES 500 per person'."""

    TILL = 'till'
    PAYBILL = 'paybill'
    PERSONAL = 'personal'
    BANK = 'bank'
    PAYOUT_METHODS = [
        (TILL, 'Till Number'),
        (PAYBILL, 'Paybill'),
        (PERSONAL, 'Personal Number'),
        (BANK, 'Bank Account'),
    ]
    AUTO_DETECT_METHODS = (TILL, PAYBILL)

    secretary = models.ForeignKey(
        Secretary, on_delete=models.CASCADE, related_name='collections')
    title = models.CharField(max_length=120)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    due_date = models.DateField(null=True, blank=True)
    payout_method = models.CharField(max_length=10, choices=PAYOUT_METHODS)
    till_number = models.CharField(max_length=20, blank=True)
    paybill_number = models.CharField(max_length=20, blank=True)
    paybill_account = models.CharField(max_length=60, blank=True)
    personal_phone = models.CharField(max_length=20, blank=True)
    bank_details = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.title} ({self.secretary.phone})'

    @property
    def auto_detect(self):
        return self.payout_method in self.AUTO_DETECT_METHODS

    def stats(self):
        members = self.members.all()
        paid = [m for m in members if m.status == Member.PAID]
        collected = sum(m.paid_amount or 0 for m in paid)
        expected = self.amount * len(members)
        return {
            'member_count': len(members),
            'paid_count': len(paid),
            'collected': collected,
            'outstanding': expected - collected,
        }


class Member(models.Model):
    """A person expected to pay into a Collection."""

    UNPAID = 'unpaid'
    PAID = 'paid'
    STATUSES = [(UNPAID, 'Not paid'), (PAID, 'Paid')]

    collection = models.ForeignKey(
        Collection, on_delete=models.CASCADE, related_name='members')
    name = models.CharField(max_length=120, blank=True)
    phone = models.CharField(max_length=20)
    pay_code = models.CharField(max_length=12, unique=True, default=new_pay_code)

    status = models.CharField(max_length=10, choices=STATUSES, default=UNPAID)
    paid_at = models.DateTimeField(null=True, blank=True)
    paid_method = models.CharField(max_length=10, blank=True)  # auto | cash | other
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    amount_mismatch = models.BooleanField(default=False)
    transaction_ref = models.CharField(max_length=60, blank=True)
    reminders_sent = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name', 'phone']
        unique_together = [('collection', 'phone')]

    def __str__(self):
        return self.name or self.phone

    def mark_paid(self, method, amount, transaction_ref=''):
        self.status = self.PAID
        self.paid_at = timezone.now()
        self.paid_method = method
        self.paid_amount = amount
        self.transaction_ref = transaction_ref
        self.amount_mismatch = amount != self.collection.amount
        self.save(update_fields=[
            'status', 'paid_at', 'paid_method', 'paid_amount',
            'transaction_ref', 'amount_mismatch',
        ])


class Payment(models.Model):
    """An incoming payment notification (webhook). Matched to a member when possible."""

    MATCHED = 'matched'
    UNMATCHED = 'unmatched'
    STATUSES = [(MATCHED, 'Matched'), (UNMATCHED, 'Unmatched')]

    member = models.ForeignKey(
        Member, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='payments')
    collection = models.ForeignKey(
        Collection, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='payments')
    phone = models.CharField(max_length=20, blank=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    reference = models.CharField(max_length=60, blank=True, db_index=True)
    transaction_code = models.CharField(max_length=60, blank=True)
    status = models.CharField(max_length=10, choices=STATUSES, default=UNMATCHED)
    raw = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.transaction_code or self.reference} - {self.amount}'
