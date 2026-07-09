from django.urls import path

from .views import AttendanceListView, QRMarkAttendanceView

urlpatterns = [
    path("", AttendanceListView.as_view(), name="attendance-list"),
    path("qr/mark/", QRMarkAttendanceView.as_view(), name="attendance-qr-mark"),
]
