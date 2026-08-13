from rest_framework import serializers
from .models import Workspace, Staff, Member, VerificationEvent, MpesaTransaction, PaymentReminder, PaymentLink

class WorkspaceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Workspace
        fields = ['id', 'name', 'type', 'phone', 'monthly_amount', 'plan', 'is_active']


class StaffSerializer(serializers.ModelSerializer):
    workspace_name = serializers.CharField(source='workspace.name', read_only=True)

    class Meta:
        model = Staff
        fields = ['id', 'name', 'phone', 'role', 'workspace', 'workspace_name', 'is_active']
        extra_kwargs = {'pin_code': {'write_only': True}}


class MemberSerializer(serializers.ModelSerializer):
    workspace_name = serializers.CharField(source='workspace.name', read_only=True)

    class Meta:
        model = Member
        fields = [
            'id', 'name', 'phone', 'member_code', 'workspace', 'workspace_name',
            'monthly_contribution', 'balance_due', 'last_paid_at',
            'has_qr_card', 'has_nfc_sticker', 'is_active'
        ]


class MemberListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Member
        fields = ['id', 'name', 'phone', 'member_code', 'balance_due']


class VerificationEventSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='member.name', read_only=True)
    member_phone = serializers.CharField(source='member.phone', read_only=True)
    verifier_name = serializers.CharField(source='verifier.name', read_only=True)
    workspace_name = serializers.CharField(source='workspace.name', read_only=True)

    class Meta:
        model = VerificationEvent
        fields = [
            'id', 'workspace', 'workspace_name', 'member', 'member_name', 'member_phone',
            'verifier', 'verifier_name', 'event_type', 'amount', 'status',
            'verification_method', 'gps_lat', 'gps_lng', 'receipt_token', 'receipt_pin',
            'sms_status', 'notes', 'created_at'
        ]


class VerifyRequestSerializer(serializers.Serializer):
    workspace_id = serializers.UUIDField()
    member_id = serializers.UUIDField(required=False)
    member_code = serializers.CharField(required=False, max_length=20)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    event_type = serializers.ChoiceField(choices=VerificationEvent.EVENT_TYPES, default='payment_cash')
    verification_method = serializers.ChoiceField(choices=VerificationEvent.VERIFICATION_METHODS, default='manual')
    gps_lat = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    gps_lng = serializers.DecimalField(max_digits=9, decimal_places=6, required=False, allow_null=True)
    notes = serializers.CharField(required=False, allow_blank=True)
    payment_link_token = serializers.CharField(required=False, allow_blank=True, max_length=64)


class ReceiptSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='member.name', read_only=True)
    workspace_name = serializers.CharField(source='workspace.name', read_only=True)
    verifier_name = serializers.CharField(source='verifier.name', read_only=True)

    class Meta:
        model = VerificationEvent
        fields = [
            'id', 'member_name', 'workspace_name', 'amount', 'event_type',
            'verification_method', 'gps_lat', 'gps_lng', 'verifier_name',
            'receipt_token', 'created_at'
        ]


class MpesaTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = MpesaTransaction
        fields = '__all__'


class PaymentReminderSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='member.name', read_only=True)
    member_phone = serializers.CharField(source='member.phone', read_only=True)

    class Meta:
        model = PaymentReminder
        fields = ['id', 'member_name', 'member_phone', 'reminder_type', 'amount_due', 'sms_sent', 'created_at']


class PaymentLinkSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='member.name', read_only=True)
    workspace_name = serializers.CharField(source='workspace.name', read_only=True)

    class Meta:
        model = PaymentLink
        fields = ['id', 'workspace', 'workspace_name', 'member', 'member_name', 'token',
                  'amount', 'description', 'status', 'rail_used', 'expires_at', 'paid_at', 'created_at']
