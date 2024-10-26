import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insulin_sync/AddCarb.dart';
import 'package:insulin_sync/AddInsulin.dart';
import 'package:insulin_sync/history.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../excercise.dart';
import '../models/carbohydrate_model.dart';
import '../models/workout_model.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../models/glucose_model.dart';
import 'AddGlucose.dart';
import 'AddNote.dart';
import 'AddPhysicalActivity.dart';
import 'services/user_service.dart';
import 'models/note_model.dart';
import 'models/insulin_model.dart';
import '../widgets.dart';
import 'package:store_redirect/store_redirect.dart';

import 'splash.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Timer? _timer;
  bool apiAvailable = false;

  int? beatsPerMinute;
  DateTime? timfOfLastBeat;
  bool hasHeartPermission = false;

  int? steps;
  DateTime? timfOfLastStep;
  bool hasStepsPermission = false;

  double? burned;
  DateTime? timfOfLastBurned;
  bool hasBurnedPermission = false;

  List<HealthConnectDataType> types = [
    HealthConnectDataType.ExerciseSession,
    HealthConnectDataType.Steps,
    HealthConnectDataType.HeartRate,
    HealthConnectDataType.TotalCaloriesBurned
  ];

  UserService userService = UserService();

  void initState() {
    super.initState();

    try {
      _requestHealthPermissions();
    } catch (e) {}

    try {
      _refreshData();
    } catch (e) {}

    try {
      _startTimer();
    } catch (e) {}
  }

  @override
  void didUpdateWidget(covariant Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshData();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(minutes: 10), (timer) {
      try {
        _refreshData();
      } catch (e) {}
    });
  }

  Future<bool> isApiAvailable() async {
    try {
      var result = await HealthConnectFactory.isAvailable();
      apiAvailable = result;

      return result;
    } catch (e) {
      return false;
    }
  }

  // Method to redirect to Play Store
  Future<void> downloadHealthConnect() async {
    await StoreRedirect.redirect(
        androidAppId: "com.google.android.apps.healthdata");
  }

  // Method to show info dialog
  void _showInfo(BuildContext context, String title, Widget body) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          content: body,
          actions: [
            Center(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Color(0xff023b96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(100, 44),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Padding buildCustomPadding(String title, Widget content) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5.0,
              color: Color(0x230E151B),
              offset: Offset(0.0, 2.0),
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 13.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 19.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

// Method to confirm sign out
  Future<void> _showConfirmationDialog(AuthService authService) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color(0xFFFFDCDC),
                    child: Icon(
                      Icons.logout,
                      size: 100,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Are You Sure You Want To Sign Out?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop(true);

                            await authService.signOut();

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OnboardingWidget()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Sign out',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

// Methods to show options for the floating button
  void _showOptions(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          behavior: HitTestBehavior.opaque,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Wrap(
                children: [
                  ListTile(
                    leading: Icon(Icons.note, color: primaryColor),
                    title: Text('Note', style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddNote()),
                      ).then((onValue) {
                        _refreshData();
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fastfood, color: primaryColor),
                    title: Text('Carb', style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddCarb()),
                      ).then((onValue) {
                        _refreshData();
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fitness_center, color: primaryColor),
                    title: Text('Physical Activity',
                        style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddPhysicalActivity()),
                      ).then((onValue) {
                        _refreshData();
                      });
                    },
                  ),
                  ListTile(
                    leading:
                        Icon(FontAwesomeIcons.syringe, color: primaryColor),
                    title: Text('Insulin Dosage',
                        style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddInsulin()),
                      ).then((onValue) {
                        _refreshData();
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.bloodtype, color: primaryColor),
                    title: Text('Glucose Reading',
                        style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddGlucose()),
                      ).then((onValue) {
                        _refreshData();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Method to determine of given day matches today's date
  bool isToday(DateTime date) {
    DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

// Method to check if permission to access a specific data type is garnted
  Future<bool> hasPermission(List<HealthConnectDataType> type) async {
    try {
      var permission = await HealthConnectFactory.hasPermissions(
        type,
        readOnly: true,
      );

      return permission;
    } catch (e) {
      return false;
    }
  }

// Method to retrive heart rate data
  Future<void> fetchHeart() async {
    try {
      var startTime = DateTime.now().subtract(const Duration(days: 1));
      var endTime = DateTime.now();
      var val = await HealthConnectFactory.getRecord(
        startTime: startTime,
        endTime: endTime,
        type: HealthConnectDataType.HeartRate,
      ) as Map<String, dynamic>;

      var records = val['records'] as List<dynamic>;

      if (records.isNotEmpty) {
        var lastRecord = records.last;

        var samples = lastRecord['samples'] as List<dynamic>;

        if (samples.isNotEmpty) {
          var lastSample = samples.last;

          beatsPerMinute = lastSample['beatsPerMinute'];
          var timeEpoch = lastSample['time']['epochSecond'] as int;

          var dateTime = DateTime.fromMillisecondsSinceEpoch(timeEpoch * 1000);

          DateTime specificDateTime = DateTime(2024, 10, 15, 00, 59);

          if (specificDateTime.difference(dateTime).inMinutes > 20) {
            beatsPerMinute = null;
          } else {
            var formattedTime = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
            beatsPerMinute = lastSample['beatsPerMinute'];
          }
        } else {
          beatsPerMinute = null;
        }
      } else {
        beatsPerMinute = null;
      }
    } catch (e) {}
  }

// Method to fetch steps data
  Future<void> fetchSteps() async {
    try {
      var startTime = DateTime.now().subtract(const Duration(days: 1));
      var endTime = DateTime.now();
      var val = await HealthConnectFactory.getRecord(
        startTime: startTime,
        endTime: endTime,
        type: HealthConnectDataType.Steps,
      ) as Map<String, dynamic>;

      var records = val['records'] as List<dynamic>;

      if (records.isNotEmpty) {
        var lastRecord = records.last;

        var retrivedSteps = lastRecord['count'];

        var startEpochSecond = lastRecord['startTime']['epochSecond'] as int;
        var startNano = lastRecord['startTime']['nano'] as int;
        var endEpochSecond = lastRecord['endTime']['epochSecond'] as int;
        var endNano = lastRecord['endTime']['nano'] as int;

        var startTime = DateTime.fromMillisecondsSinceEpoch(
            startEpochSecond * 1000 + (startNano / 1e6).round());
        var endTime = DateTime.fromMillisecondsSinceEpoch(
            endEpochSecond * 1000 + (endNano / 1e6).round());

        if (isToday(startTime)) {
          steps = retrivedSteps;
        } else {
          steps = null;
        }
      }
    } catch (e) {}
  }

// Method to fetch burned calories
  Future<double> fetchBurnedfromHealth() async {
    try {
      var startTime = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
      var endTime = DateTime.now();
      var val = await HealthConnectFactory.getRecord(
        startTime: startTime,
        endTime: endTime,
        type: HealthConnectDataType.TotalCaloriesBurned,
      ) as Map<String, dynamic>;

      var val2 = await HealthConnectFactory.getRecord(
        startTime: startTime,
        endTime: endTime,
        type: HealthConnectDataType.ActiveCaloriesBurned,
      ) as Map<String, dynamic>;

      double totalCalories = 0.0;
      var records = val['records'] as List<dynamic>;

      for (var record in records) {
        DateTime startTime2 = DateTime.fromMillisecondsSinceEpoch(
            record['startTime']['epochSecond'] * 1000);
        DateTime endTime2 = DateTime.fromMillisecondsSinceEpoch(
            record['endTime']['epochSecond'] * 1000);

        if (record['energy'] != null &&
            record['energy']['kilocalories'] != null) {
          totalCalories += record['energy']['kilocalories'];
        }
      }

      return totalCalories;
    } catch (e) {
      return 0;
    }
  }

  Future<void> getTotalBurnedCalories() async {
    burned = await fetchBurnedfromHealth();
  }

// Method to get workout sessions from health connect
  Future<List<Workout>> fetchWorkouts() async {
    try {
      var startTime = DateTime.now().subtract(const Duration(days: 100));
      var endTime = DateTime.now();
      var val = await HealthConnectFactory.getRecord(
          startTime: startTime,
          endTime: endTime,
          type: HealthConnectDataType.ExerciseSession) as Map<String, dynamic>;

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

  // Method to request Permissions for data types

  Future<void> _requestHealthPermissions() async {
    try {
      var result = await HealthConnectFactory.requestPermissions(
        types,
        readOnly: true,
      );
    } catch (e) {}
  }

  Future<void> _refreshData() async {
    try {
      apiAvailable = await isApiAvailable();
      if (!apiAvailable) {
        return;
      }
      hasHeartPermission =
          await hasPermission([HealthConnectDataType.HeartRate]);

      hasStepsPermission = await hasPermission([HealthConnectDataType.Steps]);

      hasBurnedPermission =
          await hasPermission([HealthConnectDataType.TotalCaloriesBurned]);
      if (hasHeartPermission) {
        await fetchHeart();
      } else {
        beatsPerMinute = null;
      }

      if (hasStepsPermission) {
        await fetchSteps();
      } else {
        steps = null;
      }

      if (hasBurnedPermission) {
        await getTotalBurnedCalories();
      } else {
        burned = null;
      }
      setState(() {});
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return GestureDetector(
        child: Scaffold(
            backgroundColor: Color(0xFFf1f4f8),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              onPressed: () => _showOptions(context),
              child: Icon(Icons.add),
            ),
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: SafeArea(
                  top: true,
                  child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(7.0, 7.0, 7.0, 0.0),
                      child: SingleChildScrollView(
                          child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                            Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Container(
                                    width: 357.0,
                                    height: 50.0,
                                    child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Today',
                                            style: Theme.of(context)
                                                .textTheme
                                                .displaySmall
                                                ?.copyWith(
                                                    letterSpacing: 0,
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.logout_rounded,
                                              size: 30.0,
                                            ),
                                            onPressed: () async {
                                              await _showConfirmationDialog(
                                                  authService);
                                            },
                                          )
                                        ]))),
                            Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 4.0,
                                        color: Color(0x33000000),
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      )
                                    ],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Align(
                                                  alignment:
                                                      AlignmentDirectional(
                                                          1.0, 0.0),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 7.0,
                                                                10.0, 0.0),
                                                    child: IconButton(
                                                      icon: FaIcon(
                                                        FontAwesomeIcons
                                                            .arrowRotateLeft,
                                                        size: 20.0,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                      onPressed: () async {},
                                                    ),
                                                  ))
                                            ]),
                                        Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 16.0),
                                            child: Container(
                                                width: 366.0,
                                                height: 174.0,
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface,
                                                ),
                                                child: Align(
                                                    alignment:
                                                        AlignmentDirectional(
                                                            0.0, 0.0),
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(24.0),
                                                      child: Text(
                                                        'Connect your CGM to easily track your insulin levels and view detailed charts',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              letterSpacing: 0,
                                                            ),
                                                      ),
                                                    ))))
                                      ]),
                                )),
                            Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 5.0,
                                              color: Color(0x230E151B),
                                              offset: Offset(
                                                0.0,
                                                2.0,
                                              ),
                                            )
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Padding(
                                            padding: EdgeInsets.all(4.0),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              6, 6, 0, 6),
                                                      child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            6),
                                                                    child:
                                                                        FaIcon(
                                                                      FontAwesomeIcons
                                                                          .shoePrints,
                                                                      size:
                                                                          24.0,
                                                                      color: Theme.of(
                                                                              context)
                                                                          .primaryColor,
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                      width:
                                                                          100.0,
                                                                      height:
                                                                          40.0,
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child: Align(
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                          child: showHealthData(
                                                                              [
                                                                                HealthConnectDataType.Steps
                                                                              ],
                                                                              steps,
                                                                              "Steps",
                                                                              hasStepsPermission,
                                                                              "",
                                                                              "")))
                                                                ]),
                                                            Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  FaIcon(
                                                                    FontAwesomeIcons
                                                                        .heartPulse,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .error,
                                                                    size: 24.0,
                                                                  ),
                                                                  Container(
                                                                      width:
                                                                          100.0,
                                                                      height:
                                                                          40.0,
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child: Align(
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                          child: Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0,
                                                                                  0),
                                                                              child: showHealthData([
                                                                                HealthConnectDataType.HeartRate
                                                                              ], beatsPerMinute, "BPM", hasHeartPermission, "", ""))))
                                                                ]),
                                                            Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  FaIcon(
                                                                    FontAwesomeIcons
                                                                        .fire,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .error,
                                                                    size: 24.0,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Container(
                                                                      width:
                                                                          100.0,
                                                                      height:
                                                                          40.0,
                                                                      decoration:
                                                                          BoxDecoration(),
                                                                      child: Align(
                                                                          alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0),
                                                                          child: Padding(
                                                                              padding: EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0,
                                                                                  0.0),
                                                                              child: showHealthData([
                                                                                HealthConnectDataType.TotalCaloriesBurned
                                                                              ], burned?.toInt(), "kcal", hasBurnedPermission, "Srource of burned calories", "This data is obtained from the workout sessions tracked by Health Connect."))))
                                                                ])
                                                          ]))
                                                ]))),
                                  ],
                                )),
                            Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 5.0,
                                          color: Color(0x230E151B),
                                          offset: Offset(
                                            0.0,
                                            2.0,
                                          ),
                                        )
                                      ],
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 12.0, 0.0, 30.0),
                                                child: Text(
                                                  'Intakes Totals',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        letterSpacing: 0,
                                                      ),
                                                )),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 20),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  FutureBuilder<Column>(
                                                    future: insulinDosages(
                                                        context, 'Bolus'),
                                                    builder: (BuildContext
                                                            context,
                                                        AsyncSnapshot<Column>
                                                            snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return CircularProgressIndicator();
                                                      } else if (snapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error: ${snapshot.error}');
                                                      } else if (!snapshot
                                                          .hasData) {
                                                        return Text('-');
                                                      } else {
                                                        return snapshot.data!;
                                                      }
                                                    },
                                                  ),
                                                  FutureBuilder<Column>(
                                                    future: insulinDosages(
                                                        context, 'basal'),
                                                    builder: (BuildContext
                                                            context,
                                                        AsyncSnapshot<Column>
                                                            snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return CircularProgressIndicator();
                                                      } else if (snapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error: ${snapshot.error}');
                                                      } else if (!snapshot
                                                          .hasData) {
                                                        return Text('-');
                                                      } else {
                                                        return snapshot.data!;
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      16.0, 0.0, 16.0, 16.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                0.0, -1.0),
                                                        child: Text(
                                                          'Carb',
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .labelMedium
                                                              ?.copyWith(
                                                                  letterSpacing:
                                                                      0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                  fontSize: 15),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    15.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Container(
                                                          width: 56.0,
                                                          height: 25.0,
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Align(
                                                            alignment:
                                                                AlignmentDirectional(
                                                                    0.0, -1.0),
                                                            child:
                                                                FutureBuilder<
                                                                    double>(
                                                              future: userService
                                                                  .getTotalCarbs(),
                                                              builder: (BuildContext
                                                                      context,
                                                                  AsyncSnapshot<
                                                                          double>
                                                                      snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .waiting) {
                                                                  return CircularProgressIndicator();
                                                                } else if (snapshot
                                                                    .hasError) {
                                                                  return Text(
                                                                      'Error: ${snapshot.error}');
                                                                } else if (!snapshot
                                                                    .hasData) {
                                                                  return Text(
                                                                      '-');
                                                                } else {
                                                                  return Text(
                                                                    '${snapshot.data!.toInt()} g',
                                                                    style: Theme.of(
                                                                            context)
                                                                        .textTheme
                                                                        .labelMedium
                                                                        ?.copyWith(
                                                                            letterSpacing:
                                                                                0,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize: 14),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  nutritionValues(
                                                      context, 'Protien'),
                                                  nutritionValues(
                                                      context, 'Fat'),
                                                  nutritionValues(
                                                      context, 'Calorie'),
                                                ],
                                              ),
                                            )
                                          ],
                                        )))),
                            LogbookWidget(
                              specificDate: DateTime.now(),
                              isHome: true,
                            ),
                            SizedBox(height: 60)
                          ])))),
            )));
  }

  Column nutritionValues(BuildContext context, String title) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional(0.0, -1.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0, fontWeight: FontWeight.w300, fontSize: 15),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 15.0, 0.0, 0.0),
          child: Container(
            width: 56.0,
            height: 25.0,
            decoration: BoxDecoration(),
            child: Align(
              alignment: AlignmentDirectional(0.0, -1.0),
              child: Text(
                '-',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(letterSpacing: 0, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<Column> insulinDosages(BuildContext context, String type) async {
    double? userBasal;
    double? userBolus;
    try {
      userBasal = await userService.getUserAttribute('dailyBasal');
    } catch (e) {}

    try {
      userBolus = await userService.getUserAttribute('dailyBolus');
    } catch (e) {}

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: AlignmentDirectional(-1.0, -1.0),
          child: Text(
            (type.toLowerCase() == 'bolus')
                ? 'Short Acting Dose'
                : 'Long Acting Dose',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0, fontWeight: FontWeight.w300, fontSize: 15),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
          child: Container(
            width: 145.0,
            height: 67.0,
            decoration: BoxDecoration(),
            child: Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 25.0),
                child: FutureBuilder<double>(
                  future: userService.getTotalDosages(type),
                  builder:
                      (BuildContext context, AsyncSnapshot<double> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData) {
                      return Text('0 Units');
                    } else {
                      double value = 0;
                      if (type == 'Bolus') {
                        value = snapshot.data! / userBolus!;
                      } else {
                        value = snapshot.data! / userBasal!;
                      }
                      var color = Theme.of(context).primaryColor;
                      if (value > 1) {
                        color = Theme.of(context).colorScheme.error;
                      } else if (value == 1) {
                        color = Color(0xff66B266);
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${snapshot.data!.toDouble()}/${(type == 'Bolus') ? userBolus?.toDouble() : userBasal?.toDouble()} Units',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          letterSpacing: 0,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    var info = '';
                                    if (type == 'Bolus') {
                                      info =
                                          'You have taken ${snapshot.data!.toDouble()} out of your daily dosage of ${userBasal?.toDouble()} units of bolus insulin today, which quickly manages blood sugar spikes after meals.';
                                    } else {
                                      info =
                                          'You have taken ${snapshot.data!.toDouble()} out of your daily dosage of ${userBasal?.toDouble()} units of basal insulin today, which helps maintain stable blood sugar levels.';
                                    }
                                    _showInfo(
                                        context,
                                        "Limit of ${type == 'Bolus' ? 'Short Acting' : 'Long Acting'} dosgae",
                                        Text(info));
                                  },
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Color.fromRGBO(96, 106, 133, 1),
                                    size: 16.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey[200],
                              color: color,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Padding showHealthData(List<HealthConnectDataType> type, int? value,
      String unit, bool hasTypePermission, String title, String info) {
    return Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 1.0, 0.0, 0.0),
        child: FutureBuilder<bool>(
          future: hasPermission(type),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
                  letterSpacing: 0,
                );

            if (!apiAvailable) {
              return InkWell(
                onTap: () async {
                  try {
                    await downloadHealthConnect();
                  } catch (e) {}
                },
                child: Text(
                  'Grant Access',
                  style: textStyle?.copyWith(
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      color: Theme.of(context).primaryColor),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(
                'Loading...',
                style: textStyle,
              );
            } else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: textStyle,
              );
            } else if (snapshot.hasData && snapshot.data!) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (value != null && hasTypePermission) ? '$value $unit' : '-',
                    style: textStyle,
                  ),
                  if (info.isNotEmpty) ...[
                    SizedBox(
                      width: 5,
                    ),
                    GestureDetector(
                      onTap: () {
                        _showInfo(context, title, Text(info));
                      },
                      child: Icon(
                        Icons.info_outline,
                        color: Color.fromRGBO(96, 106, 133, 1),
                        size: 16.0,
                      ),
                    ),
                  ],
                ],
              );
            } else {
              return InkWell(
                onTap: () async {
                  try {
                    await HealthConnectFactory.openHealthConnectSettings();
                  } catch (e) {}
                },
                child: Text(
                  'Grant Access',
                  style: textStyle?.copyWith(
                      decoration: TextDecoration.underline,
                      fontSize: 12,
                      color: Theme.of(context).primaryColor),
                ),
              );
            }
          },
        ));
  }
}
