import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'air_quality_service.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AirQualityService _service = AirQualityService();

  bool _isLoading = true;
  String _locationName = 'Locating...';
  int? _aqi;
  double? _pm25;
  double? _pm10;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = ''; });
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() { _error = 'Location permission denied'; _isLoading = false; });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final data = await _service.fetchAirQuality(
        position.latitude, position.longitude,
      );

      // 保存到历史记录
final prefs = await SharedPreferences.getInstance();
final List<String> history = prefs.getStringList('aqi_history') ?? [];
final newEntry = jsonEncode({
  'aqi': data['aqi'],
  'pm2_5': data['pm2_5'].toStringAsFixed(1),
  'pm10': data['pm10'].toStringAsFixed(1),
  'location': '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}',
  'time': DateTime.now().toString().substring(0, 16),
});
history.add(newEntry);
await prefs.setStringList('aqi_history', history);

setState(() {
  _aqi = data['aqi'];
  _pm25 = data['pm2_5'];
  _pm10 = data['pm10'];
  _locationName =
      '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
  _isLoading = false;
});
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _getAqiColor(int aqi) {
    switch (aqi) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      case 5: return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('AirRun', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error.isNotEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_error, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 位置卡片
                        Row(children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(_locationName,
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ]),
                        const SizedBox(height: 20),

                        // AQI 主卡片
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: _getAqiColor(_aqi!),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(children: [
                            const Text('Air Quality Index',
                                style: TextStyle(color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 12),
                            Text('$_aqi',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold)),
                            Text(_service.getAqiLabel(_aqi!),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // 建议卡片
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(children: [
                            const Icon(Icons.directions_run, size: 32, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_service.getAqiAdvice(_aqi!),
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        // PM数据卡片
                        Row(children: [
                          Expanded(child: _statCard('PM2.5',
                              '${_pm25?.toStringAsFixed(1)} µg/m³', Icons.blur_on)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('PM10',
                              '${_pm10?.toStringAsFixed(1)} µg/m³', Icons.blur_circular)),
                        ]),
                        const SizedBox(height: 20),

                        // 刷新提示
                        const Center(
                          child: Text('Pull down to refresh',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Icon(icon, color: Colors.green),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}