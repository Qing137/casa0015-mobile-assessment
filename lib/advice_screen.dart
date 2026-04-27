import 'package:flutter/material.dart';

class AdviceScreen extends StatelessWidget {
  final int aqi;
  final double temp;
  final int humidity;
  final double windSpeed;
  final double pm25;
  final double o3;
  final String locationName;

  const AdviceScreen({
    super.key,
    required this.aqi,
    required this.temp,
    required this.humidity,
    required this.windSpeed,
    required this.pm25,
    required this.o3,
    required this.locationName,
  });

  List<Map<String, dynamic>> _getTips() {
    List<Map<String, dynamic>> tips = [];

    if (aqi == 1) {
      tips.add({
        'icon': Icons.check_circle,
        'color': const Color(0xFF1E90FF),
        'title': 'Air Quality: Excellent',
        'detail': 'Air quality is ideal for outdoor running. No restrictions needed — enjoy your full workout.',
      });
    } else if (aqi == 2) {
      tips.add({
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF00C49A),
        'title': 'Air Quality: Good',
        'detail': 'Air quality is acceptable. Most runners can exercise outdoors without any concerns.',
      });
    } else if (aqi == 3) {
      tips.add({
        'icon': Icons.warning_amber,
        'color': const Color(0xFFFFB347),
        'title': 'Air Quality: Moderate',
        'detail': 'Sensitive individuals (asthma, heart conditions) should limit runs to under 45 minutes. Healthy runners can continue with normal activity.',
      });
    } else if (aqi == 4) {
      tips.add({
        'icon': Icons.dangerous_outlined,
        'color': const Color(0xFFFF6B6B),
        'title': 'Air Quality: Poor',
        'detail': 'Avoid prolonged outdoor exercise. If you must run, keep it short (under 20 min) and avoid busy roads. Consider wearing a mask.',
      });
    } else {
      tips.add({
        'icon': Icons.cancel,
        'color': const Color(0xFF9B59B6),
        'title': 'Air Quality: Very Poor',
        'detail': 'Not recommended to run outdoors today. Switch to indoor exercise or rest. Air pollution is at a harmful level.',
      });
    }

    if (temp < 0) {
      tips.add({
        'icon': Icons.ac_unit,
        'color': Colors.blue,
        'title': 'Freezing (${temp.toStringAsFixed(1)}°C)',
        'detail': 'Extremely cold. Wear thermal base layers, insulated jacket, gloves and a hat. Cover your face to protect lungs from cold air. Warm up indoors before heading out.',
      });
    } else if (temp < 5) {
      tips.add({
        'icon': Icons.ac_unit,
        'color': Colors.lightBlue,
        'title': 'Very Cold (${temp.toStringAsFixed(1)}°C)',
        'detail': 'Dress in thermal layers with gloves and a hat. Muscles take longer to warm up in cold — extend your warm-up to at least 10 minutes.',
      });
    } else if (temp < 10) {
      tips.add({
        'icon': Icons.thermostat,
        'color': Colors.lightBlue,
        'title': 'Cool (${temp.toStringAsFixed(1)}°C)',
        'detail': 'Wear a light jacket or long sleeves. Good running conditions — cool air helps keep body temperature down during longer runs.',
      });
    } else if (temp <= 20) {
      tips.add({
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFF00C49A),
        'title': 'Ideal Temperature (${temp.toStringAsFixed(1)}°C)',
        'detail': 'Perfect running weather! Light clothing is fine. This range is optimal for performance and endurance.',
      });
    } else if (temp <= 25) {
      tips.add({
        'icon': Icons.wb_sunny,
        'color': const Color(0xFFFFB347),
        'title': 'Warm (${temp.toStringAsFixed(1)}°C)',
        'detail': 'Wear light breathable clothing. Bring water and stay hydrated. Consider running in shaded areas and slow your pace slightly.',
      });
    } else if (temp <= 30) {
      tips.add({
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
        'title': 'Hot (${temp.toStringAsFixed(1)}°C)',
        'detail': 'High heat risk. Run early morning (before 8am) or after sunset. Drink water before, during and after. Wear moisture-wicking light clothes and reduce intensity.',
      });
    } else {
      tips.add({
        'icon': Icons.local_fire_department,
        'color': Colors.red,
        'title': 'Extreme Heat (${temp.toStringAsFixed(1)}°C)',
        'detail': 'Dangerous conditions. High risk of heat exhaustion. Postpone your run to early morning or evening, or switch to indoor exercise today.',
      });
    }

    if (windSpeed < 3) {
      tips.add({
        'icon': Icons.air,
        'color': const Color(0xFF00C49A),
        'title': 'Calm Wind (${windSpeed.toStringAsFixed(1)} m/s)',
        'detail': 'Minimal wind resistance. Great conditions for a tempo run or personal best attempt.',
      });
    } else if (windSpeed < 8) {
      tips.add({
        'icon': Icons.air,
        'color': const Color(0xFF1E90FF),
        'title': 'Light Wind (${windSpeed.toStringAsFixed(1)} m/s)',
        'detail': 'Light breeze — comfortable running conditions. Wind will help cool you down on warmer days.',
      });
    } else if (windSpeed < 12) {
      tips.add({
        'icon': Icons.air,
        'color': const Color(0xFFFFB347),
        'title': 'Moderate Wind (${windSpeed.toStringAsFixed(1)} m/s)',
        'detail': 'Noticeable resistance. Plan a loop route — run into the wind first when fresh and with the wind on your return. Expect a slightly slower pace.',
      });
    } else {
      tips.add({
        'icon': Icons.storm,
        'color': const Color(0xFFFF6B6B),
        'title': 'Strong Wind (${windSpeed.toStringAsFixed(1)} m/s)',
        'detail': 'Strong winds will significantly affect your pace. Stay away from open exposed areas and seek sheltered routes through parks or between buildings.',
      });
    }

    if (humidity > 85) {
      tips.add({
        'icon': Icons.water_drop,
        'color': const Color(0xFFFF6B6B),
        'title': 'High Humidity ($humidity%)',
        'detail': 'High humidity reduces your body\'s ability to cool itself. Slow your pace by 10-20%, take walk breaks and drink more water than usual.',
      });
    } else if (humidity > 70) {
      tips.add({
        'icon': Icons.water_drop,
        'color': const Color(0xFFFFB347),
        'title': 'Moderate Humidity ($humidity%)',
        'detail': 'Slightly humid. Wear moisture-wicking fabrics and stay well hydrated throughout your run.',
      });
    } else if (humidity < 30) {
      tips.add({
        'icon': Icons.water_drop,
        'color': Colors.orange,
        'title': 'Low Humidity ($humidity%)',
        'detail': 'Dry air can cause dehydration faster than you realise. Drink water before heading out and carry a bottle.',
      });
    } else {
      tips.add({
        'icon': Icons.water_drop,
        'color': const Color(0xFF00C49A),
        'title': 'Comfortable Humidity ($humidity%)',
        'detail': 'Humidity is at a comfortable level. Normal hydration routine is sufficient.',
      });
    }

    if (pm25 > 25) {
      tips.add({
        'icon': Icons.masks,
        'color': const Color(0xFFFF6B6B),
        'title': 'High PM2.5 (${pm25.toStringAsFixed(1)} µg/m³)',
        'detail': 'Fine particle levels are elevated. Consider wearing a PM2.5 filter mask. Avoid routes near heavy traffic or construction sites.',
      });
    }

    if (o3 > 100) {
      tips.add({
        'icon': Icons.wb_sunny_outlined,
        'color': const Color(0xFFFFB347),
        'title': 'Elevated Ozone (${o3.toStringAsFixed(1)} µg/m³)',
        'detail': 'Ozone peaks in the afternoon on sunny days. Run in the early morning or evening to avoid peak ozone hours.',
      });
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final tips = _getTips();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Running Advice',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
              const SizedBox(width: 6),
              Text(locationName,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ]),
            const SizedBox(height: 20),

            ...tips.map((tip) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border(
                  left: BorderSide(
                    color: tip['color'] as Color,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(tip['icon'] as IconData,
                      color: tip['color'] as Color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tip['title'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tip['color'] as Color,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(tip['detail'] as String,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}