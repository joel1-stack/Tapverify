from django.contrib import admin
from .models import Workspace, Staff, Member, VerificationEvent, MpesaTransaction, PaymentReminder

@admin.register(Workspace)
class WorkspaceAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'phone', 'plan', 'monthly_amount', 'member_count', 'is_active']
    list_filter = ['type', 'plan', 'is_active']
    search_fields = ['name', 'phone']

    def member_count(self, obj):
        return obj.members.filter(is_active=True).count()
    member_count.short_description = 'Members'

@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ['name', 'phone', 'role', 'workspace', 'is_active']
    list_filter = ['role', 'is_active']
    search_fields = ['name', 'phone']

@admin.register(Member)
class MemberAdmin(admin.ModelAdmin):
    list_display = ['name', 'phone', 'member_code', 'workspace', 'balance_due', 'last_paid_at', 'is_active']
    list_filter = ['is_active', 'workspace']
    search_fields = ['name', 'phone', 'member_code']
    list_editable = ['balance_due']

@admin.register(VerificationEvent)
class VerificationEventAdmin(admin.ModelAdmin):
    list_display = ['member', 'amount', 'event_type', 'verification_method', 'status', 'verifier', 'created_at']
    list_filter = ['event_type', 'verification_method', 'status', 'workspace']
    search_fields = ['member__name', 'receipt_token', 'member__phone']
    date_hierarchy = 'created_at'
    readonly_fields = ['receipt_token', 'receipt_pin', 'created_at']

@admin.register(MpesaTransaction)
class MpesaTransactionAdmin(admin.ModelAdmin):
    list_display = ['mpesa_receipt_number', 'phone_number', 'amount', 'is_matched', 'created_at']
    list_filter = ['is_matched', 'transaction_type']
    search_fields = ['mpesa_receipt_number', 'phone_number']

@admin.register(PaymentReminder)
class PaymentReminderAdmin(admin.ModelAdmin):
    list_display = ['member', 'reminder_type', 'amount_due', 'sms_sent', 'created_at']
    list_filter = ['reminder_type', 'sms_sent']
