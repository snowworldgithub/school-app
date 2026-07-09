from django.contrib import admin
from .models import Attendance

@admin.register(Attendance)
class AttendanceAdmin(admin.ModelAdmin):
    list_display = ["student","date","marked_at","status","marked_by"]
    list_filter = ["status","date"]
    search_fields = ["student__user__first_name","student__user__last_name"]
    date_hierarchy = "date"
