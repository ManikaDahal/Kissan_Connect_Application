import requests
import os
from django.conf import settings

class WeatherService:
    @staticmethod
    def get_weather_data(lat=None, lon=None):
        # Default to Kathmandu if coordinates are missing
        if lat is None or lon is None:
            lat, lon = 27.7172, 85.3240
            
        # Get the API key, prioritising the environment variable
        api_key = os.environ.get('OPENWEATHER_API_KEY', 'dd32260d07aba141704576a8e9813ee9')
        url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric"
        
        try:
            response = requests.get(url, timeout=10)
            if response.status_code == 200:
                data = response.json()
                condition = data['weather'][0]['main']
                description = data['weather'][0]['description'].lower()
                temp = data['main']['temp']
                
                return {
                    'city': data.get('name', 'Kathmandu'),
                    'temperature': round(temp, 1),
                    'condition': condition,
                    'description': data['weather'][0]['description'],
                    'icon': data['weather'][0]['icon'],
                    'advice': WeatherService.get_farming_advice(condition, description),
                    'color_code': WeatherService.get_weather_color(condition, description)
                }
            print(f"Weather API Error {response.status_code}: {response.text}")
            return None
        except Exception as e:
            print(f"Weather API Exception: {e}")
            return None

    @staticmethod
    def get_farming_advice(condition, description):
        # Specific description-based advice for clouds
        if condition == 'Clouds':
            if 'overcast' in description:
                return "Fully overcast. Great for fertilizing as moisture stays in soil longer."
            if 'scattered' in description or 'few' in description:
                return "Partly cloudy! Good for weeding and general maintenance."
            if 'broken' in description:
                return "Mostly cloudy. Good for transplanting young seedlings."
            return "Cloudy skies. Ideal for outdoor farming without harsh sun exposure."
            
        advice_map = {
            'Rain': "It's raining! Soil is moist, great for planting seeds or transplanting.",
            'Drizzle': "Light rain. Good for transplanting without washing away soil.",
            'Thunderstorm': "Heavy storms! Check drainage systems and protect young plants.",
            'Clear': "Sunny day! Ideal for harvesting, weeding, or sun-drying crops.",
            'Snow': "Cold weather. Shield sensitive crops and check livestock warmth.",
            'Mist': "High humidity. Watch out for fungal diseases in crops.",
            'Fog': "High humidity. Watch out for fungal diseases in crops.",
            'Haze': "Reduced visibility. Good for indoor agricultural planning.",
        }
        return advice_map.get(condition, "Standard conditions. Keep up with your regular maintenance.")

    @staticmethod
    def get_weather_color(condition, description=''):
        # Return a hex color code or a keyword for the frontend to use
        if condition == 'Clouds':
            if 'overcast' in description:
                return '#757575' # Darker grey
            return '#9B9B9B' # Standard grey

        color_map = {
            'Rain': '#4A90E2', # Blue
            'Drizzle': '#7DB1FF', # Light Blue
            'Thunderstorm': '#4A4A4A', # Dark Grey
            'Clear': '#F5A623', # Warm Orange/Yellow
            'Mist': '#C0C0C0', # Silver
            'Haze': '#E0E0E0', # Lighter Grey
        }
        return color_map.get(condition, '#2E7D32') # Default Kissan Green
