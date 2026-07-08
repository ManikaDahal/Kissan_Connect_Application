from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from .services import WeatherService

class WeatherView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        lat = request.query_params.get('lat')
        lon = request.query_params.get('lon')
        
        # If parameters provided, try to convert to float
        try:
            if lat and lon:
                lat = float(lat)
                lon = float(lon)
        except ValueError:
            return Response({'error': 'Invalid latitude or longitude format'}, status=status.HTTP_400_BAD_REQUEST)
            
        weather_data = WeatherService.get_weather_data(lat, lon)
        
        if weather_data:
            return Response(weather_data)
        return Response({'error': 'Could not fetch weather data'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
