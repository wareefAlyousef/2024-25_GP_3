import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'models/meal_model.dart';
import 'services/user_service.dart';

class NutritionStackedBarChart extends StatefulWidget {
  const NutritionStackedBarChart({
    Key? key,
  }) : super(key: key);

  @override
  State<NutritionStackedBarChart> createState() =>
      _NutritionStackedBarChartState();
}

class _NutritionStackedBarChartState extends State<NutritionStackedBarChart> {
  late DateTime _startDate;
  late DateTime _endDate;
  late Future<Map<DateTime, Map<String, double>>> _nutritionData;
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  final double _itemWidth = 60; // Width of each day's bar
  final double _chartHeight = 400;
  final double _theTop = 50;
  DateTime selectedDate = DateTime.now();

  double _currentMaxY = 1000;
  int _visibleStartIndex = 0;
  int _visibleEndIndex = 6;
  final int _visibleDays = 7;

  Map<DateTime, Map<String, double>> data = {};

  Color carbColor = const Color(0xFF5594FF);
  Color proteinColor = const Color(0xFF0352CF);
  Color fatColor = const Color(0xFF023B95);

  @override
  void initState() {
    super.initState();
    _calculateDateRange();
    _nutritionData = _fetchNutritionData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose(); // Proper disposal
    super.dispose();
  }

  void _scrollListener() {
    _updateVisibleRange();
  }

  void _calculateDateRange() {
    _startDate = selectedDate.subtract(const Duration(days: 29));
    _endDate = selectedDate;
  }

  Future<Map<DateTime, Map<String, double>>> _fetchNutritionData() async {
    final nutritionData = <DateTime, Map<String, double>>{};

    try {
      List<meal> allMeals = await _userService.getMeal();

      // Always calculate date range based on last 30 days (or more if data exists)
      DateTime newestDate = DateTime.now();
      DateTime oldestDate = newestDate.subtract(const Duration(days: 29));

      if (allMeals.isNotEmpty) {
        // If we have data, use actual date range
        final dates = allMeals
            .map((m) => DateTime(m.time.year, m.time.month, m.time.day))
            .toSet();

        oldestDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
        newestDate = DateTime.now();

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

        nutritionData[dateOnly] = {'carb': 0.0, 'protein': 0.0, 'fat': 0.0};
      }

      // If we have actual data, populate the values
      if (allMeals.isNotEmpty) {
        for (var meal in allMeals) {
          final dateOnly =
              DateTime(meal.time.year, meal.time.month, meal.time.day);

          if (nutritionData.containsKey(dateOnly)) {
            for (var foodItem in meal.foodItems) {
              nutritionData[dateOnly]!['carb'] =
                  nutritionData[dateOnly]!['carb']! + foodItem.carb;
              nutritionData[dateOnly]!['protein'] =
                  nutritionData[dateOnly]!['protein']! + foodItem.protein;
              nutritionData[dateOnly]!['fat'] =
                  nutritionData[dateOnly]!['fat']! + foodItem.fat;
            }
          }
        }
      }

      return nutritionData;
    } catch (e) {
      return {};
    }
  }

  List<BarChartGroupData> _generateBars(
      Map<DateTime, Map<String, double>> data) {
    final bars = <BarChartGroupData>[];
    final daysList = data.keys.toList()..sort((a, b) => b.compareTo(a));

    for (int i = 0; i < daysList.length; i++) {
      final date = daysList[i];
      final values = data[date]!;
      final carb = values['carb'] ?? 0;
      final protein = values['protein'] ?? 0;
      final fat = values['fat'] ?? 0;

      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: carb + protein + fat, // total height
            rodStackItems: [
              BarChartRodStackItem(0, carb, carbColor),
              BarChartRodStackItem(carb, carb + protein, proteinColor),
              BarChartRodStackItem(
                  carb + protein, carb + protein + fat, fatColor),
            ],
            width: 12,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }

    return bars;
  }

  String _getDayName(DateTime date) {
    return '${date.day}/${date.month}';
  }

  double _calculateUpMaxY(double max) {
    if (max < 10) {
      return 10; // Avoid divide-by-zero
    }

    // Step 1: Get the raw interval (for 6 values)
    double rawInterval = max / 5;
    print('debug maxy: Raw interval = $rawInterval');

    // Step 2: Find the magnitude (power of 10)
    double magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();
    print('debug maxy: Magnitude = $magnitude');

    // Step 3: Normalize the raw interval by magnitude
    double normalized = rawInterval / magnitude;
    print('debug maxy: Normalized = $normalized');

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
    print('debug maxy: Nice normalized = $niceNormalized');

    double niceInterval = niceNormalized * magnitude;
    print('debug maxy: Nice interval = $niceInterval');

    double result = (niceInterval * 5).ceilToDouble();
    print('debug maxy: Final result = $result');

    return result; // Ceiling to nearest clean value
  }

  double _calculateYInterval() {
    if (_currentMaxY == 0) return 10; // Avoid divide-by-zero

    // Step 1: Get the raw interval (for 6 values)
    double rawInterval = _currentMaxY / 5;

    // Step 2: Find the magnitude (power of 10)
    double magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();

    // Step 3: Normalize the raw interval by magnitude
    double normalized = rawInterval / magnitude;

    // Step 4: Choose the next "nice" interval based on the normalized value
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

    // Step 5: Calculate the final interval
    double niceInterval = niceNormalized * magnitude;

    return niceInterval;
  }

  void _updateVisibleRange() {
    if (data.isEmpty) return;

    final scrollOffset = _scrollController.offset;
    _visibleStartIndex = (scrollOffset / _itemWidth).floor();
    _visibleEndIndex = _visibleStartIndex + _visibleDays - 1;

    if (_visibleEndIndex >= data.length) {
      _visibleEndIndex = data.length - 1;
    }

    // Calculate max only for visible items
    double visibleMax = 0;
    final dates = data.keys.toList()..sort((a, b) => b.compareTo(a));

    for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
      if (i < 0 || i >= dates.length) continue;

      final values = data[dates[i]]!;
      final total = (values['carb'] ?? 0) +
          (values['protein'] ?? 0) +
          (values['fat'] ?? 0);
      if (total > visibleMax) visibleMax = total;
    }

    setState(() {
      _currentMaxY = _calculateUpMaxY(visibleMax);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chartHeight,
      child: FutureBuilder<Map<DateTime, Map<String, double>>>(
        future: _nutritionData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load data'));
          }

          data = snapshot.data!;

          double visibleMax = 0;
          final dates = data.keys.toList()..sort((a, b) => b.compareTo(a));

          for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
            if (i < 0 || i >= dates.length) continue;

            final values = data[dates[i]]!;
            final total = (values['carb'] ?? 0) +
                (values['protein'] ?? 0) +
                (values['fat'] ?? 0);
            if (total > visibleMax) visibleMax = total;
          }

          _currentMaxY = _calculateUpMaxY(visibleMax);

          return Column(
            children: [
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification ||
                        notification is ScrollEndNotification) {
                      _updateVisibleRange();
                    }
                    return false;
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.rotate(
                        angle: -3.14159 / 2, // 90 degrees in radians
                        child: Center(
                          child: Text(
                            'Grams',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      // Y-axis
                      SizedBox(
                        width: 40,
                        height: double.infinity,
                        child: Padding(
                          padding: EdgeInsets.only(top: _theTop),
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: _currentMaxY,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: _calculateYInterval(),
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      final interval = _calculateYInterval();
                                      if (value % interval != 0 || value == 0)
                                        return const SizedBox();

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4.0),
                                        child: Text(
                                          '${value.toInt()}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(),
                                topTitles: const AxisTitles(),
                                bottomTitles: const AxisTitles(),
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
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _currentMaxY,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      fitInsideHorizontally: false,
                                      fitInsideVertically: false,
                                      tooltipBorder: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                        width: 1,
                                      ),
                                      getTooltipColor: (touchedSpot) {
                                        return Colors.white;
                                      },
                                      getTooltipItem:
                                          (group, groupIndex, rod, rodIndex) {
                                        final date = dates[groupIndex];

                                        // Get the rod stack items (carb, protein, fat)
                                        final stackItems =
                                            rod.rodStackItems ?? [];

                                        double carb = 0;
                                        double protein = 0;
                                        double fat = 0;

                                        if (stackItems.length >= 3) {
                                          carb = stackItems[0].toY -
                                              stackItems[0].fromY;
                                          protein = stackItems[1].toY -
                                              stackItems[1].fromY;
                                          fat = stackItems[2].toY -
                                              stackItems[2].fromY;
                                        }

                                        return BarTooltipItem(
                                          'Carbs: ${carb.toStringAsFixed(0)}g\n'
                                          'Protein: ${protein.toStringAsFixed(0)}g\n'
                                          'Fat: ${fat.toStringAsFixed(0)}g',
                                          TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value % 1 != 0)
                                            return const SizedBox();
                                          final dateIndex = value.toInt();
                                          if (dateIndex < 0 ||
                                              dateIndex >= dates.length) {
                                            return const SizedBox();
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
                                  barGroups: _generateBars(data),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend(carbColor, 'Carbs'),
                    const SizedBox(width: 20),
                    _buildLegend(fatColor, 'Fat'),
                    const SizedBox(width: 20),
                    _buildLegend(proteinColor, 'Protein'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
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
