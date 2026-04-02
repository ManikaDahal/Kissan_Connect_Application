from django.urls import path
from .views import WeatherView

urlpatterns = [
    path('current/', WeatherView.as_view(), name='current_weather'),
]
