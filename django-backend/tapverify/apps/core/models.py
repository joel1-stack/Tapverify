from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
import uuid
import secrets

class Workspace(models.Model):
    WORKSPACE_TYPES = [
        ('chama', 'Chama / Welfare Group'),
        ('church', 'Church / Religious'),
        ('event', 'Event / Conference'),
        ('delivery', 'Delivery / Logistics'),
    ]
    PLAN_TYPES = [
        ('free', 'Free — 50 members'),
        ('basic', 'Basic — Ksh 1,000/mo — 200 members'),
        ('pro', 'Pro — Ksh 3,000/mo — unlimited'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    type = models.CharField(max_length=20, choices=WORKSPACE_TYPES, default='chama')
    phone = models.CharField(max_length=15, help_text="Admin contact phone")
    till_number = models.CharField(max_length=20, blank=True, null=True)
    paybill_number = models.CharField(max_length=20, blank=True, null=True)
    account_number = models.CharField(max_length=50, blank=True, null=True)
    monthly_amount = models.DecimalField(max_digits=10, decimal_places=2, default=500)
    meeting_location_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    meeting_location_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    meeting_radius_meters = models.IntegerField(default=500)
    plan = models.CharField(max_length=20, choices=PLAN_TYPES, default='free')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'workspaces'

    def __str__(self):
        return f"{self.name} ({self.type})"


class Staff(models.Model):
    ROLE_CHOICES = [
        ('admin', 'Admin'),
        ('treasurer', 'Treasurer'),
        ('verifier', 'Verifier'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, null=True, blank=True)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='staff')
    name = models.CharField(max_length=200)
    phone = models.CharField(max_length=15, unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='treasurer')
    pin_code = models.CharField(max_length=6, default="0000", help_text="App login PIN")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'staff'

    def __str__(self):
        return f"{self.name} — {self.role} @ {self.workspace.name}"


class Member(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='members')
    name = models.CharField(max_length=200)
    phone = models.CharField(max_length=15, db_index=True)
    member_code = models.CharField(max_length=20, unique=True, db_index=True,
                                   default=lambda: f"TV-{secrets.token_hex(4).upper()}")
    id_number = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    monthly_contribution = models.DecimalField(max_digits=10, decimal_places=2, default=500)
    balance_due = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    last_paid_at = models.DateTimeField(null=True, blank=True)
    has_qr_card = models.BooleanField(default=False)
    has_nfc_sticker = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'members'
        unique_together = ['workspace', 'phone']

    def __str__(self):
        return f"{self.name} ({self.member_code})"


class VerificationEvent(models.Model):
    EVENT_TYPES = [
        ('payment_cash', 'Cash Payment Collected'),
        ('payment_mpesa', 'M-Pesa Payment Verified'),
        ('payment_till', 'Till Payment Matched'),
        ('attendance_only', 'Attendance / No Payment'),
        ('penalty', 'Late Payment / Penalty'),
    ]
    VERIFICATION_METHODS = [
        ('manual', 'Manual Selection'),
        ('qr_scan', 'QR Code Scan'),
        ('nfc_tap', 'NFC Sticker Tap'),
        ('mpesa_callback', 'M-Pesa Auto-Match'),
        ('ussd', 'USSD Check-in'),
    ]
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('disputed', 'Disputed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='events')
    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='events')
    verifier = models.ForeignKey(Staff, on_delete=models.SET_NULL, null=True, related_name='verifications')

    event_type = models.CharField(max_length=20, choices=EVENT_TYPES, default='payment_cash')
    amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='approved')
    verification_method = models.CharField(max_length=20, choices=VERIFICATION_METHODS, default='manual')

    gps_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    gps_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    gps_accuracy = models.FloatField(null=True, blank=True)

    receipt_token = models.CharField(max_length=32, unique=True, db_index=True,
                                     default=lambda: secrets.token_urlsafe(16))
    receipt_pin = models.CharField(max_length=4, default=lambda: f"{secrets.randbelow(10000):04d}")
    sms_status = models.CharField(max_length=20, default='pending')
    sms_message_id = models.CharField(max_length=100, blank=True)

    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    verified_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'verification_events'
        indexes = [
            models.Index(fields=['workspace', 'created_at']),
            models.Index(fields=['member', 'created_at']),
            models.Index(fields=['receipt_token']),
            models.Index(fields=['status', 'created_at']),
        ]
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.member.name} — {self.amount} — {self.created_at.strftime('%Y-%m-%d %H:%M')}"


class MpesaTransaction(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='mpesa_transactions')
    member = models.ForeignKey(Member, on_delete=models.SET_NULL, null=True, blank=True, related_name='mpesa_payments')
    event = models.OneToOneField(VerificationEvent, on_delete=models.SET_NULL, null=True, blank=True, related_name='mpesa_txn')

    transaction_type = models.CharField(max_length=20, choices=[
        ('stk_push', 'STK Push'),
        ('till', 'Till Payment'),
        ('paybill', 'Paybill Payment'),
    ])
    mpesa_receipt_number = models.CharField(max_length=50, unique=True, db_index=True)
    phone_number = models.CharField(max_length=15)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    account_reference = models.CharField(max_length=50)
    raw_callback = models.JSONField(default=dict)
    is_matched = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'mpesa_transactions'

    def __str__(self):
        return f"{self.mpesa_receipt_number} — {self.amount}"


class PaymentReminder(models.Model):
    REMINDER_TYPES = [
        ('due_soon', '3 Days Before Due'),
        ('due_today', 'Due Today'),
        ('overdue', 'Overdue'),
        ('meeting_day', 'Meeting Day Reminder'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='reminders')
    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='reminders')
    reminder_type = models.CharField(max_length=20, choices=REMINDER_TYPES)
    amount_due = models.DecimalField(max_digits=10, decimal_places=2)
    message = models.TextField()
    sms_sent = models.BooleanField(default=False)
    sms_sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payment_reminders'

    def __str__(self):
        return f"{self.member.name} — {self.reminder_type}"


class PaymentLink(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending Payment'),
        ('paid', 'Paid'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='payment_links')
    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='payment_links')
    event = models.OneToOneField(VerificationEvent, on_delete=models.SET_NULL, null=True, blank=True, related_name='payment_link')

    token = models.CharField(max_length=32, unique=True, db_index=True,
                             default=lambda: secrets.token_urlsafe(16))
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    description = models.CharField(max_length=200, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    rail_used = models.CharField(max_length=20, default='loop')
    transaction_ref = models.CharField(max_length=100, blank=True)

    expires_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payment_links'
        ordering = ['-created_at']

    def __str__(self):
        return f"Link for {self.member.name} — Ksh {self.amount} ({self.status})"

    @property
    def is_expired(self):
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False


class Collection(models.Model):
    """An obligation raised by a foreman against the whole workforce.

    Mirrors the mobile `WfCollection`: every worker gets a PaymentTask that
    moves through the 9-state lifecycle below.
    """

    COLLECTION_TYPES = [
        ('welfare', 'Welfare'),
        ('medical', 'Medical'),
        ('emergency', 'Emergency'),
        ('trip', 'Trip'),
    ]
    RAIL_CHOICES = [
        ('loop-prompt', 'LOOP M-Pesa Prompt'),
        ('loop-till', 'LOOP Pay to Till'),
        ('loop-paybill', 'LOOP Pay to Paybill'),
        ('sasapay', 'SasaPay Checkout link'),
        ('till', 'M-PESA Till'),
        ('paybill', 'M-PESA Paybill'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    workspace = models.ForeignKey(Workspace, on_delete=models.CASCADE, related_name='collections')
    title = models.CharField(max_length=200)
    type = models.CharField(max_length=20, choices=COLLECTION_TYPES, default='welfare')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    due = models.DateTimeField()
    rail = models.CharField(max_length=20, choices=RAIL_CHOICES, default='loop-prompt')
    message = models.TextField(blank=True)
    sms_sent = models.BooleanField(default=False)
    closed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'collections'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.workspace.name})"

    @property
    def paid_count(self):
        return self.tasks.filter(state__in=['completed', 'verified', 'streak', 'badge', 'reward']).count()


class PaymentTask(models.Model):
    """One worker's task inside a Collection — the 9-state lifecycle.

    CREATED → NOTIFIED → PENDING → COMPLETED → VERIFIED → STREAK → BADGE →
    REWARD → ARCHIVED. `rail` + `txn_ref` are the evidence of how money moved.
    """

    STATE_CHOICES = [
        ('created', 'CREATED'),
        ('notified', 'NOTIFIED'),
        ('pending', 'PENDING'),
        ('completed', 'COMPLETED'),
        ('verified', 'VERIFIED'),
        ('streak', 'STREAK'),
        ('badge', 'BADGE'),
        ('reward', 'REWARD'),
        ('archived', 'ARCHIVED'),
    ]
    LIFECYCLE = ['created', 'notified', 'pending', 'completed',
                 'verified', 'streak', 'badge', 'reward', 'archived']

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    collection = models.ForeignKey(Collection, on_delete=models.CASCADE, related_name='tasks')
    member = models.ForeignKey(Member, on_delete=models.CASCADE, related_name='payment_tasks')
    state = models.CharField(max_length=20, choices=STATE_CHOICES, default='created')
    amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    rail = models.CharField(max_length=20, blank=True, default='')
    txn_ref = models.CharField(max_length=100, blank=True, default='')
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'payment_tasks'
        unique_together = ['collection', 'member']

    def __str__(self):
        return f"{self.member.name} — {self.collection.title} ({self.state})"

    def advance(self, to_state):
        """Move the task through the lifecycle (validating order)."""
        if to_state not in self.LIFECYCLE:
            raise ValueError(f"Unknown state: {to_state}")
        if self.state and self.LIFECYCLE.index(to_state) < self.LIFECYCLE.index(self.state):
            raise ValueError(f"Cannot move back from {self.state} to {to_state}")
        self.state = to_state
        if to_state in ('completed', 'verified', 'streak', 'badge', 'reward') and not self.paid_at:
            self.paid_at = timezone.now()
        self.save(update_fields=['state', 'paid_at'])
        return self
