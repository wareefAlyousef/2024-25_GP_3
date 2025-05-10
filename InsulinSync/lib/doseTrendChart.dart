import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:insulin_sync/models/insulin_model.dart';
import 'services/user_service.dart';

class DoseTrendChart extends StatefulWidget {
  const DoseTrendChart({Key? key}) : super(key: key);

  @override
  State<DoseTrendChart> createState() => _DoseTrendChartState();
}

class _DoseTrendChartState extends State<DoseTrendChart> {
  late DateTime _startDate;
  late DateTime _endDate;
  late Future<Map<DateTime, Map<String, double>>> _doseData;
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  final double _itemWidth = 60; // Width of each day's data point
  final double _chartHeight = 400;

  double _theTop = 50;

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
    _doseData = _fetchDoseData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // You can add pagination logic here if needed
  }

  void _calculateDateRange() {
    _startDate = DateTime.now().subtract(const Duration(days: 29));
    _endDate = DateTime.now();
  }

  Future<Map<DateTime, Map<String, double>>> _fetchDoseData() async {
    final doseData = <DateTime, Map<String, double>>{};

    try {
      List<InsulinDosage> allDosages = await _userService.getInsulinDosages();

      DateTime newestDate = DateTime.now();
      DateTime oldestDate = newestDate.subtract(const Duration(days: 29));

      if (allDosages.isNotEmpty) {
        // If we have data, use actual date range
        final dates = allDosages
            .map((d) => DateTime(d.time.year, d.time.month, d.time.day))
            .toSet();

        oldestDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        newestDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);

        // Ensure minimum 30-day range
        final dataRangeDays = newestDate.difference(oldestDate).inDays + 1;
        if (dataRangeDays < 30) {
          oldestDate = newestDate.subtract(const Duration(days: 29));
        }
      }

      // Generate all dates in range (newest to oldest)
      final totalDays = newestDate.difference(oldestDate).inDays + 1;

      for (int i = 0; i < totalDays; i++) {
        final currentDate = newestDate.subtract(Duration(days: i));
        final dateOnly =
            DateTime(currentDate.year, currentDate.month, currentDate.day);

        doseData[dateOnly] = {'bolus': 0.0, 'basal': 0.0};
      }

      // If we have actual data, populate the values
      if (allDosages.isNotEmpty) {
        for (var dosage in allDosages) {
          final dateOnly =
              DateTime(dosage.time.year, dosage.time.month, dosage.time.day);
          final type = dosage.type.toLowerCase();

          if (doseData.containsKey(dateOnly)) {
            if (type == 'bolus') {
              doseData[dateOnly]!['bolus'] =
                  doseData[dateOnly]!['bolus']! + dosage.dosage;
            } else if (type == 'basal') {
              doseData[dateOnly]!['basal'] =
                  doseData[dateOnly]!['basal']! + dosage.dosage;
            }
          }
        }
      }

      return doseData;
    } catch (e) {
      debugPrint('Error processing dose data: $e');
      return {};
    }
  }

  List<FlSpot> _generateSpots(
      Map<DateTime, Map<String, double>> data, String doseType) {
    final spots = <FlSpot>[];
    // Sort dates in descending order (newest first)
    final daysList = data.keys.toList()..sort((a, b) => b.compareTo(a));
    final totalDays = daysList.length;

    for (int i = 0; i < totalDays; i++) {
      final date = daysList[i];
      // Use direct index mapping (0 = newest, 29 = oldest)
      final dayIndex = i.toDouble();
      final value = data[date]![doseType.toLowerCase()] ?? 0;
      spots.add(FlSpot(dayIndex, value > 0 ? value : 0));
    }
    return spots;
  }

  String _getDayName(DateTime date) {
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight,
      child: FutureBuilder<Map<DateTime, Map<String, double>>>(
        future: _doseData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load data'));
          }

          final data = snapshot.data!;
          final dates = data.keys.toList()..sort((a, b) => b.compareTo(a));
          final rawMax = data.values.fold(
              0.0, (max, e) => e.values.fold(max, (m, v) => v > m ? v : m));
          final double maxY = _calculateUpMaxY(rawMax);

          return Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.rotate(
                      angle: -3.14159 / 2, // 90 degrees in radians
                      child: Center(
                        child: Text(
                          'Units',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Y-axis
                    SizedBox(
                      width: 30,
                      height: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(top: _theTop),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: maxY,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _calculateYInterval(maxY),
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const SizedBox();
                                    }
                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              bottomTitles: const AxisTitles(),
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: true),
                            lineBarsData: [],
                          ),
                        ),
                      ),
                    ),
                    // Chart area
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: _itemWidth * data.length,
                          height: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 13.0, right: 16.0, top: _theTop),
                            child: LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: maxY,
                                lineTouchData: LineTouchData(
                                  enabled: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipMargin: 10,
                                    fitInsideHorizontally: false,
                                    fitInsideVertically: false,
                                    showOnTopOfTheChartBoxArea: true,
                                    tooltipPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    getTooltipColor: (touchedSpot) =>
                                        Colors.white,
                                    tooltipBorder: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 1,
                                    ),
                                    getTooltipItems:
                                        (List<LineBarSpot> touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        final dayIndex = spot.x.toInt();
                                        // Get date from the sorted dates list (newest first)
                                        if (dayIndex < 0 ||
                                            dayIndex >= dates.length)
                                          return const LineTooltipItem(
                                              '', TextStyle());

                                        final doseType = spot.barIndex == 0
                                            ? 'Basal'
                                            : 'Bolus';
                                        final doseValue = spot.y;

                                        return LineTooltipItem(
                                          '${doseValue.toStringAsFixed(1)} units $doseType',
                                          TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value % 1 != 0) return SizedBox();
                                        final dateIndex = value.toInt();
                                        if (dateIndex < 0 ||
                                            dateIndex >= dates.length) {
                                          return SizedBox();
                                        }
                                        final date = dates[dateIndex];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            _getDayName(date),
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      },
                                      reservedSize: 24,
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(),
                                  rightTitles: const AxisTitles(),
                                  topTitles: const AxisTitles(),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: Border.all(color: Colors.grey),
                                ),
                                gridData: FlGridData(show: true),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _generateSpots(data, 'basal'),
                                    isCurved: true,
                                    curveSmoothness: 0.01,
                                    color: const Color(0xFF5594FF),
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: _generateSpots(data, 'bolus'),
                                    isCurved: true,
                                    curveSmoothness: 0.01,
                                    color: Theme.of(context).primaryColor,
                                    barWidth: 3,
                                    dotData: const FlDotData(show: true),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 100.0),
                child: Text(
                  'Days',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(Theme.of(context).primaryColor, 'Bolus'),
                    const SizedBox(width: 20),
                    _buildLegend(const Color(0xFF5594FF), 'Basal'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateUpMaxY(double max) {
    if (max < 10) {
      return 10; // Avoid divide-by-zero
    }

    // Step 1: Get the raw interval (for 6 values)
    double rawInterval = max / 5;

    // Step 2: Find the magnitude (power of 10)
    double magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();

    // Step 3: Normalize the raw interval by magnitude
    double normalized = rawInterval / magnitude;

    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    double niceInterval = niceNormalized * magnitude;

    double result = (niceInterval * 5).ceilToDouble();

    return result; // Ceiling to nearest clean value
  }

  double _calculateYInterval(double _currentMaxY) {
    if (_currentMaxY == 0) return 10; // Avoid divide-by-zero

    // Step 1: Get the raw interval (for 6 values)
    double rawInterval = _currentMaxY / 5;

    // Step 2: Find the magnitude (power of 10)
    double magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();

    // Step 3: Normalize the raw interval by magnitude
    double normalized = rawInterval / magnitude;

    // Step 4: Choose the next  interval based on the normalized value
    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    // Step 5: Calculate the final  interval
    double niceInterval = niceNormalized * magnitude;

    return niceInterval;
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
