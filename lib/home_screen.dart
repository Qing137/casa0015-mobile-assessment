import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'air_quality_service.dart';
import 'history_screen.dart';
import 'pollutant_card.dart';
import 'search_screen.dart';

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
  double? _o3;
  double? _no2;
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

      final locationName = await _service.fetchLocationName(
          position.latitude, position.longitude);

      setState(() {
        _aqi = data['aqi'];
        _pm25 = data['pm2_5'];
        _pm10 = data['pm10'];
        _o3 = data['o3'];
        _no2 = data['no2'];
        _locationName = locationName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('AirRun', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => HistoryScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RunningIcon(),
                  const SizedBox(height: 16),
                  Text('Checking air quality...',
                      style: TextStyle(color: Colors.green.shade700, fontSize: 14)),
                ],
              ),
            )
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
                        Row(children: [
                          Icon(Icons.location_on, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(_locationName,
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ]),
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getAqiColor(_aqi!),
                                _getAqiColor(_aqi!).withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: _getAqiColor(_aqi!).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
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

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(children: [
                            Icon(Icons.directions_run, size: 32, color: Colors.green.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_service.getAqiAdvice(_aqi!),
                                  style: const TextStyle(fontSize: 16)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 16),

                        const Text('Tap a card to learn more',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),

                        Row(children: [
                          Expanded(child: PollutantCard(
                            title: 'PM2.5',
                            value: '${_pm25?.toStringAsFixed(1)}',
                            unit: 'µg/m³',
                            icon: Icons.blur_on,
                            normalRange: '< 10 µg/m³',
                            impact: 'High levels cause breathing difficulty during runs',
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: PollutantCard(
                            title: 'O₃',
                            value: '${_o3?.toStringAsFixed(1)}',
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
                            value: '${_pm10?.toStringAsFixed(1)}',
                            unit: 'µg/m³',
                            icon: Icons.blur_circular,
                            normalRange: '< 20 µg/m³',
                            impact: 'Coarse particles cause throat and airway irritation',
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: PollutantCard(
                            title: 'NO₂',
                            value: '${_no2?.toStringAsFixed(1)}',
                            unit: 'µg/m³',
                            icon: Icons.air,
                            normalRange: '< 40 µg/m³',
                            impact: 'Inflames airways, worsens asthma symptoms',
                          )),
                        ]),
                        const SizedBox(height: 20),

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
}

class _RunningIcon extends StatefulWidget {
  @override
  State<_RunningIcon> createState() => _RunningIconState();
}

class _RunningIconState extends State<_RunningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: Icon(
            Icons.directions_run,
            size: 60,
            color: Colors.green.shade700,
          ),
        );
      },
    );
  }
}