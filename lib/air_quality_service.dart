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
        'pm2_5': (components['pm2_5'] as num).toDouble(),
        'o3': (components['o3'] as num).toDouble(),
        'pm10': (components['pm10'] as num).toDouble(),
        'no2': (components['no2'] as num).toDouble(),
      };
    } else {
      throw Exception('Failed to fetch air quality');
    }
  }

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'temp': (data['main']['temp'] as num).toDouble(),
        'humidity': (data['main']['humidity'] as num).toInt(),
        'windSpeed': (data['wind']['speed'] as num).toDouble(),
        'description': data['weather'][0]['description'],
        'icon': data['weather'][0]['icon'],
      };
    } else {
      throw Exception('Failed to fetch weather');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNearbyPlaces(double lat, double lon) async {
    final types = ['park', 'stadium', 'gym', 'natural_feature'];
    final List<Map<String, dynamic>> allPlaces = [];
    final Set<String> seenIds = {};

    for (final type in types) {
      final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=$lat,$lon'
          '&radius=5000'
          '&type=$type'
          '&key=${googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        for (final place in results) {
          final id = place['place_id'] as String;
          if (!seenIds.contains(id)) {
            seenIds.add(id);
            allPlaces.add({
              'name': place['name'],
              'lat': place['geometry']['location']['lat'],
              'lon': place['geometry']['location']['lng'],
              'type': type,
            });
          }
        }
      }
    }

    // 按距离排序，最多返回20个
    allPlaces.sort((a, b) {
      final distA = _distance(lat, lon, a['lat'], a['lon']);
      final distB = _distance(lat, lon, b['lat'], b['lon']);
      return distA.compareTo(distB);
    });

    return allPlaces.take(20).toList();
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    return ((lat2 - lat1) * (lat2 - lat1)) + ((lon2 - lon1) * (lon2 - lon1));
  }

  Future<List<Map<String, dynamic>>> fetchHourlyForecast(double lat, double lon) async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m,precipitation_probability,weathercode,windspeed_10m&timezone=auto&forecast_days=2';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final times = data['hourly']['time'] as List;
      final temps = data['hourly']['temperature_2m'] as List;
      final precipProb = data['hourly']['precipitation_probability'] as List;
      final wind = data['hourly']['windspeed_10m'] as List;

      final currentHour = DateTime.now().hour;

      List<Map<String, dynamic>> result = [];
      for (int i = currentHour; i < currentHour + 6 && i < times.length; i++) {
        result.add({
          'time': times[i].toString().substring(11, 16),
          'temp': (temps[i] as num).toDouble(),
          'precipProb': (precipProb[i] as num).toInt(),
          'wind': (wind[i] as num).toDouble(),
          'isNow': i == currentHour,
        });
      }
      return result;
    } else {
      throw Exception('Failed to fetch forecast');
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

  Future<String> fetchLocationName(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isEmpty) return '$lat, $lon';
      final name = data[0]['name'];
      final country = data[0]['country'];
      return '$name, $country';
    }
    return '$lat, $lon';
  }

  Future<Map<String, dynamic>> fetchCoordinates(String city) async {
    final url =
        'https://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isEmpty) throw Exception('Location not found');
      return {
        'lat': data[0]['lat'],
        'lon': data[0]['lon'],
      };
    } else {
      throw Exception('Failed to fetch coordinates');
    }
  }
}