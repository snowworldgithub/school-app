from django.contrib import admin
from django.http import JsonResponse
from django.urls import path, include


def api_home(request):
    return JsonResponse({
        "message": "Ahmed School Django API is running.",
        "endpoints": {
            "admin": "/admin/",
            "auth": "/api/auth/",
            "students": "/api/students/",
            "attendance": "/api/attendance/",
            "qr_attendance": "/api/attendance/qr/mark/",
            "fees": "/api/fees/",
            "notices": "/api/notices/",
        },
    })


urlpatterns = [
    path('', api_home),
    path('admin/', admin.site.urls),
    path('api/auth/',       include('accounts.urls')),
    path('api/students/',   include('students.urls')),
    path('api/attendance/', include('attendance.urls')),
    path('api/fees/',       include('fees.urls')),
    path('api/notices/',    include('notices.urls')),
]
