import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'models/glucose_model.dart';
import 'services/user_service.dart';

class TimeInRange extends StatefulWidget {
  final DateTime date;

  const TimeInRange({Key? key, required this.date}) : super(key: key);

  @override
  _TimeInRangeState createState() => _TimeInRangeState();
}

class _TimeInRangeState extends State<TimeInRange> {
  bool _isLoading = true;
  Map<String, double> _data = {'Low': 0, 'In-Range': 0, 'High': 0};
  UserService userService = UserService();

  @override
  void initState() {
    super.initState();

    _fetchGlucoseData();
  }

  @override
  void didUpdateWidget(TimeInRange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.date != widget.date) {
      _fetchGlucoseData();
    }
  }

  Future<void> _fetchGlucoseData() async {
    setState(() {
      _isLoading = true;
    });

    if (userService.currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final List<GlucoseReading> allReadings =
          await userService.getGlucoseReadings();

      // Filter readings for the selected date
      DateTime startOfDay =
          DateTime(widget.date.year, widget.date.month, widget.date.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      final filteredReadings = allReadings.where((reading) {
        return reading.time.isAfter(startOfDay) &&
            reading.time.isBefore(endOfDay);
      }).toList();

      print('Filtered readings count: ${filteredReadings.length}');

      // Categorize readings
      int low = 0, inRange = 0, high = 0;
      for (var reading in filteredReadings) {
        print(
            'Processing reading - value: ${reading.reading}, time: ${reading.time}');
        if (reading.reading < 70) {
          low++;
        } else if (reading.reading >= 70 && reading.reading <= 180) {
          inRange++;
        } else {
          high++;
        }
      }

      int total = low + inRange + high;
      print(
          'Categorized - Low: $low, In-Range: $inRange, High: $high, Total: $total');

      if (total > 0) {
        _data['Low'] = (low / total) * 100;
        _data['In-Range'] = (inRange / total) * 100;
        _data['High'] = (high / total) * 100;
        print(
            'Calculated percentages - Low: ${_data['Low']}%, In-Range: ${_data['In-Range']}%, High: ${_data['High']}%');
      } else {
        _data = {'Low': 0, 'In-Range': 0, 'High': 0};
        print('No readings found, resetting to 0%');
      }
    } catch (e) {
      print('Error fetching glucose data: $e');
      _data = {'Low': 0, 'In-Range': 0, 'High': 0};
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: _isLoading
          ? _buildLoadingState()
          : _data.values.every((value) => value == 0)
              ? _buildNoDataState()
              : _buildChartWithData(),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildNoDataState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0.0, 20),
            child: Text(
              'No glucose data available for ${widget.date.toString().split(' ')[0]}.',
              style: TextStyle(
                fontSize: 14.7,
                color: const Color.fromARGB(255, 123, 123, 123),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartWithData() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: AspectRatio(
                  aspectRatio: 1.4,
                  child: PieChart(
                    PieChartData(
                      sections: _data.entries.map((entry) {
                        return PieChartSectionData(
                          title: '',
                          value: entry.value,
                          color: entry.key == 'Low'
                              ? Color.fromARGB(255, 194, 43, 98)
                              : entry.key == 'In-Range'
                                  ? Color.fromARGB(255, 71, 169, 140)
                                  : Color.fromARGB(255, 244, 165, 52),
                          radius: 28,
                        );
                      }).toList(),
                      centerSpaceRadius: 0,
                      sectionsSpace: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 24.0),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDataPoint(
                        'Low', _data['Low']!, Color.fromARGB(255, 194, 43, 98)),
                    _buildDataPoint('In-Range', _data['In-Range']!,
                        Color.fromARGB(255, 71, 169, 140)),
                    _buildDataPoint('High', _data['High']!,
                        Color.fromARGB(255, 244, 165, 52)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataPoint(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 6.0),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14.0,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
