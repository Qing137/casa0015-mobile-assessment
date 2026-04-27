import 'package:flutter/material.dart';
import 'dart:math';
import 'air_quality_service.dart';

class WeatherScreen extends StatefulWidget {
  final double lat;
  final double lon;
  final double currentTemp;
  final int humidity;
  final double windSpeed;
  final String weatherDescription;
  final String locationName;

  const WeatherScreen({
    super.key,
    required this.lat,
    required this.lon,
    required this.currentTemp,
    required this.humidity,
    required this.windSpeed,
    required this.weatherDescription,
    required this.locationName,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final AirQualityService _service = AirQualityService();
  List<Map<String, dynamic>> _forecast = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    try {
      final data = await _service.fetchHourlyForecast(widget.lat, widget.lon);
      setState(() {
        _forecast = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  String _getRainSummary() {
    if (_forecast.isEmpty) return '';
    final dryHours = _forecast.where((h) => (h['precipProb'] as int) < 30).length;
    if (dryHours == _forecast.length) {
      return 'No rain expected in the next ${_forecast.length} hours — great time to run!';
    }
    final firstRainIndex = _forecast.indexWhere((h) => (h['precipProb'] as int) >= 30);
    if (firstRainIndex == 0) return 'Rain likely now — consider waiting or wearing a jacket.';
    final firstRainTime = _forecast[firstRainIndex]['time'];
    final prob = _forecast[firstRainIndex]['precipProb'];
    return 'Dry for the next $firstRainIndex hour${firstRainIndex > 1 ? 's' : ''}. ${prob}% chance of rain around $firstRainTime.';
  }

  bool _hasRainSoon() {
    if (_forecast.isEmpty) return false;
    return _forecast.take(2).any((h) => (h['precipProb'] as int) >= 30);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Weather', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(children: [
                    Icon(Icons.location_on, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(widget.locationName,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
                  const SizedBox(height: 16),

                  // 跑步建议摘要
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _hasRainSoon() ? Colors.orange.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasRainSoon() ? Colors.orange.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _hasRainSoon() ? Colors.orange.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.directions_run,
                              color: _hasRainSoon() ? Colors.orange.shade700 : Colors.green.shade700,
                              size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_getRainSummary(),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _hasRainSoon() ? Colors.orange.shade800 : Colors.green.shade800)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 未来6小时图表
                  if (_forecast.isNotEmpty)
                    Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Next 6 hours',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Container(width: 16, height: 3,
                                color: Colors.green.shade600),
                            const SizedBox(width: 6),
                            Text('Temperature (°C)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(width: 16),
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('Rain probability (%)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                          ]),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: LayoutBuilder(
                              builder: (context, constraints) => CustomPaint(
                                painter: _ChartPainter(_forecast),
                                size: Size(constraints.maxWidth, 180),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _forecast.map((hour) {
                              final isNow = hour['isNow'] as bool;
                              return Text(
                                isNow ? 'Now' : hour['time'],
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                                    color: isNow ? Colors.green.shade700 : Colors.grey.shade500),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> forecast;

  _ChartPainter(this.forecast);

  @override
  void paint(Canvas canvas, Size size) {
    if (forecast.isEmpty) return;

    final temps = forecast.map((h) => h['temp'] as double).toList();
    final probs = forecast.map((h) => (h['precipProb'] as int).toDouble()).toList();

    final maxTemp = temps.reduce(max);
    final minTemp = temps.reduce(min);
    final tempRange = (maxTemp - minTemp).clamp(2.0, double.infinity);
    final n = forecast.length;
    final colWidth = size.width / n;

    // 柱状图：降雨概率
    for (int i = 0; i < n; i++) {
      final prob = probs[i];
      if (prob > 0) {
        final barHeight = (prob / 100) * (size.height * 0.35);
        final x = colWidth * i + colWidth * 0.25;
        final barWidth = colWidth * 0.5;

        final barPaint = Paint()
          ..color = prob >= 30
              ? Colors.blue.shade300
              : Colors.blue.shade100
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
            const Radius.circular(3),
          ),
          barPaint,
        );

        // 概率数值
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${prob.toInt()}%',
            style: TextStyle(
                color: prob >= 30 ? Colors.blue.shade600 : Colors.blue.shade300,
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x + barWidth / 2 - textPainter.width / 2,
              size.height - barHeight - 14),
        );
      }
    }

    // 折线：温度
    final linePaint = Paint()
      ..color = Colors.green.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.green.shade600
      ..style = PaintingStyle.fill;

    final topPadding = 30.0;
    final chartHeight = size.height * 0.55;

    List<Offset> points = [];
    for (int i = 0; i < n; i++) {
      final x = colWidth * i + colWidth / 2;
      final normalized = (temps[i] - minTemp) / tempRange;
      final y = topPadding + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(points[i], 3, dotPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${temps[i].toStringAsFixed(0)}°',
          style: TextStyle(
              color: forecast[i]['isNow'] as bool
                  ? Colors.green.shade700
                  : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}