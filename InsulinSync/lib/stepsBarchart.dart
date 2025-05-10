import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:store_redirect/store_redirect.dart';

class StepsBarchart extends StatefulWidget {
  const StepsBarchart({super.key});

  @override
  State<StepsBarchart> createState() => _StepsBarchartState();
}

class _StepsBarchartState extends State<StepsBarchart> {
  // State variables
  bool _apiAvailable = false;
  bool _hasStepsPermission = false;
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 30;
  int? _selectedBarIndex;

  Map<DateTime, int> steps = {};
  List<StepData> _stepData = [];

  // UI and responsive axis variables
  final ScrollController _scrollController = ScrollController();
  final double _barWidth = 20;
  final double _spacing = 30;
  // TODO change
  double _currentMaxY = 10000;
  int _visibleStartIndex = 0;
  int _visibleEndIndex = 6;
  final int _visibleDays = 7;

  bool initialLoading = true;

  double _theTop = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _checkApiAvailability();
    if (_apiAvailable) {
      await _checkPermissions();
      if (_hasStepsPermission) {
        await _loadMoreData();
      }
    }
  }

  Future<void> _checkApiAvailability() async {
    try {
      _apiAvailable = await HealthConnectFactory.isAvailable();
      setState(() {});
    } catch (e) {
      _apiAvailable = false;
    }
  }

  Future<void> _checkPermissions() async {
    try {
      _hasStepsPermission = await HealthConnectFactory.hasPermissions(
        [HealthConnectDataType.Steps],
        readOnly: true,
      );
      setState(() {});
    } catch (e) {
      _hasStepsPermission = false;
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);

    try {
      final startTime = DateTime.now()
          .subtract(Duration(days: (_currentPage + 1) * _pageSize));
      final endTime =
          DateTime.now().subtract(Duration(days: _currentPage * _pageSize));

      final newData = await _fetchStepsInRange(startTime, endTime);

      final sortedNewData = Map.fromEntries(
          newData.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
      steps.addAll(sortedNewData);
      _stepData = _getStepDataList();

      if (initialLoading) {
        if (_stepData.isNotEmpty) {
          double max = 0;
          for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
            if (i >= 0 && i < _stepData.length) {
              if (_stepData[i].steps > max) {
                max = _stepData[i].steps.toDouble();
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
        _currentPage++;
        _hasMoreData = newData.length >= _pageSize;
        _updateVisibleRange();
      });
    } catch (e) {
      debugPrint('Error loading more data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<DateTime, int>> _fetchStepsInRange(
      DateTime start, DateTime end) async {
    final Map<DateTime, int> stepsHistory = {};

    try {
      final response = await HealthConnectFactory.getRecord(
        startTime: start,
        endTime: end,
        type: HealthConnectDataType.Steps,
      ) as Map<String, dynamic>;

      final records = response['records'] as List<dynamic>;

      for (final record in records) {
        final count = record['count'] as int;
        final startEpochSecond = record['startTime']['epochSecond'] as int;
        final startNano = record['startTime']['nano'] as int;

        final recordDate = DateTime.fromMillisecondsSinceEpoch(
          startEpochSecond * 1000 + (startNano / 1e6).round(),
        ).toLocal(); // ensure local time

        final dateKey =
            DateTime(recordDate.year, recordDate.month, recordDate.day);

        stepsHistory.update(dateKey, (existing) => existing + count,
            ifAbsent: () => count);
      }

      final daysInRange = end.difference(start).inDays;
      for (int i = 0; i <= daysInRange; i++) {
        final date = end.subtract(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day); // normalized

        if (!stepsHistory.containsKey(dateKey)) {
          stepsHistory[dateKey] = 0;
        }
      }

      return stepsHistory;
    } catch (e) {
      debugPrint('Error fetching steps: $e');
      return {};
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
    _updateVisibleRange();
  }

  List<StepData> _getStepDataList() {
    final sortedEntries = steps.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedEntries
        .map((entry) => StepData(
              date: entry.key,
              steps: entry.value,
              day: '${entry.key.day}/${entry.key.month}',
            ))
        .toList();
  }

  void _updateVisibleRange() {
    final scrollOffset = _scrollController.offset;
    final itemWidth = _barWidth + _spacing;

    _visibleStartIndex = (scrollOffset / itemWidth).floor();
    _visibleEndIndex = _visibleStartIndex + _visibleDays - 1;

    if (_visibleEndIndex >= _stepData.length) {
      _visibleEndIndex = _stepData.length - 1;
    }

    if (_stepData.isNotEmpty) {
      double max = 0;
      for (int i = _visibleStartIndex; i <= _visibleEndIndex; i++) {
        if (i >= 0 && i < _stepData.length) {
          if (_stepData[i].steps > max) {
            max = _stepData[i].steps.toDouble();
          }
        }
      }
      setState(() {
        _currentMaxY = _calculateUpMaxY(max);
      });
    }
  }

  double _calculateUpMaxY(double max) {
    print('debug maxy: Starting calculation with max = $max');

    if (max == 0) {
      print('debug maxy: max is 0, returning 10');
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

    // Step 5: Calculate the final "nice" interval
    double niceInterval = niceNormalized * magnitude;

    debugPrint(
        'Y interval calculated as $niceInterval, with _currentMaxY as $_currentMaxY');
    return niceInterval;
  }

  List<BarChartGroupData> _generateBarGroups() {
    return List.generate(_stepData.length, (index) {
      final data = _stepData[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.steps.toDouble(),
            color: _selectedBarIndex == index
                ? Colors.green[100]
                : Theme.of(context).primaryColor,
            width: _barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
        showingTooltipIndicators: _selectedBarIndex == index ? [0] : [],
      );
    });
  }

  BarTouchData _getBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipMargin: 30, // Add margin at the top
        fitInsideHorizontally: true,
        fitInsideVertically: false,
        // showOnTopOfTheChartBoxArea:true,
        getTooltipColor: (touchedSpot) {
          return Colors.white;
        },
        // tooltipBgColor: Colors.white, // White background
        tooltipRoundedRadius: 4,
        tooltipBorder: BorderSide(
          color: Theme.of(context).primaryColor, // Primary color border
          width: 1,
        ),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${rod.toY.toInt()} steps',
            TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        },
      ),
      // handleBuiltInTouches: false,
      // touchCallback: (event, response) {
      //   if (response?.spot == null) return;

      //   final spot = response!.spot!;
      //   final barIndex = spot.touchedBarGroupIndex;

      //   if (event is FlTapUpEvent) {
      //     setState(() {
      //       _selectedBarIndex = barIndex;
      //     });
      //     _onBarClicked(barIndex);
      //   }
      // },
    );
  }

  void _onBarClicked(int barIndex) {
    if (barIndex >= 0 && barIndex < _stepData.length) {
      final steps = _stepData[barIndex].steps;
      final date = _stepData[barIndex].date;
      print('Clicked bar: ${date.day}/${date.month} - $steps steps');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${date.day}/${date.month}: $steps steps'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
      steps = {};
      _stepData = [];
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
    print(
        'Debug health connect in charts:STPES: apiAvailable:$apiAvailable  hasPermission:$hasPermission');
    if (!apiAvailable) {
      print('Debug health connect in charts:STPES: inside !apiavailable');

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
      print('Debug health connect in charts:STPES: inside !haspermission');
      return _buildPermissionPrompt(
        icon: Icons.lock_outline,
        title: "Permission Needed",
        subtitle: "Grant access to your step count data",
        actionText: "Grant Access",
        onTap: () => HealthConnectFactory.openHealthConnectSettings(),
        theme: theme,
      );
    }

    return const SizedBox(); // Return an empty widget if no errors
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(letterSpacing: 0);

    if (!_apiAvailable || !_hasStepsPermission) {
      return handleErrorStates(
        apiAvailable: _apiAvailable,
        hasPermission: _hasStepsPermission,
        theme: theme,
      );
    }
    print('Debug health connect in charts:STPES: 1');
    if (_stepData.isEmpty && _isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    print('Debug health connect in charts:STPES: 2');

    if (initialLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   // padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        //   padding: EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),

        //   child: Text(
        //     'Steps',
        //     style: Theme.of(context).textTheme.titleLarge?.copyWith(
        //           letterSpacing: 0,
        //         ),
        //   ),
        // ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollEndNotification) {
                _updateVisibleRange();
                print('Debug health connect in charts:STPES: 3');
              }
              return false;
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Y-axis title
                Transform.rotate(
                  angle: -3.14159 / 2, // 90 degrees in radians
                  child: Center(
                    child: Text(
                      'Steps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                // Fixed Y-axis
                SizedBox(
                  width: 48, // Increased width for better fit
                  height: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.only(top: _theTop),
                    child: BarChart(
                      BarChartData(
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            // axisNameWidget: Padding(
                            //   padding: EdgeInsets.only(
                            //       left: 8.0, bottom: 10), // Reduced padding
                            //   child: Text(
                            //     'Steps',
                            //     style: TextStyle(
                            //       fontWeight: FontWeight.bold,
                            //       fontSize: 16,
                            //     ),
                            //     textAlign: TextAlign.center,
                            //   ),
                            // ),
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _calculateYInterval(),
                              reservedSize: 40,
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
                            ),
                          ),
                          bottomTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: [],
                        maxY: _currentMaxY,
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
                      width: (_barWidth + _spacing) * _stepData.length,
                      height: double.infinity,
                      child: Padding(
                        padding: EdgeInsets.only(top: _theTop),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: _getBarTouchData(),
                            barGroups: _generateBarGroups(),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 &&
                                        index < _stepData.length) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          top: 8.0,
                                          left: index == 0 ? 15.0 : 0.0,
                                        ),
                                        child: Text(
                                          _stepData[index].day,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                  reservedSize: 30,
                                ),
                              ),
                              leftTitles: const AxisTitles(),
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left: BorderSide(
                                    color: Colors.grey), // Re-added left border
                                top: BorderSide(color: Colors.grey),
                                right: BorderSide(color: Colors.grey),
                                bottom: BorderSide(color: Colors.grey),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                            ),
                            maxY: _currentMaxY,
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

class StepData {
  final DateTime date;
  final int steps;
  final String day;

  StepData({
    required this.date,
    required this.steps,
    required this.day,
  });
}
