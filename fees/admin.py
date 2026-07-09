from django.contrib import admin
from .models import FeeRecord

@admin.register(FeeRecord)
class FeeAdmin(admin.ModelAdmin):
    list_display = ["student","month","year","amount","paid_amount","status"]
    list_filter = ["status","month","year"]
    search_fields = ["student__user__first_name","student__user__last_name"]
