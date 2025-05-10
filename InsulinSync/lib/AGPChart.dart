import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'models/glucose_model.dart';
import 'services/user_service.dart';

class DailyGlucosePattern {
  final List<GlucoseReading> allReadings;

  DailyGlucosePattern({required this.allReadings});

  /// Step 1: Filter readings within the past [days] days
  List<GlucoseReading> filterReadings(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return allReadings.where((r) => r.time.isAfter(cutoffDate)).toList();
  }

  /// Step 2: Strip the date and keep only the time part
  List<GlucoseReading> stripDate(List<GlucoseReading> readings) {
    return readings.map((r) {
      return GlucoseReading(
          title: 'glucoseReading',
          reading: r.reading,
          time: DateTime(0, 1, 1, r.time.hour, r.time.minute),
          source: 'temp');
    }).toList();
  }

  /// Step 3: Group readings into 15-minute bins
  // In groupByTime, initialize all possible 15-minute buckets
  Map<TimeOfDay, List<double>> groupByTime(List<GlucoseReading> readings) {
    Map<TimeOfDay, List<double>> grouped = {};

    // Initialize all 96 possible 15-minute buckets in a day
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final bucket = TimeOfDay(hour: hour, minute: minute);
        grouped[bucket] = [];
      }
    }

    // Now populate with actual data
    for (var r in readings) {
      final bucket = TimeOfDay(
        hour: r.time.hour,
        minute: (r.time.minute ~/ 15) * 15,
      );
      grouped[bucket]!.add(r.reading);
    }

    return grouped;
  }

  /// Step 4: Calculate statistics per time bucket
  Map<TimeOfDay, GlucoseStats> calculateStats(
      Map<TimeOfDay, List<double>> groupedReadings) {
    Map<TimeOfDay, GlucoseStats> stats = {};

    groupedReadings.forEach((time, readings) {
      stats[time] = GlucoseStats(
        median: _median(readings),
        percentile25: _percentile(readings, 25),
        percentile75: _percentile(readings, 75),
      );
    });

    return stats;
  }

  /// Helper: Calculate median
  double _median(List<double> values) {
    if (values.isEmpty) return 0;
    values.sort();
    int middle = values.length ~/ 2;
    if (values.length % 2 == 1) {
      return values[middle];
    } else {
      return (values[middle - 1] + values[middle]) / 2;
    }
  }

  /// Helper: Calculate nth percentile
  double _percentile(List<double> values, double percentile) {
    if (values.isEmpty) return 0;
    values.sort();
    double index = (percentile / 100.0) * (values.length - 1);
    int lower = index.floor();
    int upper = index.ceil();
    if (lower == upper) {
      return values[lower];
    }
    return values[lower] + (values[upper] - values[lower]) * (index - lower);
  }
}

class GlucoseStats {
  final double median;
  final double percentile25;
  final double percentile75;

  GlucoseStats({
    required this.median,
    required this.percentile25,
    required this.percentile75,
  });
}

class AGPChartSyncfusion extends StatefulWidget {
  final Map<TimeOfDay, GlucoseStats> stats;

  const AGPChartSyncfusion({Key? key, required this.stats}) : super(key: key);

  @override
  _AGPChartSyncfusionState createState() => _AGPChartSyncfusionState();
}

class _AGPChartSyncfusionState extends State<AGPChartSyncfusion> {
  late List<TimeOfDay> sortedTimes;
  late List<ChartData> medianData;
  late List<RangeData> iqrData;
  late int minRange, maxRange;
  UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    minRange = 70;
    maxRange = 180;
    loadRange();
    _prepareChartData();
  }

  Future<void> loadRange() async {
    minRange = await userService.getUserAttribute('minRange');
    maxRange = await userService.getUserAttribute('maxRange');
    print('debug apg: min $minRange max $maxRange');
  }

  void _prepareChartData() {
    int _compareTimeOfDay(TimeOfDay a, TimeOfDay b) {
      if (a.hour != b.hour) return a.hour.compareTo(b.hour);
      return a.minute.compareTo(b.minute);
    }

    sortedTimes = widget.stats.keys.toList()..sort(_compareTimeOfDay);

    print('debug agp: print(sortedTimes) $sortedTimes');

    medianData = sortedTimes.map((time) {
      final x = time.hour + time.minute / 60.0; // Convert to hours
      return ChartData(x, widget.stats[time]!.median);
    }).toList();

    iqrData = sortedTimes.map((time) {
      final x = time.hour + time.minute / 60.0;
      return RangeData(x, widget.stats[time]!.percentile25,
          widget.stats[time]!.percentile75);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: loadRange(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          return SfCartesianChart(
            primaryXAxis: NumericAxis(
              title: AxisTitle(
                text: 'Time',
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              interval: 3,
              minimum: 0,
              maximum: 24,
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                int intValue = details.value.toInt();
                intValue = intValue % 24;
                String formattedLabel;

                if (intValue == 0) {
                  formattedLabel = '12AM';
                } else if (intValue == 12) {
                  formattedLabel = '12PM';
                } else if (intValue < 12) {
                  formattedLabel = '';
                } else {
                  formattedLabel = '';
                }

                return ChartAxisLabel(formattedLabel, TextStyle(fontSize: 10));
              },
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(
                text: 'mg/dL', // <-- X-axis title
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              minimum: 0,
              maximum: 350,
              majorGridLines: MajorGridLines(
                width: 1,
                color: Colors.grey.withOpacity(0.5),
              ),
              minorGridLines: MinorGridLines(
                width: 0.5,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            series: <CartesianSeries>[
              // Target range area (now with visible grid lines)
              RangeAreaSeries<RangeData, double>(
                animationDuration: 0,
                opacity: 0.3, // Use opacity property instead of color opacity
                dataSource: sortedTimes.map((time) {
                  final x = time.hour + time.minute / 60.0;
                  return RangeData(
                      x, (minRange).toDouble(), (maxRange).toDouble());
                }).toList(),
                xValueMapper: (data, _) => data.x,
                highValueMapper: (data, _) => data.high,
                lowValueMapper: (data, _) => data.low,
                color: const Color(
                    0xff4CAF50), // Solid color (opacity controlled by widget)
              ),
              // IQR Shaded Area
              RangeAreaSeries<RangeData, double>(
                animationDuration: 0,
                dataSource: iqrData,
                xValueMapper: (data, _) => data.x,
                highValueMapper: (data, _) => data.high,
                lowValueMapper: (data, _) => data.low,
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
              // Median Line
              LineSeries<ChartData, double>(
                animationDuration: 0,
                dataSource: medianData,
                xValueMapper: (data, _) => data.x,
                yValueMapper: (data, _) => data.y,
                color: Theme.of(context).primaryColor,
                width: 3,
              ),
            ],
            trackballBehavior: TrackballBehavior(
              enable: true,
              tooltipSettings: InteractiveTooltip(
                format: 'Time: {x}h\nGlucose: {y} mg/dL',
              ),
            ),
          );
        });
  }
}

class ChartData {
  final double x;
  final double y;
  ChartData(this.x, this.y);
}

class RangeData {
  final double x;
  final double low;
  final double high;
  RangeData(this.x, this.low, this.high);
}

class GlucoseAGPScreen extends StatefulWidget {
  int selectedDays;
  GlucoseAGPScreen({
    Key? key,
    required this.selectedDays,
  }) : super(key: key);
  @override
  _GlucoseAGPScreenState createState() => _GlucoseAGPScreenState();
}

class _GlucoseAGPScreenState extends State<GlucoseAGPScreen> {
  late int selectedDays;
  late Future<List<GlucoseReading>> _glucoseReadingsFuture;

  @override
  void initState() {
    super.initState();
    selectedDays = widget.selectedDays;
    _glucoseReadingsFuture = _loadGlucoseReadings();
  }

  @override
  void didUpdateWidget(covariant GlucoseAGPScreen oldWidget) {
    print('in didUpdateWidget ${widget.selectedDays}');
    print('in didUpdateWidget ${oldWidget.selectedDays}');
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDays != oldWidget.selectedDays) {
      setState(() {
        selectedDays = widget.selectedDays;
        _glucoseReadingsFuture = _loadGlucoseReadings();
      });
    }
  }

  Future<List<GlucoseReading>> _loadGlucoseReadings() async {
    UserService userService = UserService();
    var a = userService.getGlucoseReadings(source: 'libreCGM');
    return a;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GlucoseReading>>(
      future: _glucoseReadingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading data'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No data available'));
        }

        List<GlucoseReading> yourGlucoseList = snapshot.data!;
        final pattern = DailyGlucosePattern(allReadings: yourGlucoseList);
        final filtered = pattern.filterReadings(selectedDays);
        final stripped = pattern.stripDate(filtered);
        final grouped = pattern.groupByTime(stripped);
        final stats = pattern.calculateStats(grouped);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(height: 400, child: AGPChartSyncfusion(stats: stats)),
        );
      },
    );
  }
}
