import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'air_quality_service.dart';
import 'map_screen.dart';
import 'details_screen.dart';
import 'advice_screen.dart';
import 'weather_screen.dart';
import 'run_log_screen.dart';
import 'tracking_screen.dart';

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
  double? _temp;
  int? _humidity;
  double? _windSpeed;
  String? _weatherDescription;
  String _error = '';
  LatLng _currentPosition = const LatLng(51.5074, -0.1278);

  final List<Map<String, dynamic>> _runningSpots = [
    {'name': 'Hyde Park', 'lat': 51.5073, 'lon': -0.1657},
    {'name': 'Hampstead Heath', 'lat': 51.5624, 'lon': -0.1680},
    {'name': 'Victoria Park', 'lat': 51.5362, 'lon': -0.0381},
    {'name': 'Regent\'s Park', 'lat': 51.5313, 'lon': -0.1536},
    {'name': 'Battersea Park', 'lat': 51.4793, 'lon': -0.1568},
    {'name': 'Richmond Park', 'lat': 51.4408, 'lon': -0.2858},
    {'name': 'Greenwich Park', 'lat': 51.4769, 'lon': -0.0010},
    {'name': 'Clapham Common', 'lat': 51.4613, 'lon': -0.1488},
    {'name': 'Finsbury Park', 'lat': 51.5641, 'lon': -0.1005},
    {'name': 'Wimbledon Common', 'lat': 51.4347, 'lon': -0.2282},
    {'name': 'Primrose Hill', 'lat': 51.5393, 'lon': -0.1601},
    {'name': 'Olympic Park', 'lat': 51.5484, 'lon': -0.0168},
    {'name': 'Bushy Park', 'lat': 51.4147, 'lon': -0.3368},
    {'name': 'Crystal Palace Park', 'lat': 51.4216, 'lon': -0.0714},
    {'name': 'Epping Forest', 'lat': 51.6500, 'lon': 0.0500},
    {'name': 'Lee Valley Park', 'lat': 51.6833, 'lon': -0.0167},
    {'name': 'Brockwell Park', 'lat': 51.4520, 'lon': -0.1096},
    {'name': 'Tooting Bec Common', 'lat': 51.4333, 'lon': -0.1500},
    {'name': 'Highgate Wood', 'lat': 51.5726, 'lon': -0.1465},
    {'name': 'Wanstead Park', 'lat': 51.5720, 'lon': 0.0365},
  ];

  Set<Marker> get _spotMarkers => _runningSpots.map((spot) => Marker(
    markerId: MarkerId(spot['name']),
    position: LatLng(spot['lat'], spot['lon']),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  )).toSet();

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

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      final data = await _service.fetchAirQuality(position.latitude, position.longitude);
      final weather = await _service.fetchWeather(position.latitude, position.longitude);

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

      final locationName = await _service.fetchLocationName(position.latitude, position.longitude);

      setState(() {
        _aqi = data['aqi'];
        _pm25 = data['pm2_5'];
        _pm10 = data['pm10'];
        _o3 = data['o3'];
        _no2 = data['no2'];
        _temp = weather['temp'];
        _humidity = weather['humidity'];
        _windSpeed = weather['windSpeed'];
        _weatherDescription = weather['description'];
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

  String _getOneLineSummary() {
    if (_aqi == null || _temp == null || _windSpeed == null) return '';
    if (_aqi! >= 4) return 'Poor air quality — indoor exercise recommended';
    if (_temp! > 30) return 'Extreme heat — avoid outdoor running';
    if (_windSpeed! > 12) return 'Strong winds — find a sheltered route';
    if (_aqi! <= 2 && _temp! >= 10 && _temp! <= 20) return 'Perfect day for a run!';
    if (_aqi! <= 2) return 'Good air quality — go for it!';
    return 'Moderate conditions — short runs are fine';
  }

  String _getAdviceTag() {
    if (_aqi == null || _temp == null || _windSpeed == null) return '';
    if (_aqi! >= 4 || _temp! > 30) return '⚠️ Not ideal today';
    if (_aqi! <= 2 && _temp! >= 10 && _temp! <= 20) return '✅ Great day for a run';
    return '👟 Good day for a run';
  }

  Color _getSummaryColor() {
    if (_aqi == null || _temp == null) return Colors.green.shade700;
    if (_aqi! >= 4 || (_temp != null && _temp! > 30)) return const Color(0xFFFF6B6B);
    if (_windSpeed != null && _windSpeed! > 12) return const Color(0xFFFFB347);
    if (_aqi! <= 2 && _temp! >= 10 && _temp! <= 20) return const Color(0xFF00C49A);
    return Colors.green.shade600;
  }

  IconData _getWeatherIcon() {
    final desc = _weatherDescription?.toLowerCase() ?? '';
    if (desc.contains('clear')) return Icons.wb_sunny;
    if (desc.contains('rain') || desc.contains('drizzle')) return Icons.grain;
    if (desc.contains('snow')) return Icons.ac_unit;
    if (desc.contains('storm') || desc.contains('thunder')) return Icons.thunderstorm;
    if (desc.contains('mist') || desc.contains('fog')) return Icons.foggy;
    if (desc.contains('cloud')) return Icons.cloud;
    return Icons.wb_cloudy;
  }

  Color _getWeatherIconColor() {
    final desc = _weatherDescription?.toLowerCase() ?? '';
    if (desc.contains('clear')) return Colors.amber;
    if (desc.contains('rain') || desc.contains('drizzle')) return Colors.blue;
    if (desc.contains('snow')) return Colors.lightBlue;
    if (desc.contains('storm') || desc.contains('thunder')) return Colors.deepPurple;
    if (desc.contains('mist') || desc.contains('fog')) return Colors.blueGrey;
    return Colors.blueGrey;
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _navigateToTracking() {
    if (_aqi == null) return;
    Navigator.push(context,
      MaterialPageRoute(builder: (_) => TrackingScreen(
        locationName: _locationName,
        aqi: _aqi,
      )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Runify',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => RunLogScreen(
                locationName: _locationName,
                aqi: _aqi,
              ))),
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
                  Text('Checking conditions...',
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
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollEndNotification &&
                        notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 10) {
                      _navigateToTracking();
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // 迷你地图卡片
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => MapScreen())),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20)),
                                  child: SizedBox(
                                    height: 160,
                                    child: AbsorbPointer(
                                      child: GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: _currentPosition,
                                          zoom: 11,
                                        ),
                                        markers: _spotMarkers,
                                        myLocationEnabled: false,
                                        myLocationButtonEnabled: false,
                                        zoomControlsEnabled: false,
                                        mapToolbarEnabled: false,
                                        compassEnabled: false,
                                        scrollGesturesEnabled: false,
                                        zoomGesturesEnabled: false,
                                        rotateGesturesEnabled: false,
                                        tiltGesturesEnabled: false,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Find your best run today! 🏃',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to check for a running spot\nyou might like nearby',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Icon(Icons.arrow_forward,
                                            color: Colors.green.shade700, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 卡片1：跑步建议
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AdviceScreen(
                              aqi: _aqi!,
                              temp: _temp!,
                              humidity: _humidity!,
                              windSpeed: _windSpeed!,
                              pm25: _pm25!,
                              o3: _o3!,
                              locationName: _locationName,
                            ))),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: _getSummaryColor().withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(Icons.directions_run,
                                      color: _getSummaryColor(), size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Advice',
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(_getOneLineSummary(),
                                          style: TextStyle(
                                              color: _getSummaryColor(),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getSummaryColor().withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(_getAdviceTag(),
                                            style: TextStyle(
                                                color: _getSummaryColor(),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: Colors.grey, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 卡片2和3并排
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              // 卡片2：AQI
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => DetailsScreen(
                                      aqi: _aqi!,
                                      pm25: _pm25!,
                                      pm10: _pm10!,
                                      o3: _o3!,
                                      no2: _no2!,
                                      temp: _temp!,
                                      humidity: _humidity!,
                                      windSpeed: _windSpeed!,
                                      weatherDescription: _weatherDescription ?? '',
                                      locationName: _locationName,
                                    ))),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Air Quality',
                                                style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 13)),
                                            Icon(Icons.chevron_right,
                                                color: Colors.grey.shade400,
                                                size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: _getAqiColor(_aqi!),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: Text('$_aqi',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(_service.getAqiLabel(_aqi!),
                                            style: TextStyle(
                                                color: _getAqiColor(_aqi!),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18)),
                                        const SizedBox(height: 4),
                                        Text('AQI (UK)',
                                            style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 12)),
                                        const SizedBox(height: 12),
                                        Text('Tap for full air quality breakdown',
                                            style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // 卡片3：天气
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => WeatherScreen(
                                      lat: _currentPosition.latitude,
                                      lon: _currentPosition.longitude,
                                      currentTemp: _temp!,
                                      humidity: _humidity!,
                                      windSpeed: _windSpeed!,
                                      weatherDescription: _weatherDescription ?? '',
                                      locationName: _locationName,
                                    ))),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Weather',
                                                style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 13)),
                                            Icon(Icons.chevron_right,
                                                color: Colors.grey.shade400,
                                                size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        Row(children: [
                                          Icon(_getWeatherIcon(),
                                              color: _getWeatherIconColor(), size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _capitalize(_weatherDescription ?? ''),
                                              style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(height: 14),
                                        Row(children: [
                                          Icon(Icons.thermostat,
                                              color: Colors.orange, size: 20),
                                          const SizedBox(width: 6),
                                          Text('${_temp?.toStringAsFixed(1)}°C',
                                              style: const TextStyle(fontSize: 14)),
                                        ]),
                                        const SizedBox(height: 10),
                                        Row(children: [
                                          Icon(Icons.water_drop,
                                              color: Colors.blue, size: 20),
                                          const SizedBox(width: 6),
                                          Text('$_humidity%',
                                              style: const TextStyle(fontSize: 14)),
                                        ]),
                                        const SizedBox(height: 10),
                                        Row(children: [
                                          Icon(Icons.air,
                                              color: Colors.teal, size: 20),
                                          const SizedBox(width: 6),
                                          Text('${_windSpeed?.toStringAsFixed(1)} m/s',
                                              style: const TextStyle(fontSize: 14)),
                                        ]),
                                        const SizedBox(height: 12),
                                        Text('Tap for hourly forecast',
                                            style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 上滑提示
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.keyboard_arrow_up,
                                  color: Colors.green.shade600, size: 28),
                              Text('Swipe up to start running',
                                  style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                            ],
                          ),
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