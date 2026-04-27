import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

class TrackingScreen extends StatefulWidget {
  final String locationName;
  final int? aqi;

  const TrackingScreen({
    super.key,
    required this.locationName,
    this.aqi,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isFinished = false;

  int _steps = 0;
  double _distanceKm = 0.0;
  int _seconds = 0;
  double _currentPace = 0.0;

  // 步态检测
  double _lastMagnitude = 0;
  bool _stepUp = false;
  static const double _threshold = 11.5;
  static const double _stepLengthM = 0.75;

  Timer? _timer;
  StreamSubscription? _accelerometerSub;

  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastWeight();
  }

  Future<void> _loadLastWeight() async {
    final prefs = await SharedPreferences.getInstance();
    _weightController.text = prefs.getString('last_weight') ?? '';
  }

  void _startRun() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _steps = 0;
      _distanceKm = 0.0;
      _seconds = 0;
      _currentPace = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
          if (_distanceKm > 0 && _seconds > 0) {
            _currentPace = (_seconds / 60) / _distanceKm;
          }
        });
      }
    });

    _accelerometerSub = accelerometerEventStream().listen((event) {
      if (!_isRunning || _isPaused) return;
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude > _threshold && _lastMagnitude <= _threshold && !_stepUp) {
        _stepUp = true;
        setState(() {
          _steps++;
          _distanceKm = (_steps * _stepLengthM) / 1000;
        });
      } else if (magnitude < _threshold) {
        _stepUp = false;
      }
      _lastMagnitude = magnitude;
    });
  }

  void _pauseRun() {
    setState(() { _isPaused = true; });
  }

  void _resumeRun() {
    setState(() { _isPaused = false; });
  }

  void _stopRun() {
    _timer?.cancel();
    _accelerometerSub?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = true;
    });
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double _calculateCalories() {
    final weight = double.tryParse(_weightController.text) ?? 70;
    return weight * _distanceKm * 1.036;
  }

  Future<void> _saveRun() async {
    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your weight to calculate calories')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_weight', _weightController.text);

    final calories = _calculateCalories();
    final entry = jsonEncode({
      'date': DateTime.now().toString().substring(0, 16),
      'location': widget.locationName,
      'distance': _distanceKm.toStringAsFixed(2),
      'duration': (_seconds ~/ 60).toString(),
      'steps': _steps.toString(),
      'weight': _weightController.text,
      'calories': calories.toStringAsFixed(0),
      'note': _noteController.text,
      'aqi': widget.aqi ?? 0,
    });

    final List<String> runs = prefs.getStringList('run_history') ?? [];
    runs.add(entry);
    await prefs.setStringList('run_history', runs);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerSub?.cancel();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Track Run',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isFinished ? _buildSaveScreen() : _buildTrackingScreen(),
    );
  }

  Widget _buildTrackingScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          Row(children: [
            Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
            const SizedBox(width: 4),
            Text(widget.locationName,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 24),

          // 主数据卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(_formatTime(_seconds),
                    style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Duration',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statBlock('${_distanceKm.toStringAsFixed(2)}', 'km',
                        'Distance', Icons.straighten, Colors.green.shade600),
                    Container(height: 50, width: 1, color: Colors.grey.shade200),
                    _statBlock('$_steps', 'steps',
                        'Steps', Icons.directions_walk, Colors.blue),
                    Container(height: 50, width: 1, color: Colors.grey.shade200),
                    _statBlock(
                      _currentPace > 0 ? _currentPace.toStringAsFixed(1) : '--',
                      'min/km', 'Pace', Icons.speed, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 控制按钮
          if (!_isRunning)
            GestureDetector(
              onTap: _startRun,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 50),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isPaused ? _resumeRun : _pauseRun,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white, size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: _stopRun,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stop,
                        color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),

          if (_isRunning)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _isPaused ? 'Paused — tap play to resume' : 'Running — tap stop when done',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSaveScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 跑步总结
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('Run Complete! 🎉',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryTile('${_distanceKm.toStringAsFixed(2)}', 'km', 'Distance'),
                    _summaryTile(_formatTime(_seconds), '', 'Duration'),
                    _summaryTile('$_steps', 'steps', 'Steps'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 体重
          const Text('Your weight (kg)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 65',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.monitor_weight_outlined,
                  color: Colors.green.shade700, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Used to estimate calories burned',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          const SizedBox(height: 16),

          // 备注
          const Text('Note (optional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'How did it feel?',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Save Run',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String unit, String label,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(unit,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        Text(label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
      ],
    );
  }

  Widget _summaryTile(String value, String unit, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        if (unit.isNotEmpty)
          Text(unit,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}