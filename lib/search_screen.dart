import 'package:flutter/material.dart';
import 'air_quality_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final AirQualityService _service = AirQualityService();
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String _searchedLocation = '';
  String _error = '';

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() { _isLoading = true; _error = ''; _result = null; });
    try {
      final coords = await _service.fetchCoordinates(query);
      final data = await _service.fetchAirQuality(coords['lat'], coords['lon']);
      setState(() {
        _result = data;
        _searchedLocation = query;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Location not found. Try again.'; _isLoading = false; });
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

  String _getAqiAdvice(int aqi) {
    switch (aqi) {
      case 1: return 'Perfect for running!';
      case 2: return 'Good conditions for running';
      case 3: return 'Short runs are fine';
      case 4: return 'Consider indoor exercise';
      case 5: return 'Avoid outdoor running';
      default: return 'Unable to determine';
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
        title: const Text('Search Location',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'e.g. Hyde Park, London',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Search'),
              ),
            ]),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.green)),

            if (_error.isNotEmpty)
              Center(
                child: Text(_error,
                    style: const TextStyle(color: Colors.red)),
              ),

            if (_result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    Text(_searchedLocation,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _getAqiColor(_result!['aqi']),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('${_result!['aqi']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getAqiLabel(_result!['aqi']),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_getAqiAdvice(_result!['aqi']),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ]),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}