import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'tracking_screen.dart';

class RunLogScreen extends StatefulWidget {
  final String locationName;
  final int? aqi;

  const RunLogScreen({
    super.key,
    required this.locationName,
    this.aqi,
  });

  @override
  State<RunLogScreen> createState() => _RunLogScreenState();
}

class _RunLogScreenState extends State<RunLogScreen> {
  List<Map<String, dynamic>> _runs = [];

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> runs = prefs.getStringList('run_history') ?? [];
    setState(() {
      _runs = runs
          .map((r) => jsonDecode(r) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _deleteRun(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> runs = prefs.getStringList('run_history') ?? [];
    final actualIndex = runs.length - 1 - index;
    runs.removeAt(actualIndex);
    await prefs.setStringList('run_history', runs);
    _loadRuns();
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
        title: const Text('Run Log',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => TrackingScreen(
                  locationName: widget.locationName,
                  aqi: widget.aqi,
                )));
              if (result == true) _loadRuns();
            },
          ),
        ],
      ),
      body: _runs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No runs logged yet',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap + to log your first run!',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _runs.length,
              itemBuilder: (context, index) {
                final run = _runs[index];
                final aqi = run['aqi'] as int? ?? 0;
                return Dismissible(
                  key: Key(run['date'] + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteRun(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                          children: [
                            Expanded(
                              child: Text(run['date'] ?? '',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12)),
                            ),
                            if (aqi > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getAqiColor(aqi),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('AQI $aqi',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(children: [
                          Icon(Icons.location_on,
                              color: Colors.green.shade700, size: 14),
                          const SizedBox(width: 4),
                          Text(run['location'] ?? '',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statTile(Icons.straighten,
                                '${run['distance']} km', 'Distance'),
                            _statTile(Icons.timer,
                                '${run['duration']} min', 'Duration'),
                            _statTile(Icons.directions_walk,
                                '${run['steps'] ?? '--'} steps', 'Steps'),
                            _statTile(Icons.local_fire_department,
                                '${run['calories']} kcal', 'Calories'),
                          ],
                        ),
                        if ((run['note'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          const Divider(),
                          const SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.notes,
                                color: Colors.grey.shade400, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(run['note'],
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic)),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (_) => TrackingScreen(
              locationName: widget.locationName,
              aqi: widget.aqi,
            )));
          if (result == true) _loadRuns();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
      ],
    );
  }
}