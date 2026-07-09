from django.db import models
from students.models import Student

class FeeRecord(models.Model):
    STATUS = [("paid","Paid"),("unpaid","Unpaid"),("partial","Partial")]
    MONTHS = [("1","January"),("2","February"),("3","March"),("4","April"),("5","May"),("6","June"),("7","July"),("8","August"),("9","September"),("10","October"),("11","November"),("12","December")]
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="fees")
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    paid_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    month = models.CharField(max_length=2, choices=MONTHS)
    year = models.PositiveIntegerField(default=2025)
    status = models.CharField(max_length=10, choices=STATUS, default="unpaid")
    due_date = models.DateField()
    paid_date = models.DateField(null=True, blank=True)
    remarks = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        ordering = ["-year","-month"]
    def __str__(self):
        return f"{self.student} - {self.month}/{self.year} - {self.status}"
    def save(self, *args, **kwargs):
        if self.paid_amount >= self.amount:
            self.status = "paid"
        elif self.paid_amount > 0:
            self.status = "partial"
        else:
            self.status = "unpaid"
        super().save(*args, **kwargs)
