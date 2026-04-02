import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/theme/app_theme.dart';

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Position? position;
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition();
        }
      } catch (e) {
        print("Location error, defaulting to Kathmandu: $e");
      }

      final params = position != null 
          ? {'lat': position.latitude.toString(), 'lon': position.longitude.toString()}
          : null; // Backend defaults to Kathmandu if null

      final data = await ApiService.get('weather/current/', params: params);
      
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not fetch weather";
          _isLoading = false;
        });
      }
    }
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return AppTheme.primaryGreen;
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _weatherData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(_error ?? "Unknown error", style: const TextStyle(color: Colors.red))),
            IconButton(onPressed: _fetchWeather, icon: const Icon(Icons.refresh, color: Colors.red)),
          ],
        ),
      );
    }

    final color = _parseColor(_weatherData!['color_code']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weatherData!['city'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "${_weatherData!['temperature']}°C • ${_weatherData!['description']}",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                ],
              ),
              Image.network(
                "https://openweathermap.org/img/wn/${_weatherData!['icon']}@2x.png",
                height: 50,
                width: 50,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.nature_people, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _weatherData!['advice'],
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
