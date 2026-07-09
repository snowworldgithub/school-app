from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ["username","first_name","last_name","email","role"]
    list_filter = ["role"]
    fieldsets = BaseUserAdmin.fieldsets + (("School Info", {"fields": ("role","phone")}),)
    add_fieldsets = BaseUserAdmin.add_fieldsets + (("School Info", {"fields": ("role","phone")}),)
