from rest_framework import serializers

from students.models import Student
from .models import Attendance


class AttendanceSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source="student.full_name", read_only=True)
    roll_number = serializers.CharField(source="student.roll_number", read_only=True)
    gr_number = serializers.CharField(source="student.gr_number", read_only=True)
    class_name = serializers.SerializerMethodField()

    class Meta:
        model = Attendance
        fields = [
            "id",
            "student",
            "student_name",
            "roll_number",
            "gr_number",
            "class_name",
            "date",
            "marked_at",
            "status",
            "remarks",
            "marked_by",
        ]
        read_only_fields = ["id", "marked_at"]

    def get_class_name(self, obj):
        if not obj.student.student_class:
            return ""
        return str(obj.student.student_class)


class QRMarkAttendanceSerializer(serializers.Serializer):
    qr_data = serializers.CharField()
    status = serializers.ChoiceField(choices=Attendance.STATUS, default="present")
    remarks = serializers.CharField(required=False, allow_blank=True, max_length=200)
    marked_by = serializers.CharField(required=False, allow_blank=True, max_length=100)
    date = serializers.DateField(required=False)

    def validate_qr_data(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("QR data required.")
        if value.startswith("AES-STUDENT:"):
            value = value.split(":", 1)[1].strip()
        if not value:
            raise serializers.ValidationError("Invalid student QR.")
        return value

    def validate(self, attrs):
        token = attrs["qr_data"]
        student = self._find_student(token)
        if not student:
            raise serializers.ValidationError({
                "qr_data": "Student QR record nahi mila."
            })
        attrs["student"] = student
        return attrs

    def create(self, validated_data):
        from django.utils import timezone

        student = validated_data["student"]
        attendance_date = validated_data.get("date") or timezone.localdate()
        attendance, _ = Attendance.objects.update_or_create(
            student=student,
            date=attendance_date,
            defaults={
                "status": validated_data.get("status", "present"),
                "remarks": validated_data.get("remarks", ""),
                "marked_by": validated_data.get("marked_by", "Flutter QR"),
            },
        )
        return attendance

    def _find_student(self, token):
        lookups = [
            {"gr_number": token},
            {"roll_number": token},
        ]
        if token.isdigit():
            lookups.append({"pk": int(token)})

        for lookup in lookups:
            student = Student.objects.filter(**lookup).first()
            if student:
                return student
        return None
