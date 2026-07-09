from django.urls import path
from .views import NextGRNumberView, StudentListView, StudentDetailView

urlpatterns = [
    path('next-gr/', NextGRNumberView.as_view(), name='student-next-gr'),
    path('', StudentListView.as_view(), name='student-list'),
    path('<int:pk>/', StudentDetailView.as_view(), name='student-detail'),
]
