import 'secrets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AirQualityService {
  final String apiKey = openWeatherApiKey;

  Future<Map<String, dynamic>> fetchAirQuality(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final aqi = data['list'][0]['main']['aqi'];
      final components = data['list'][0]['components'];
      return {
        'aqi': aqi,
        'pm2_5': components['pm2_5'],
        'pm10': components['pm10'],
      };
    } else {
      throw Exception('Failed to fetch air quality');
    }
  }

  String getAqiLabel(int aqi) {
    switch (aqi) {
      case 1: return 'Good';
      case 2: return 'Fair';
      case 3: return 'Moderate';
      case 4: return 'Poor';
      case 5: return 'Very Poor';
      default: return 'Unknown';
    }
  }

  String getAqiAdvice(int aqi) {
    switch (aqi) {
      case 1: return 'Perfect for running! Go enjoy your run 🏃';
      case 2: return 'Good conditions for running 👍';
      case 3: return 'Moderate air quality, short runs are fine';
      case 4: return 'Poor air quality, consider indoor exercise';
      case 5: return 'Very poor air quality, avoid outdoor running ❌';
      default: return 'Unable to determine conditions';
    }
  }
}