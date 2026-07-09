from django.urls import path
from django.http import JsonResponse
def coming_soon(request):
    return JsonResponse({"message": "coming soon"})
urlpatterns = [path("", coming_soon)]
