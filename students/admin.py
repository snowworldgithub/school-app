from django.contrib import admin
from .models import Student, Class

@admin.register(Class)
class ClassAdmin(admin.ModelAdmin):
    list_display = ["name", "section"]

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ["gr_number", "roll_number", "full_name", "student_class", "status"]
    search_fields = ["gr_number", "roll_number", "user__first_name", "user__last_name"]
    list_filter = ["status", "student_class"]
