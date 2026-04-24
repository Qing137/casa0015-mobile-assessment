import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'search_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(51.5074, -0.1278);

  final List<Map<String, dynamic>> _nearbyAreas = [
    {'name': 'Hyde Park', 'lat': 51.5073, 'lng': -0.1657},
    {'name': 'Regent\'s Park', 'lat': 51.5313, 'lng': -0.1570},
    {'name': 'Greenwich Park', 'lat': 51.4769, 'lng': -0.0005},
    {'name': 'Victoria Park', 'lat': 51.5361, 'lng': -0.0359},
    {'name': 'Hampstead Heath', 'lat': 51.5624, 'lng': -0.1773},
    {'name': 'Battersea Park', 'lat': 51.4794, 'lng': -0.1549},
    {'name': 'Richmond Park', 'lat': 51.4429, 'lng': -0.2756},
    {'name': 'Clapham Common', 'lat': 51.4613, 'lng': -0.1389},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    } catch (e) {
      print(e);
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (final area in _nearbyAreas) {
      markers.add(Marker(
        markerId: MarkerId(area['name']),
        position: LatLng(area['lat'], area['lng']),
        infoWindow: InfoWindow(
          title: area['name'],
          snippet: 'Tap to check air quality',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(initialQuery: area['name']),
              ),
            );
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Areas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 11,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _buildMarkers(),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}