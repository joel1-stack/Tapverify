from django.contrib import admin

from .models import Collection, LoginOTP, Member, Payment, Secretary


class MemberInline(admin.TabularInline):
    model = Member
    extra = 0


@admin.register(Secretary)
class SecretaryAdmin(admin.ModelAdmin):
    list_display = ('phone', 'created_at')
    search_fields = ('phone',)


@admin.register(Collection)
class CollectionAdmin(admin.ModelAdmin):
    list_display = ('title', 'secretary', 'amount', 'payout_method', 'created_at')
    list_filter = ('payout_method',)
    search_fields = ('title', 'secretary__phone')
    inlines = [MemberInline]


@admin.register(Member)
class MemberAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'collection', 'status', 'paid_amount',
                    'paid_method', 'paid_at')
    list_filter = ('status', 'paid_method')
    search_fields = ('name', 'phone')


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ('transaction_code', 'amount', 'phone', 'status',
                    'member', 'created_at')
    list_filter = ('status',)


@admin.register(LoginOTP)
class LoginOTPAdmin(admin.ModelAdmin):
    list_display = ('phone', 'code', 'used', 'expires_at', 'created_at')
