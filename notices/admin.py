from django.contrib import admin
from .models import Notice

@admin.register(Notice)
class NoticeAdmin(admin.ModelAdmin):
    list_display = ["title","audience","is_active","created_at"]
    list_filter = ["audience","is_active"]
    search_fields = ["title"]
