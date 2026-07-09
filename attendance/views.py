from rest_framework import generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Attendance
from .serializers import AttendanceSerializer, QRMarkAttendanceSerializer


class AttendanceListView(generics.ListCreateAPIView):
    queryset = Attendance.objects.select_related(
        "student",
        "student__user",
        "student__student_class",
    )
    serializer_class = AttendanceSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        queryset = super().get_queryset()
        date = self.request.query_params.get("date")
        student = self.request.query_params.get("student")
        if date:
            queryset = queryset.filter(date=date)
        if student:
            queryset = queryset.filter(student_id=student)
        return queryset


class QRMarkAttendanceView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = QRMarkAttendanceSerializer(data=request.data)
        if serializer.is_valid():
            attendance = serializer.save()
            return Response(
                AttendanceSerializer(attendance).data,
                status=status.HTTP_200_OK,
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
