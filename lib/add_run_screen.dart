import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddRunScreen extends StatefulWidget {
  final String locationName;
  final int? aqi;

  const AddRunScreen({
    super.key,
    required this.locationName,
    this.aqi,
  });

  @override
  State<AddRunScreen> createState() => _AddRunScreenState();
}

class _AddRunScreenState extends State<AddRunScreen> {
  final _distanceController = TextEditingController();
  final _durationController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLastWeight();
  }

  Future<void> _loadLastWeight() async {
    final prefs = await SharedPreferences.getInstance();
    final lastWeight = prefs.getString('last_weight') ?? '';
    _weightController.text = lastWeight;
  }

  double _calculateCalories() {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 70;
    return weight * distance * 1.036;
  }

  Future<void> _saveRun() async {
    if (_distanceController.text.isEmpty || _durationController.text.isEmpty ||
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in distance, duration and weight')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_weight', _weightController.text);

    final calories = _calculateCalories();
    final entry = jsonEncode({
      'date': DateTime.now().toString().substring(0, 16),
      'location': widget.locationName,
      'distance': _distanceController.text,
      'duration': _durationController.text,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Log a Run',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 位置和日期
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.locationName,
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(DateTime.now().toString().substring(0, 10),
                      style: TextStyle(color: Colors.green.shade600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 距离
            _inputLabel('Distance (km)'),
            const SizedBox(height: 8),
            _inputField(
              controller: _distanceController,
              hint: 'e.g. 5.0',
              icon: Icons.straighten,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 时长
            _inputLabel('Duration (minutes)'),
            const SizedBox(height: 8),
            _inputField(
              controller: _durationController,
              hint: 'e.g. 30',
              icon: Icons.timer,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 体重
            _inputLabel('Your weight (kg)'),
            const SizedBox(height: 8),
            _inputField(
              controller: _weightController,
              hint: 'e.g. 65',
              icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            Text('Used to estimate calories burned',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            const SizedBox(height: 16),

            // 备注
            _inputLabel('Note (optional)'),
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

            // 保存按钮
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
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.green.shade700, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}