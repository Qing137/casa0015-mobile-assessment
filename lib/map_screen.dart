import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'air_quality_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final AirQualityService _service = AirQualityService();
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(51.5074, -0.1278);
  bool _isScanning = false;
  Map<String, dynamic>? _selectedResult;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndScan();
  }

  Future<void> _getCurrentLocationAndScan() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 13),
      );
      await _scanAllSpots();
    } catch (e) {
      print(e);
    }
  }

  double _aqiToHue(int aqi) {
    switch (aqi) {
      case 1: return BitmapDescriptor.hueBlue;
      case 2: return BitmapDescriptor.hueCyan;
      case 3: return BitmapDescriptor.hueOrange;
      case 4: return BitmapDescriptor.hueRed;
      case 5: return BitmapDescriptor.hueViolet;
      default: return BitmapDescriptor.hueGreen;
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

  IconData _getPlaceIcon(String type) {
    switch (type) {
      case 'park': return Icons.park;
      case 'stadium': return Icons.stadium;
      case 'gym': return Icons.fitness_center;
      case 'natural_feature': return Icons.terrain;
      case 'tourist_attraction': return Icons.attractions;
      default: return Icons.place;
    }
  }

  String _getPlaceTypeLabel(String type) {
    switch (type) {
      case 'park': return 'Park';
      case 'stadium': return 'Stadium';
      case 'gym': return 'Gym';
      case 'natural_feature': return 'Nature';
      case 'tourist_attraction': return 'Attraction';
      default: return 'Place';
    }
  }

  Future<void> _scanAllSpots() async {
    setState(() {
      _isScanning = true;
      _selectedResult = null;
      _markers = {};
    });

    try {
      // 先获取附近地点
      final places = await _service.fetchNearbyPlaces(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );

      List<Map<String, dynamic>> results = [];

      for (final place in places) {
        try {
          final aqi = await _service.fetchAirQuality(place['lat'], place['lon']);
          final weather = await _service.fetchWeather(place['lat'], place['lon']);
          results.add({
            'name': place['name'],
            'lat': place['lat'],
            'lon': place['lon'],
            'type': place['type'],
            'aqi': aqi['aqi'],
            'temp': weather['temp'],
            'wind': weather['windSpeed'],
            'humidity': weather['humidity'],
            'description': weather['description'],
          });
        } catch (e) {
          print('Error scanning ${place['name']}: $e');
        }
      }

      Set<Marker> markers = {};
      for (final r in results) {
        markers.add(Marker(
          markerId: MarkerId(r['name']),
          position: LatLng(r['lat'], r['lon']),
          icon: BitmapDescriptor.defaultMarkerWithHue(_aqiToHue(r['aqi'])),
          onTap: () => _showSpotDetail(r),
        ));
      }

      setState(() {
        _isScanning = false;
        _markers = markers;
        if (results.isNotEmpty) {
          _selectedResult = results.first;
        }
      });
    } catch (e) {
      setState(() { _isScanning = false; });
      print('Error: $e');
    }
  }

  void _showSpotDetail(Map<String, dynamic> spot) {
    setState(() {
      _selectedResult = spot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Spots',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_currentPosition, 13),
              );
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // 扫描中
          if (_isScanning)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: Colors.green),
                    const SizedBox(height: 12),
                    Text('Loading...',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),

          // 选中地点详情
          if (_selectedResult != null && !_isScanning)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getPlaceIcon(_selectedResult!['type'] ?? 'park'),
                            color: Colors.green.shade700, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(_selectedResult!['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPlaceTypeLabel(_selectedResult!['type'] ?? 'park'),
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _getAqiColor(_selectedResult!['aqi']),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text('${_selectedResult!['aqi']}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _service.getAqiLabel(_selectedResult!['aqi']),
                                    style: TextStyle(
                                        color: _getAqiColor(_selectedResult!['aqi']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(
                                    _service.getAqiAdvice(_selectedResult!['aqi']),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _weatherTile(Icons.thermostat,
                              '${(_selectedResult!['temp'] as double).toStringAsFixed(1)}°C',
                              'Temp', Colors.orange),
                          _weatherTile(Icons.water_drop,
                              '${_selectedResult!['humidity']}%',
                              'Humidity', Colors.blue),
                          _weatherTile(Icons.air,
                              '${(_selectedResult!['wind'] as double).toStringAsFixed(1)} m/s',
                              'Wind', Colors.teal),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          (_selectedResult!['description'] as String).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weatherTile(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}