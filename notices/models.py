from django.db import models

class Notice(models.Model):
    AUDIENCE = [("all","Sab ke liye"),("student","Students"),("teacher","Teachers"),("parent","Parents")]
    title = models.CharField(max_length=200)
    content = models.TextField()
    audience = models.CharField(max_length=10, choices=AUDIENCE, default="all")
    is_active = models.BooleanField(default=True)
    created_by = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    class Meta:
        ordering = ["-created_at"]
    def __str__(self):
        return self.title
