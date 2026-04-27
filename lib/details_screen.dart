import 'package:flutter/material.dart';
import 'pollutant_card.dart';

class DetailsScreen extends StatelessWidget {
  final int aqi;
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double temp;
  final int humidity;
  final double windSpeed;
  final String weatherDescription;
  final String locationName;

  const DetailsScreen({
    super.key,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.temp,
    required this.humidity,
    required this.windSpeed,
    required this.weatherDescription,
    required this.locationName,
  });

  Color _getAqiColor(int aqi) {
    switch (aqi) {
      case 1: return const Color(0xFF1E90FF);
      case 2: return const Color(0xFF00C49A);
      case 3: return const Color(0xFFFFB347);
      case 4: return const Color(0xFFFF6B6B);
      case 5: return const Color(0xFF9B59B6);
      default: return Colors.grey;
    }
  }

  String _getAqiLabel(int aqi) {
    switch (aqi) {
      case 1: return 'Good';
      case 2: return 'Fair';
      case 3: return 'Moderate';
      case 4: return 'Poor';
      case 5: return 'Very Poor';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Air Quality Details',
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

            // AQI 总览
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getAqiColor(aqi),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getAqiColor(aqi).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text('$aqi',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Air Quality Index',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_getAqiLabel(aqi),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 污染物卡片
            const Text('Air Pollutants',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Tap a card to learn more',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: PollutantCard(
                title: 'PM2.5',
                value: pm25.toStringAsFixed(1),
                unit: 'µg/m³',
                icon: Icons.blur_on,
                normalRange: '< 10 µg/m³',
                impact: 'High levels cause breathing difficulty during runs',
              )),
              const SizedBox(width: 12),
              Expanded(child: PollutantCard(
                title: 'O₃',
                value: o3.toStringAsFixed(1),
                unit: 'µg/m³',
                icon: Icons.wb_sunny_outlined,
                normalRange: '< 60 µg/m³',
                impact: 'Ozone irritates lungs, reduces stamina',
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PollutantCard(
                title: 'PM10',
                value: pm10.toStringAsFixed(1),
                unit: 'µg/m³',
                icon: Icons.blur_circular,
                normalRange: '< 20 µg/m³',
                impact: 'Coarse particles cause throat and airway irritation',
              )),
              const SizedBox(width: 12),
              Expanded(child: PollutantCard(
                title: 'NO₂',
                value: no2.toStringAsFixed(1),
                unit: 'µg/m³',
                icon: Icons.air,
                normalRange: '< 40 µg/m³',
                impact: 'Inflames airways, worsens asthma symptoms',
              )),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}