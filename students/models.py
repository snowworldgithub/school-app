from django.db import models
from accounts.models import User


def get_next_gr_number():
    highest = 0
    for gr_number in Student.objects.exclude(gr_number__isnull=True).values_list(
        "gr_number", flat=True
    ):
        if not gr_number:
            continue
        digits = "".join(ch for ch in gr_number if ch.isdigit())
        if digits:
            highest = max(highest, int(digits))

    return f"GR{highest + 1:04d}"


def get_next_roll_number():
    highest = 0
    for roll_number in Student.objects.exclude(roll_number__isnull=True).values_list(
        "roll_number", flat=True
    ):
        if not roll_number:
            continue
        digits = "".join(ch for ch in roll_number if ch.isdigit())
        if digits:
            highest = max(highest, int(digits))

    return f"{highest + 1:03d}"


class Class(models.Model):
    name = models.CharField(max_length=20)
    section = models.CharField(max_length=5, blank=True)
    def __str__(self):
        return f"{self.name} {self.section}".strip()

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="student_profile")
    roll_number = models.CharField(max_length=20, unique=True)
    gr_number = models.CharField(max_length=20, unique=True, blank=True, null=True)
    student_class = models.ForeignKey(Class, on_delete=models.SET_NULL, null=True, related_name="students")
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, blank=True)
    address = models.TextField(blank=True)
    status = models.CharField(max_length=10, default="active")
    admission_date = models.DateField(auto_now_add=True)
    prev_school = models.CharField(max_length=100, blank=True)

    father_name = models.CharField(max_length=100, blank=True)
    father_phone = models.CharField(max_length=15, blank=True)
    father_nic = models.CharField(max_length=20, blank=True)
    mother_name = models.CharField(max_length=100, blank=True)
    mother_phone = models.CharField(max_length=15, blank=True)
    mother_nic = models.CharField(max_length=20, blank=True)

    whatsapp = models.CharField(max_length=15, blank=True)

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.roll_number})"

    def save(self, *args, **kwargs):
        if not self.roll_number:
            self.roll_number = get_next_roll_number()
        if not self.gr_number:
            self.gr_number = get_next_gr_number()
        super().save(*args, **kwargs)

    @property
    def full_name(self):
        return self.user.get_full_name()
