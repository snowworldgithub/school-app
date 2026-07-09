from django.db import models
from students.models import Student

class Attendance(models.Model):
    STATUS = [("present","Present"),("absent","Absent"),("late","Late"),("leave","Leave")]
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="attendances")
    date = models.DateField()
    marked_at = models.DateTimeField(auto_now=True)
    status = models.CharField(max_length=10, choices=STATUS, default="present")
    remarks = models.CharField(max_length=200, blank=True)
    marked_by = models.CharField(max_length=100, blank=True)
    class Meta:
        unique_together = ("student","date")
        ordering = ["-date"]
    def __str__(self):
        return f"{self.student} - {self.date} - {self.status}"
