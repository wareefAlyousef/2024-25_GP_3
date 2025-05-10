import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:store_redirect/store_redirect.dart';

class CaloriesLineChart extends StatefulWidget {
  const CaloriesLineChart({super.key});

  @override
  State<CaloriesLineChart> createState() => _CaloriesLineChartState();
}

class _CaloriesLineChartState extends State<CaloriesLineChart> {
  // State variables
  bool _apiAvailable = false;
  bool _hasCaloriesPermission = false;
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 30;

  Map<DateTime, double> calories = {};
  List<CalorieData> _calorieData = [];

  // UI and chart variables
  final ScrollController _scrollController = ScrollController();
  final double _chartHeight = 300;
  final double _itemWidth = 60;
  double _currentMaxY = 1000;
  int _visibleStartIndex = 0;
  int _visibleEndIndex = 6;
  final int _visibleDays = 7;
  bool firstScroll = true;
  bool initialLoading = true;

  final double _theTop = 50;

  @override
  void initState() {
    super.initState();
    debugPrint('debugging calories burned: initState called');
    _scrollController.addListener(_scrollListener);

    _initializeData();
  }

  @override
  void dispose() {
    debugPrint('debugging calories burned: dispose called');
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    debugPrint('debugging calories burned: _initializeData started');
    await _checkApiAvailability();
    if (_apiAvailable) {
      debugPrint('debugging calories burned: API is available');
      await _checkPermissions();
      if (_hasCaloriesPermission) {
        debugPrint('debugging calories burned: has permissions, loading data');
        print(' debug getInitialMax: firstScroll is $firstScroll');

        await _loadMoreData();
      } else {
        debugPrint('debugging calories burned: no permissions');
      }
    } else {
      debugPrint('debugging calories burned: API not available');
    }
  }

  Future<void> _checkApiAvailability() async {
    try {
      debugPrint('debugging calories burned: checking API availability');
      _apiAvailable = await HealthConnectFactory.isAvailable();
      debugPrint('debugging calories burned: API available = $_apiAvailable');
      setState(() {});
    } catch (e) {
      debugPrint(
          'debugging calories burned: Error checking API availability: $e');
      _apiAvailable = false;
    }
  }

  Future<void> _checkPermissions() async {
    try {
      debugPrint('debugging calories burned: checking permissions');
      _hasCaloriesPermission = await HealthConnectFactory.hasPermissions(
        [HealthConnectDataType.TotalCaloriesBurned],
        readOnly: true,
      );
      debugPrint(
          'debugging calories burned: has permissions = $_hasCaloriesPermission');
      setState(() {});
    } catch (e) {
      debugPrint('debugging calories burned: Error checking permissions: $e');
      _hasCaloriesPermission = false;
    }
  }

  Future<Map<DateTime, double>> _fetchCaloriesInRange(
      DateTime start, DateTime end) async {
    final Map<DateTime, double> caloriesHistory = {};

    try {
      final response = await HealthConnectFactory.getRecord(
        startTime: start,
        endTime: end,
        type: HealthConnectDataType.TotalCaloriesBurned,
      ) as Map<String, dynamic>;

      final records = response['records'] as List<dynamic>;

      for (final record in records) {
        try {
          double calories = 0.0;
          if (record['energy'] != null &&
              record['energy']['kilocalories'] != null) {
            calories = record['energy']['kilocalories'].toDouble();
          }

          final startEpochSecond = record['startTime']['epochSecond'] as int;
          final startNano = record['startTime']['nano'] as int;

          final recordDate = DateTime.fromMillisecondsSinceEpoch(
            startEpochSecond * 1000 + (startNano / 1e6).round(),
          ).toLocal();

          final dateKey =
              DateTime(recordDate.year, recordDate.month, recordDate.day);

          caloriesHistory.update(
            dateKey,
            (existing) => existing + calories,
            ifAbsent: () => calories,
          );
        } catch (e) {
          debugPrint('Error processing record: $e');
        }
      }

      // Fill in missing dates with zero values (same as steps function)
      final daysInRange = end.difference(start).inDays;
      for (int i = 0; i <= daysInRange; i++) {
        final date = end.subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);

        if (!caloriesHistory.containsKey(dateKey)) {
          caloriesHistory[dateKey] = 0.0;
        }
      }

      return caloriesHistory;
    } catch (e) {
      debugPrint('Error fetching calories: $e');
      return {};
    }
  }

  List<CalorieData> _getCalorieDataList() {
    final sortedEntries = calories.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedEntries
        .map((entry) => CalorieData(
              date: entry.key,
              calories: entry.value,
              day: '${entry.key.day}/${entry.key.month}',
            ))
        .toList();
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);

    try {
      final startTime = DateTime.now()
          .subtract(Duration(days: (_currentPage + 1) * _pageSize));
      final endTime =
          DateTime.now().subtract(Duration(days: _currentPage * _pageSize));

      final newData = await _fetchCaloriesInRange(startTime, endTime);

      final sortedNewData = Map.fromEntries(
          newData.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));

      calories.addAll(sortedNewData);
      _calorieData = _getCalorieDataList();

      if (initialLoading) {
        if (_calorieData.isNotEmpty) {
          double max = 0;
          for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
            if (i >= 0 && i < _calorieData.length) {
              if (_calorieData[i].calories > max) {
                max = _calorieData[i].calories;
              }
            }
          }
          setState(() {
            _currentMaxY = _calculateUpMaxY(max);

            initialLoading = false;
          });
        }
      }

      setState(() {
        // Reset visible range to start from the beginning
        _currentPage++;
        _hasMoreData = newData.length >= _pageSize;
        _updateVisibleRange();
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double? _tryGetDouble(dynamic map, String key) {
    try {
      if (map is Map && map[key] != null) {
        return map[key].toDouble();
      }
    } catch (e) {}
    return null;
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
    _updateVisibleRange();
  }

  void _updateVisibleRange() {
    firstScroll = false;
    final scrollOffset = _scrollController.offset;

    _visibleStartIndex = (scrollOffset / _itemWidth).floor();
    _visibleEndIndex = _visibleStartIndex + _visibleDays - 1;

    if (_visibleEndIndex >= _calorieData.length) {
      _visibleEndIndex = _calorieData.length - 1;
    }

    if (_calorieData.isNotEmpty) {
      double max = 0;
      for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
        if (i >= 0 && i < _calorieData.length) {
          if (_calorieData[i].calories > max) {
            max = _calorieData[i].calories;
          }
        }
      }
      setState(() {
        _currentMaxY = _calculateUpMaxY(max);
      });
    }
  }

  double _calculateUpMaxY(double max) {
    if (max == 0) {
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

  double _calculateYInterval() {
    if (_currentMaxY == 0) return 10; // Avoid divide-by-zero

    // Step 1: Get the raw interval (for 6 values)
    double rawInterval = _currentMaxY / 5;

    // Step 2: Find the magnitude (power of 10)
    double magnitude = pow(10, (log(rawInterval) / ln10).floor()).toDouble();

    // Step 3: Normalize the raw interval by magnitude
    double normalized = rawInterval / magnitude;

    // Step 4: Choose the next interval based on the normalized value
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

  List<FlSpot> _generateSpots() {
    return List.generate(_calorieData.length, (index) {
      return FlSpot(
        index.toDouble(),
        _calorieData[index].calories,
      );
    });
  }

  LineTouchData _getLineTouchData() {
    return LineTouchData(
      enabled: true, // This is crucial
      touchTooltipData: LineTouchTooltipData(
        tooltipMargin: 10, // Add margin at the top
        fitInsideHorizontally: true,
        fitInsideVertically: false,
        showOnTopOfTheChartBoxArea:
            true, // Allow tooltip to go outside vertically
        getTooltipColor: (touchedSpot) {
          return Colors.white;
        },
        tooltipBorder: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1,
        ),
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) {
            final caloriesBurned = spot.y;

            return LineTooltipItem(
              '${caloriesBurned.toStringAsFixed(1)} kCal',
              TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            );
          }).toList();
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
      calories = {};
      _calorieData = [];
    });
    await _loadMoreData();
  }

// Method to redirect user to the store to download health connect
  Future<void> downloadHealthConnect() async {
    await StoreRedirect.redirect(
        androidAppId: "com.google.android.apps.healthdata");
  }

  Widget _buildPermissionPrompt({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  Widget handleErrorStates({
    required bool apiAvailable,
    required bool hasPermission,
    required ThemeData theme,
  }) {
    if (!apiAvailable) {
      return _buildPermissionPrompt(
        icon: Icons.download,
        title: "Health Connect Required",
        subtitle: "Tap to download the Health Connect app",
        actionText: "Download Now",
        onTap: downloadHealthConnect,
        theme: theme,
      );
    }

    if (!hasPermission) {
      return _buildPermissionPrompt(
        icon: Icons.lock_outline,
        title: "Permission Needed",
        subtitle: "Grant access to your burned calories data",
        actionText: "Grant Access",
        onTap: () => HealthConnectFactory.openHealthConnectSettings(),
        theme: theme,
      );
    }

    return const SizedBox(); // Return an empty widget if no errors
  }

  Future<void> getInitialMax() async {
    if (!firstScroll) return;
    if (_isLoading || !_hasMoreData) {
      return;
    }

    _isLoading = true;

    try {
      final startTime = DateTime.now()
          .subtract(Duration(days: (_currentPage + 1) * _pageSize));
      final endTime =
          DateTime.now().subtract(Duration(days: _currentPage * _pageSize));

      final newData = await _fetchCaloriesInRange(startTime, endTime);

      final sortedNewData = Map.fromEntries(
          newData.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));

      calories.addAll(sortedNewData);

      _calorieData = _getCalorieDataList();

      _currentPage++;
      _hasMoreData = newData.length >= _pageSize;

      if (_calorieData.isNotEmpty) {
        double max = 0;
        for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
          if (i >= 0 && i < _calorieData.length) {
            if (_calorieData[i].calories > max) {
              max = _calorieData[i].calories;
            }
          }
        }

        _currentMaxY = _calculateUpMaxY(max);
      }
    } catch (e) {
      debugPrint('ERROR - $e');
    } finally {
      _isLoading = false;
      firstScroll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!_apiAvailable || !_hasCaloriesPermission) {
      return handleErrorStates(
        apiAvailable: _apiAvailable,
        hasPermission: _hasCaloriesPermission,
        theme: theme,
      );
    }

    if (_calorieData.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (initialLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      'KCal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                // Fixed Y-axis
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
                                // Only show labels at interval points
                                final interval = _calculateYInterval();
                                if (value % interval != 0 || value == 0)
                                  return SizedBox();

                                return Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Text(
                                    value.toInt().toString(),
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
                // Scrollable chart content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _itemWidth * _calorieData.length,
                      height: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 13.0, right: 16.0, top: _theTop),
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: _currentMaxY,
                            lineTouchData: _getLineTouchData(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 != 0) return const SizedBox();

                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        '${_calorieData[value.toInt()].day}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    );
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                              topTitles: const AxisTitles(),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left: BorderSide(color: Colors.grey),
                                top: BorderSide(color: Colors.grey),
                                right: BorderSide(color: Colors.grey),
                                bottom: BorderSide(color: Colors.grey),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _generateSpots(),
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
        ),
        Padding(
          padding: EdgeInsets.only(left: 200.0),
          child: Text(
            'Days',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class CalorieData {
  final DateTime date;
  final double calories;
  final String day;

  CalorieData({
    required this.date,
    required this.calories,
    required this.day,
  });
}
