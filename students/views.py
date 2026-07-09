from rest_framework import generics
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Student, Class
from .models import get_next_gr_number, get_next_roll_number
from .serializers import StudentSerializer, ClassSerializer

class StudentListView(generics.ListCreateAPIView):
    queryset = Student.objects.all()
    serializer_class = StudentSerializer
    permission_classes = [AllowAny]

class StudentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Student.objects.all()
    serializer_class = StudentSerializer
    permission_classes = [AllowAny]


class NextGRNumberView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            "gr_number": get_next_gr_number(),
            "roll_number": get_next_roll_number(),
        })
