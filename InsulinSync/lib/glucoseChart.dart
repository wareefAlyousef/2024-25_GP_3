// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:insulin_sync/models/meal_model.dart';
import 'package:intl/intl.dart';

import '../models/glucose_model.dart';
import '../models/insulin_model.dart';
import '../models/workout_model.dart';
import 'excercise.dart';
import 'models/note_model.dart';
import 'services/user_service.dart';

//  A custom dot painter for rendering event dots on a graph.
class EventDotPainter extends FlDotPainter with EquatableMixin {
  final ui.Image image;
  final double size;

  EventDotPainter({
    required this.image,
    required this.size,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    final double imageSize = size * 0.5;
    final Offset imageOffset = offsetInCanvas - const Offset(0, 20);

    paintImage(
      canvas: canvas,
      image: image,
      rect: Rect.fromCenter(
          center: imageOffset, width: imageSize, height: imageSize),
      fit: BoxFit.fill,
    );
  }

  @override
  Size getSize(FlSpot spot) => Size(size, size);

  @override
  Color get mainColor => Colors.transparent;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => this;

  @override
  List<Object?> get props => [image, size];
}

class timeLabel {
  DateTime time;
  timeLabel({
    required this.time,
  });
}

Future<ui.Image> loadImage(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);
  final Completer<ui.Image> completer = Completer();
  ui.decodeImageFromList(data.buffer.asUint8List(), completer.complete);
  return completer.future;
}

// Method to get workout sessions from health connect
Future<List<Workout>> fetchWorkouts() async {
  try {
    var startTime = DateTime.now().subtract(const Duration(days: 100));
    var endTime = DateTime.now();
    var val = await HealthConnectFactory.getRecord(
      startTime: startTime,
      endTime: endTime,
      type: HealthConnectDataType.ExerciseSession,
    ) as Map<String, dynamic>;

    List<Workout> workouts = [];

    if (val.containsKey('records') && val['records'] is List) {
      var records = val['records'] as List;

      for (var record in records) {
        DateTime start = DateTime.fromMillisecondsSinceEpoch(
          record['startTime']['epochSecond'] * 1000,
        );
        DateTime end = DateTime.fromMillisecondsSinceEpoch(
          record['endTime']['epochSecond'] * 1000,
        );

        double duration = end.difference(start).inMinutes.toDouble();
        int ceilingMinutes = duration.ceil().toInt();

        int type = record['exerciseType'];
        String title = ExerciseConstants.getExerciseTypeString(type);

        workouts.add(
          Workout(
            title: title,
            time: start,
            intensity: null,
            duration: ceilingMinutes,
            source: "Health Connect",
          ),
        );
      }
    }

    return workouts;
  } catch (e) {
    return [];
  }
}

class GlucoseChart extends StatefulWidget {
  final DateTime specificDate;
  const GlucoseChart({Key? key, required this.specificDate}) : super(key: key);

  @override
  _GlucoseChartState createState() => _GlucoseChartState();
}

class _GlucoseChartState extends State<GlucoseChart> {
  DateTime now = DateTime.now();
  // Define the start and end times for the first 12 hours and the last 12 hours
  late final first12Start;
  late final first12End;

  late final last12Start;
  late final last12End;

  List<GlucoseReading> glucoseEntries = [];
  List<InsulinDosage> insulinEntries = [];
  List<Workout> localWorkoutEntries = [];
  List<Workout> healthConnectWorkoutEntries = [];

  UserService userService = UserService();

  late Future<List<GlucoseReading>> glucoseList;
  late Future<List<InsulinDosage>> insulinList;
  late Future<List<meal>> mealList;
  late Future<List<Workout>> localWorkoutList;
  late Future<List<Workout>> healthConnectWorkoutList;

  late List<dynamic> combinedEntries;
  late Map<String, List<dynamic>> groupedEntries;
  ui.Image? insulinIcon;
  ui.Image? workoutIcon;
  ui.Image? mealIcon;
  int? minRange, maxRange;

  Future<void> loadImages() async {
    final ui.Image insulinImage = await loadImage('images/insulinIcon.png');
    final ui.Image workoutImage = await loadImage('images/workoutIcon.png');
    final ui.Image mealImage = await loadImage('images/mealIcon.png');

    insulinIcon = insulinImage;
    workoutIcon = workoutImage;
    mealIcon = mealImage;
  }

  // Method to retrive the user's normal range from the database
  Future<void> loadRange() async {
    minRange = await userService.getUserAttribute('minRange');
    maxRange = await userService.getUserAttribute('maxRange');
  }

// method to filters a list of entries to include only those that fall within a specified date range.
  List<dynamic> filterEntriesForSpecificDate(
      List<dynamic> entries, DateTime start, DateTime end) {
    return entries.where((entry) {
      DateTime entryTimestamp = entry.time;

      return ((entryTimestamp.isAfter(start) && entryTimestamp.isBefore(end)) ||
          entryTimestamp.isAtSameMomentAs(start));
    }).toList();
  }

// Method to calculates the number of minutes between two DateTime objects.
  double minutesSinceTime(DateTime dateTime, DateTime referenceTime) {
    Duration difference = dateTime.difference(referenceTime);
    return difference.inMinutes.toDouble();
  }

// Method to converts a total number of minutes into a formatted time string (HH:mm).
  String timeFromMinutes(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void getInitialPage() {
    DateTime now = DateTime.now();
    DateTime first12Start = DateTime(now.year, now.month, now.day);
    DateTime first12End = first12Start.add(const Duration(hours: 12));
    DateTime last12Start = first12End;
    DateTime last12End = last12Start.add(const Duration(hours: 12));

    if (now.isAfter(first12Start) && now.isBefore(first12End)) {
      _pageController = PageController(initialPage: 0);
    } else if (now.isAfter(last12Start) && now.isBefore(last12End)) {
      _pageController = PageController(initialPage: 1);
    } else {
      // Default to the first page if for any reason the current time doesn't match
      _pageController = PageController(initialPage: 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    glucoseList = userService.getGlucoseReadings(source: 'libreCGM');
    insulinList = userService.getInsulinDosages();
    mealList = userService.getMeal();
    localWorkoutList = userService.getWorkouts();
    healthConnectWorkoutList = fetchWorkouts();

    loadImages();
    loadRange();

    getInitialPage();

    DateTime now = DateTime.now();
    first12Start = DateTime(
        now.year, now.month, now.day, 0, 0, 0, 0); // Start at 12:00 AM today
    first12End = DateTime(now.year, now.month, now.day, 11, 59, 59,
        999); // End at 11:59:59.999 AM today

    last12Start = DateTime(
        now.year, now.month, now.day, 12, 0, 0, 0); // Start at 12:00 PM today
    last12End = DateTime(now.year, now.month, now.day, 23, 59, 59,
        999); // End at 11:59:59.999 PM today
  }

  @override
  void didUpdateWidget(covariant GlucoseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    glucoseList = userService.getGlucoseReadings(source: 'libreCGM');
    insulinList = userService.getInsulinDosages();
    mealList = userService.getMeal();
    localWorkoutList = userService.getWorkouts();
    healthConnectWorkoutList = fetchWorkouts();
  }

  late final PageController _pageController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<List<meal>>(
            future: mealList,
            builder: (context, mealSnapshot) {
              return FutureBuilder<List<InsulinDosage>>(
                future: insulinList,
                builder: (context, insulinSnapshot) {
                  return FutureBuilder<List<Workout>>(
                    future: localWorkoutList,
                    builder: (context, workoutSnapshot) {
                      return FutureBuilder<List<GlucoseReading>>(
                        future: glucoseList,
                        builder: (context, glucoseSnapshot) {
                          return FutureBuilder<List<Workout>>(
                            future: healthConnectWorkoutList,
                            builder: (context, workoutSnapshotHealth) {
                              if (insulinSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  workoutSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  workoutSnapshotHealth.connectionState ==
                                      ConnectionState.waiting ||
                                  glucoseSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  mealSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (insulinSnapshot.hasError ||
                                  workoutSnapshot.hasError ||
                                  glucoseSnapshot.hasError ||
                                  mealSnapshot.hasError) {
                                return const Center(
                                    child: Text('Error loading data'));
                              }

                              List<GlucoseReading> glucoseEntries = [];
                              List<InsulinDosage> insulinEntries = [];
                              List<meal> mealEntries = [];
                              List<Workout> localWorkoutEntries = [];
                              List<Workout> healthConnectWorkoutEntries = [];

                              insulinEntries = insulinSnapshot.data ?? [];
                              mealEntries = mealSnapshot.data ?? [];
                              localWorkoutEntries = workoutSnapshot.data ?? [];
                              healthConnectWorkoutEntries =
                                  workoutSnapshotHealth.data ?? [];
                              glucoseEntries = glucoseSnapshot.data ?? [];

                              print('glucoseSnapshot ${glucoseSnapshot.data}');

                              combinedEntries = [
                                ...insulinEntries,
                                ...localWorkoutEntries,
                                ...healthConnectWorkoutEntries,
                                ...glucoseEntries,
                                ...mealEntries
                              ];

                              return Stack(
                                children: <Widget>[
                                  AspectRatio(
                                    aspectRatio: 0.8,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: FutureBuilder<dynamic>(
                                        future: userService
                                            .getUserAttribute('token'),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Center(
                                                child:
                                                    Text('Error: ${snapshot}'));
                                          } else if (snapshot.hasData) {
                                            List<dynamic> firstEntries =
                                                filterEntriesForSpecificDate(
                                                    combinedEntries,
                                                    first12Start,
                                                    first12End);

                                            List<dynamic> lastEntries =
                                                filterEntriesForSpecificDate(
                                                    combinedEntries,
                                                    last12Start,
                                                    last12End);

                                            return showGlucoseChartColumn(
                                                firstEntries, lastEntries);
                                          } else {
                                            List<dynamic> firstEntries =
                                                filterEntriesForSpecificDate(
                                                    combinedEntries,
                                                    first12Start,
                                                    first12End);

                                            List<dynamic> lastEntries =
                                                filterEntriesForSpecificDate(
                                                    combinedEntries,
                                                    last12Start,
                                                    last12End);
                                            return showGlucoseChartColumn(
                                                firstEntries, lastEntries);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            }),
      ],
    );
  }

  Column showGlucoseChartColumn(
      List<dynamic> firstEntries, List<dynamic> lastEntries) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Container(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {},
              children: [
                // First page - First 12 hours

                Padding(
                  padding: const EdgeInsets.only(top: 90, right: 15),
                  child: LineChart(
                      mainData(firstEntries, first12Start, first12End)),
                ),

                // Second page - Last 12 hours
                Padding(
                  padding: const EdgeInsets.only(top: 90, right: 15),
                  child:
                      LineChart(mainData(lastEntries, last12Start, last12End)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildCircleIndicator(0),
            buildCircleIndicator(1),
          ],
        ),
      ],
    );
  }

  Widget buildCircleIndicator(int pageIndex) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double currentPage = _pageController.hasClients
            ? _pageController.page ?? _pageController.initialPage.toDouble()
            : _pageController.initialPage.toDouble();

        bool isSelected = (currentPage.round() == pageIndex);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Container(
            width: isSelected ? 12 : 8,
            height: isSelected ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  LineChartData mainData(
    List<dynamic> combinedEntries,
    DateTime start,
    DateTime end,
  ) {
    double mealY = 435;
    double workoutY = 390;
    double insulinY = 345;

    List<FlSpot> glucoseSpots = [];
    List<FlSpot> eventSpots = [];
    List<FlSpot> labelsSpots = [];

    List<dynamic> allSpots = combinedEntries;

    try {
      // Generate all hours between start and end
      List<DateTime> hours = [];
      for (DateTime currentTime = start;
          currentTime.isBefore(end);
          currentTime = currentTime.add(const Duration(minutes: 1))) {
        hours.add(currentTime);
      }

      // Pre-populate allSpots with the hours
      for (var hour in hours) {
        timeLabel t = timeLabel(time: hour);
        allSpots.add(t);
      }

      allSpots.sort((b, a) => b.time.compareTo(a.time));

      DateTime lastGlucose = start;

      for (var entry in allSpots) {
        if (entry is GlucoseReading) {
          if (lastGlucose.difference(entry.time).inMinutes.abs() >= 20) {
            glucoseSpots.add(FlSpot.nullSpot);
          }
          glucoseSpots
              .add(FlSpot(minutesSinceTime(entry.time, start), entry.reading));
          lastGlucose = entry.time;
        } else if (entry is InsulinDosage) {
          double yValue = insulinY; // Fixed y-value for insulin events
          eventSpots.add(FlSpot(minutesSinceTime(entry.time, start), yValue));
        } else if (entry is Workout) {
          double yValue = workoutY; // Fixed y-value for workout events
          eventSpots.add(FlSpot(minutesSinceTime(entry.time, start), yValue));
        } else if (entry is meal) {
          double yValue = mealY; // Fixed y-value for meal events
          eventSpots.add(FlSpot(minutesSinceTime(entry.time, start), yValue));
        } else if (entry is timeLabel) {
          labelsSpots.add(FlSpot(minutesSinceTime(entry.time, start), 0));
        }
      }
    } catch (e, stack) {}

    final eventsLineChartBarData = LineChartBarData(
      showingIndicators: [],
      spots: eventSpots,
      isCurved: false,
      color: Theme.of(context).primaryColor,
      barWidth: 0,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          ui.Image? img;
          if (spot.y == insulinY) {
            img = insulinIcon;
          } else if (spot.y == workoutY) {
            img = workoutIcon;
          } else if (spot.y == mealY) {
            img = mealIcon;
          }
          return EventDotPainter(
            image: img!,
            size: 30.0,
          );
        },
      ),
    );

    final glucoseLineChartBarData = LineChartBarData(
        spots: glucoseSpots,
        isCurved: true,
        color: Theme.of(context).primaryColor,
        barWidth: 2,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 0,
              color: Colors.blue,
              strokeWidth: 0,
              strokeColor: Colors.white,
            );
          },
        ));

    final labelsLineChartBarData = LineChartBarData(
      spots: labelsSpots,
      isCurved: false,
      color: Colors.transparent,
      barWidth: 0,
      dotData: const FlDotData(
        show: false,
      ),
    );

    List<LineTooltipItem?> customLineTooltipItem(
        List<LineBarSpot> touchedSpots) {
      final textStyle = TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );

      List<LineTooltipItem?> toolTips = [];
      bool hasBarIndex0 = touchedSpots.any((spot) => spot.barIndex == 0);
      bool hasBarIndex1 = touchedSpots.any((spot) => spot.barIndex == 1);
      bool hasBarIndex2 = touchedSpots.any((spot) => spot.barIndex == 2);

      List<LineBarSpot> glucoseSpots =
          touchedSpots.where((spot) => spot.barIndex == 0).toList();

      // only show a tooltip is the spot belongs to glucose reading
      if (hasBarIndex0) {
        final now = DateTime.now();

        bool isFirstHalf =
            DateTime(now.year, now.month, now.day, 0, 0) == start;
        String time = "";
        double y = 0, x = 0;
        for (var spot in glucoseSpots) {
          y = spot.y;
          x = spot.x;
          if (isFirstHalf)
            time = timeFromMinutes(x.toInt());
          else
            time = timeFromMinutes(x.toInt() + 720);
        }
        toolTips.add(LineTooltipItem("$y mg/dL\nAt $time", textStyle));
      }

      if (hasBarIndex1) {
        toolTips.add(null);
      }

      if (hasBarIndex2) {
        toolTips.add(null);
      }
      return toolTips;
    }

    final myLineTouchData = LineTouchData(
      touchSpotThreshold: 20,
      touchTooltipData: LineTouchTooltipData(
        tooltipBorder: BorderSide(
          color: Theme.of(context).primaryColor,
          width: 1,
          style: BorderStyle.solid,
        ),
        fitInsideHorizontally: true,
        showOnTopOfTheChartBoxArea: true,
        getTooltipColor: (touchedSpot) {
          return Colors.white;
        },
        tooltipMargin: -20,
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return customLineTooltipItem(touchedSpots);
        },
      ),
      getTouchLineEnd: (barData, spotIndex) {
        if (barData != glucoseLineChartBarData) {
          return 0;
        } else {
          return barData.spots[spotIndex].y;
        }
      },
      getTouchLineStart: (barData, spotIndex) {
        if (barData != glucoseLineChartBarData) {
          return 0;
        } else {
          return -double.infinity;
        }
      },
      getTouchedSpotIndicator: (barData, spotIndexes) {
        return spotIndexes.map((index) {
          if (barData != glucoseLineChartBarData) {
            return null;
          }

          return TouchedSpotIndicatorData(
              FlLine(
                color: Theme.of(context).primaryColor,
                strokeWidth: 10,
              ),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 10,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 10,
                    strokeColor: Colors.black,
                  );
                },
              ));
        }).toList();
      },
      enabled: true,
    );

    return LineChartData(
      rangeAnnotations: RangeAnnotations(
        horizontalRangeAnnotations: [
          HorizontalRangeAnnotation(
              y1: (minRange ?? 70).toDouble(),
              y2: (maxRange ?? 180).toDouble(),
              color: const Color(0xffCCE5CC)),
        ],
      ),
      lineTouchData: myLineTouchData,
      gridData: const FlGridData(show: true, verticalInterval: 60),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: const Padding(
            padding: EdgeInsets.only(left: 50.0),
            child: Text(
              'Time',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          axisNameSize: 18,
          sideTitles: SideTitles(
            reservedSize: 60,
            showTitles: true,
            interval: 180,
            getTitlesWidget: (double value, TitleMeta meta) {
              // Hours that will be shown in x-axis are 3,6 and 9 both am and pm
              List<int> targetTimesInMinutes = [
                180,
                360,
                540,
              ];
              if (targetTimesInMinutes.contains(value.toInt())) {
                int minutes = value.toInt();
                if (start != first12Start) {
                  // adding 12 hours if it belongs to second half of the day
                  minutes += 720;
                }
                String time = timeFromMinutes(minutes);
                return Padding(
                  padding: const EdgeInsets.only(left: 40.0),
                  child: Transform.rotate(angle: -0.785398, child: Text(time)),
                );
              }

              return Container();
            },
          ),
        ),
        leftTitles: const AxisTitles(
          axisNameWidget: Padding(
            padding: EdgeInsets.only(left: 50.0),
            child: Text(
              'mg/dL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          axisNameSize: 25,
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
          show: true, border: Border.all(color: const Color(0xff37434d))),
      minX: 0,
      minY: 0,
      maxY: 350,
      lineBarsData: [
        glucoseLineChartBarData,
        eventsLineChartBarData,
        labelsLineChartBarData,
      ],
    );
  }
}
