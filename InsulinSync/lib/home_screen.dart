import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
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
import 'glucoseChart.dart';
import 'services/cgm_auth_service.dart';
import 'services/user_service.dart';
import 'models/note_model.dart';
import 'models/insulin_model.dart';
import '../widgets.dart';
import 'package:store_redirect/store_redirect.dart';
import 'Cart.dart';
import 'splash.dart';
import 'AddBySearch.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'addnNutrition2.dart';

// A class for mapping integer trend arrow values to corresponding Flutter icons.
class ArrowIconMapper {
  static const Map<int, IconData> arrowIcons = {
    1: Icons.arrow_downward,
    2: Icons.south_east,
    3: Icons.arrow_forward,
    4: Icons.north_east,
    5: Icons.arrow_upward
  };

  static IconData getIcon(int value) {
    return arrowIcons[value] ?? Icons.help_outline;
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  int? minRange;
  int? maxRange;

  // Method to retrive the user's normal range from the database
  Future<void> getMinMax() async {
    try {
      // Retrive tha values from the database
      maxRange = await userService.getUserAttribute('maxRange') as int?;
      minRange = await userService.getUserAttribute('minRange') as int?;
    } catch (e) {
      print('error $e');
    }
  }

  late Future<Column> syncInsulinDosagesBolus;
  late Future<Column> syncInsulinDosagesBasal;
  late Future<Map<String, double>> getTotalMeal;

  late Future<bool> isCgmConnectedFuture;

  late Future<void> minMaxFuture;
  late Stream<double> glucoseStream;
  late Stream<int> arrowStream;

  late UserService userService;
  CGMAuthService cgmAuthService = CGMAuthService();

  Map<String, double> _data = {'Low': 0, 'In-Range': 0, 'High': 0};
  bool _isLoading = true;

  void initState() {
    userService = UserService();
    userService.fetchCurrentGlucose();
    userService.startPeriodicGlucoseFetch();
    isCgmConnectedFuture = userService.isCgmConnected();
    minMaxFuture = getMinMax();
    glucoseStream = userService.glucoseStream;
    arrowStream = userService.arrowStream;

    syncInsulinDosagesBolus = insulinDosages(context, 'Bolus');
    syncInsulinDosagesBasal = insulinDosages(context, 'Basal');
    getTotalMeal = userService.getTotalMeal(onlyToday: true);

    super.initState();

    try {
      _requestHealthPermissions();
    } catch (e) {
      print('Error requesting health permissions: \$e');
    }

    try {
      _fetchGlucoseData();
    } catch (e) {}

    try {
      _refreshData();
    } catch (e) {
      print('Error refreshing data: \$e');
    }

    try {
      _startTimer();
    } catch (e) {
      print('Error starting timer: \$e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshData();
  }

// Timer to refresh screen every 10 minutes
  void _startTimer() {
    _timer = Timer.periodic(Duration(minutes: 10), (timer) {
      try {
        _refreshData();
      } catch (e) {}
    });
  }

// Method to check availablity of health connect
  Future<bool> isApiAvailable() async {
    try {
      var result = await HealthConnectFactory.isAvailable();
      apiAvailable = result;

      return result;
    } catch (e) {
      return false;
    }
  }

// Method to redirect user to the store to download health connect
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

// Method to determines the background color based on the glucose value.
  Color getGlucoseBackgroundColor(double? glucoseValue) {
    if (glucoseValue == null || minRange == null || maxRange == null) {
      return Color(0xffA6A6A6);
    }

    if (glucoseValue <= minRange!) {
      return Color(0xffE50000); // Low glucose levels - Red
    } else if (glucoseValue >= maxRange!) {
      return Color(0xffFFB732); // High glucose levels - Orange
    } else {
      return Color(0xff99CC99); // Normal range - Green
    }
  }

// Method to confirm sign out
  Future<void> _showConfirmationDialogLogout(AuthService authService) async {
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

  Future<bool> _showConfirmationDialogLibre(String text) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Text(
                  text,
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
                          // Close dialog and return false (Cancel)
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
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Close dialog and return true (Confirm)
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Return the result, default to false if null (in case the dialog is dismissed without selection)
    return result ?? false;
  }

  Future<void> _showDialogLibreLoginStatus(bool isSuccess, bool isLogin) async {
    // Show the dialog
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel_outlined,
                color: isSuccess
                    ? Color(0xff023b96)
                    : Color.fromARGB(255, 194, 43, 98),
                size: 80,
              ),
              SizedBox(height: 25),
              Text(
                isLogin
                    ? (isSuccess
                        ? 'Connected to the CGM successfully'
                        : 'Failed to connect to the CGM. Please try again.')
                    : (isSuccess
                        ? 'Disconnected from the CGM successfully'
                        : 'Failed to disconnect from the CGM. Please try again.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              SizedBox(height: 30),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => MainNavigation()),
                    (Route<dynamic> route) => false,
                  );
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
              )
            ],
          ),
          actions: isSuccess
              ? []
              : [
                  Center(
                    // Center the button
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
    if (isSuccess) {
      // Wait for 3 seconds before closing the dialog and navigating
      await Future.delayed(Duration(seconds: 3));

      // Close the dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Navigate to MainNavigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation()),
      );
    }
  }

  Future<void> showResultDialog(
    bool isSuccess, {
    String? successMessage,
    String? errorMessage,
    String? detailedErrorMessage,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.cancel_outlined,
                color: isSuccess
                    ? Color(0xff023b96)
                    : Color.fromARGB(255, 194, 43, 98),
                size: 80,
              ),
              SizedBox(height: 25),
              Text(
                isSuccess
                    ? successMessage ?? 'Operation was successful!'
                    : errorMessage ?? 'Operation failed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
              if (!isSuccess && detailedErrorMessage != null) ...[
                SizedBox(height: 15),
                Text(
                  detailedErrorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ],
          ),
        );
      },
    );

    // If success, navigate after 3 seconds
    if (isSuccess) {
      // Wait for 3 seconds
      await Future.delayed(Duration(seconds: 3));

      // Dismiss the dialog manually
      Navigator.pop(context);

      // Navigate to the next screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainNavigation()),
        (Route<dynamic> route) => false,
      );
    } else {
      print('Operation failed, no success action taken');
    }
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
                    leading: ImageIcon(
                      AssetImage('images/wheat.png'),
                      color: primaryColor,
                    ),
                    title: Text('Carb', style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddNutrition2()),
                      ).then((onValue) {
                        _refreshData();
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.fastfood, color: primaryColor),
                    title: Text('Meal', style: TextStyle(color: primaryColor)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Cart()),
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

// Method to check if permission to access a specific data type is granted
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

          // use the value of the heart rate only if it within 10 minutes
          if (specificDateTime.difference(dateTime).inMinutes > 10) {
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

        // only show the steps if they happened today
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

      double totalCalories = 0.0;
      var records = val['records'] as List<dynamic>;

      // sum the calories burned from all sessions
      for (var record in records) {
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
      var startTime = DateTime.now().subtract(const Duration(days: 1000));
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

  // Method to return a future of the user connection state to the CGM
  Future<bool> getIsCgmConnectedFuture() {
    return userService.isCgmConnected(); // Always create a new Future
  }

  Future<void> _refreshCGMData(bool onlyCGM) async {
    await userService.fetchCurrentGlucose();
    await userService.fetchAndStoreReadings();
    await _fetchGlucoseData();

    if (onlyCGM) {
      setState(() {});
    }
  }

  Future<void> _refreshData() async {
    await _refreshCGMData(false);
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
                                              await _showConfirmationDialogLogout(
                                                  authService);
                                            },
                                          )
                                        ]))),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(1, 0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0, 0, 23, 20),
                                    child: GestureDetector(
                                      onTap: () async {
                                        bool isConnected =
                                            await userService.isCgmConnected();
                                        if (isConnected) {
                                          await showSlideShowOverlaySignedIn(
                                              context);
                                        } else {
                                          showSlideShowOverlay(context);
                                        }
                                      },
                                      child: FaIcon(
                                        FontAwesomeIcons.dotCircle,
                                        color: Theme.of(context).primaryColor,
                                        size: 25,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                                      onPressed: () async {
                                                        await _refreshCGMData(
                                                            true);
                                                      },
                                                    ),
                                                  )),
                                            ]),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 0),
                                          child:
                                              // StreamBuilder for glucose value
                                              FutureBuilder(
                                                  future: minMaxFuture,
                                                  builder: (context,
                                                      minMaxsnapshot) {
                                                    if (minMaxsnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return CircularProgressIndicator(); // Loading indicator
                                                    } else if (minMaxsnapshot
                                                        .hasError) {
                                                      print(
                                                          '${minMaxsnapshot.error}');
                                                      return SizedBox();
                                                    } else {
                                                      return StreamBuilder(
                                                        stream: glucoseStream,
                                                        builder: (context,
                                                            glucoseSnapshot) {
                                                          if (glucoseSnapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return CircularProgressIndicator(); // Loading indicator
                                                          } else if (glucoseSnapshot
                                                                  .hasData &&
                                                              !glucoseSnapshot
                                                                  .hasError) {
                                                            print(
                                                                'snapshot.hasData  ${glucoseSnapshot.data}');
                                                            Color color =
                                                                getGlucoseBackgroundColor(
                                                                    glucoseSnapshot
                                                                        .data);
                                                            return Container(
                                                                color: color,
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      Text(
                                                                        '${glucoseSnapshot.data}',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              40.0,
                                                                          color:
                                                                              Colors.white,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          // StreamBuilder for arrow icon
                                                                          StreamBuilder(
                                                                            stream:
                                                                                arrowStream,
                                                                            builder:
                                                                                (context, snapshot) {
                                                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                                                return SizedBox(height: 20); // Default loading icon
                                                                              } else if (snapshot.hasError || !snapshot.hasData) {
                                                                                return SizedBox(height: 20); // Error icon
                                                                              } else {
                                                                                return Icon(
                                                                                  ArrowIconMapper.getIcon(snapshot.data! as int),
                                                                                  color: Colors.white,
                                                                                  size: 35.0,
                                                                                ); // Map the number to the appropriate icon
                                                                              }
                                                                            },
                                                                          ),
                                                                          Text(
                                                                            'mg/dL',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 15,
                                                                              color: Colors.white, // Set text color to contrast with the background
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ]));
                                                          } else {
                                                            return Container(
                                                                height: 90,
                                                                color: Color(
                                                                    0xffA6A6A6), // Set the background color for the entire row
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0), // Optional: Add padding around the Row
                                                                child: Row(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .max,
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        '-',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              40.0,

                                                                          color:
                                                                              Colors.white, // Ensure contrast against the green background
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            10,
                                                                      ),
                                                                      Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          // StreamBuilder for arrow icon

                                                                          Row(
                                                                            children: [
                                                                              Text(
                                                                                ' ',
                                                                                style: TextStyle(
                                                                                  fontSize: 40.0,

                                                                                  color: Colors.white, // Ensure contrast against the green background
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                'mg/dL',
                                                                                style: TextStyle(
                                                                                  fontSize: 25,
                                                                                  color: Colors.white, // Set text color to contrast with the background
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ]));
                                                          }
                                                        },
                                                      );
                                                    }
                                                  }),
                                        ),
                                        Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    16.0, 0.0, 16.0, 16.0),
                                            child: Container(
                                                // width: 366.0,
                                                // height: 700.0,
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
                                                          EdgeInsets.all(0),
                                                      child:
                                                          FutureBuilder<bool>(
                                                        future:
                                                            getIsCgmConnectedFuture(),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return const CircularProgressIndicator();
                                                          } else if (snapshot
                                                              .hasError) {
                                                            return Text(
                                                                'Error: ${snapshot.error}');
                                                          } else if (snapshot
                                                                  .hasData &&
                                                              snapshot.data ==
                                                                  true) {
                                                            return GlucoseChart(
                                                                specificDate:
                                                                    DateTime
                                                                        .now());
                                                          } else {
                                                            return Container(
                                                              width: 366.0,
                                                              height: 174.0,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .surface,
                                                              ),
                                                              child: Align(
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        0.0,
                                                                        0.0),
                                                                child: Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            24.0),
                                                                    child:
                                                                        RichText(
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      text:
                                                                          TextSpan(
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .bodyMedium
                                                                            ?.copyWith(
                                                                              letterSpacing: 0,
                                                                            ),
                                                                        children: [
                                                                          TextSpan(
                                                                            text:
                                                                                'Click here to Connect your CGM to InsulinSync',
                                                                            style:
                                                                                TextStyle(
                                                                              color: Theme.of(context).primaryColor,
                                                                              decoration: TextDecoration.underline,
                                                                            ),
                                                                            recognizer: TapGestureRecognizer()
                                                                              ..onTap = () {
                                                                                showSlideShowOverlay(context);
                                                                              },
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                '\n\nor by clicking',
                                                                            style:
                                                                                TextStyle(fontWeight: FontWeight.bold), // Style for CGM text if needed
                                                                          ),
                                                                          WidgetSpan(
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets.only(left: 4.0), // Space between CGM and icon
                                                                              child: FaIcon(
                                                                                FontAwesomeIcons.dotCircle,
                                                                                color: Theme.of(context).primaryColor,
                                                                                size: 18,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                ' at the upper right corner',
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ))))
                                      ]),
                                )),
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
                                      offset: Offset(0.0, 2.0),
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: _isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : _data.values.every((value) => value == 0)
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Title Section
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 20.0,
                                                    horizontal: 16.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(5, 0, 0.0, 0),
                                                  child: Text(
                                                    'Time-in-Range',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          letterSpacing: 0,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              // Message Section
                                              Center(
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(0, 0, 0.0, 20),
                                                  child: Text(
                                                    'No glucose data available for today.',
                                                    style: TextStyle(
                                                      fontSize: 14.7,
                                                      color:
                                                          const Color.fromARGB(
                                                              255,
                                                              123,
                                                              123,
                                                              123),
                                                    ),
                                                    textAlign: TextAlign
                                                        .center, // Ensure the text is centered within the padding
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 20.0,
                                                horizontal:
                                                    16.0), // Balanced padding
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start, // Aligns children to the left
                                              children: [
                                                // Title Section
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(5, 0, 0.0, 0),
                                                  child: Text(
                                                    'Time-in-Range',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          letterSpacing: 0,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(height: 8.0),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      flex: 1,
                                                      child: AspectRatio(
                                                        aspectRatio: 1.4,
                                                        child: PieChart(
                                                          PieChartData(
                                                            sections: _data
                                                                .entries
                                                                .map((entry) {
                                                              return PieChartSectionData(
                                                                title: '',
                                                                value:
                                                                    entry.value,
                                                                color: entry.key ==
                                                                        'Low'
                                                                    ? Color
                                                                        .fromARGB(
                                                                            255,
                                                                            194,
                                                                            43,
                                                                            98)
                                                                    : entry.key ==
                                                                            'In-Range'
                                                                        ? Color.fromARGB(
                                                                            255,
                                                                            71,
                                                                            169,
                                                                            140)
                                                                        : Color.fromARGB(
                                                                            255,
                                                                            244,
                                                                            165,
                                                                            52),
                                                                radius:
                                                                    28, // Smaller slices for compactness
                                                              );
                                                            }).toList(),
                                                            centerSpaceRadius:
                                                                0,
                                                            sectionsSpace: 1.5,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 24.0),
                                                    // Data Summary Section
                                                    Expanded(
                                                      flex: 3,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceAround,
                                                        children: [
                                                          // Low Summary
                                                          Column(
                                                            children: [
                                                              Text(
                                                                'Low',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          194,
                                                                          43,
                                                                          98),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 6.0),
                                                              Text(
                                                                '${_data['Low']?.toStringAsFixed(1)}%',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          // In-Range Summary
                                                          Column(
                                                            children: [
                                                              Text(
                                                                'In-Range',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          71,
                                                                          169,
                                                                          140),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 6.0),
                                                              Text(
                                                                '${_data['In-Range']?.toStringAsFixed(1)}%',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          // High Summary
                                                          Column(
                                                            children: [
                                                              Text(
                                                                'High',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          244,
                                                                          165,
                                                                          52),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 6.0),
                                                              Text(
                                                                '${_data['High']?.toStringAsFixed(1)}%',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      14.0,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                              ),
                            ),
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
                                                    future:
                                                        syncInsulinDosagesBolus,
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
                                                    future:
                                                        syncInsulinDosagesBasal,
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
                                              child: FutureBuilder<
                                                  Map<String, double>>(
                                                future: getTotalMeal,
                                                builder: (BuildContext context,
                                                    AsyncSnapshot<
                                                            Map<String, double>>
                                                        snapshot) {
                                                  if (snapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return Center(
                                                        child:
                                                            CircularProgressIndicator());
                                                  } else if (snapshot
                                                      .hasError) {
                                                    return Center(
                                                        child: Text(
                                                            'Error: ${snapshot.error}'));
                                                  } else if (!snapshot
                                                      .hasData) {
                                                    return Center(
                                                        child: Text(
                                                            'No data available'));
                                                  } else {
                                                    final totalNutrition =
                                                        snapshot.data!;
                                                    return Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                      children: [
                                                        nutritionValues(
                                                            context,
                                                            'Carb',
                                                            '${totalNutrition["totalCarb"]?.toStringAsFixed(1)} g'),
                                                        nutritionValues(
                                                            context,
                                                            'Protein',
                                                            '${totalNutrition["totalProtein"]?.toStringAsFixed(1)} g'),
                                                        nutritionValues(
                                                            context,
                                                            'Fat',
                                                            '${totalNutrition["totalFat"]?.toStringAsFixed(1)} g'),
                                                        nutritionValues(
                                                            context,
                                                            'Calories',
                                                            '${totalNutrition["totalCal"]?.toStringAsFixed(1)}'),
                                                      ],
                                                    );
                                                  }
                                                },
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

  Column nutritionValues(BuildContext context, String title, String value) {
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
                value, // Display the passed value dynamically
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
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

  Future<void> _fetchGlucoseData() async {
    if (userService.currentUserId == null) {
      print('Error: currentUserId is null. User may not be authenticated.');

      _isLoading = false;

      return;
    }

    try {
      print('Fetching glucose readings for user: ${userService.currentUserId}');
      final List<GlucoseReading> allReadings =
          await userService.getGlucoseReadings();
      print('Total fetched readings: ${allReadings.length}');

      // Filter readings for today's data
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = startOfDay.add(Duration(days: 1));

      final todayReadings = allReadings.where((reading) {
        return reading.time.isAfter(startOfDay) &&
            reading.time.isBefore(endOfDay);
      }).toList();

      print('Today\'s readings count: ${todayReadings.length}');

      // Categorize readings
      int low = 0, inRange = 0, high = 0;

      for (var reading in todayReadings) {
        if (reading.reading < 70) {
          low++;
        } else if (reading.reading >= 70 && reading.reading <= 180) {
          inRange++;
        } else {
          high++;
        }
      }

      int total = low + inRange + high;
      print('Low: $low, In-Range: $inRange, High: $high, Total: $total');

      if (total > 0) {
        _data['Low'] = (low / total) * 100;
        _data['In-Range'] = (inRange / total) * 100;
        _data['High'] = (high / total) * 100;
      } else {
        _data = {'Low': 0, 'In-Range': 0, 'High': 0};
      }
      _isLoading = false; // Stop loading after processing
    } catch (e) {
      print('Error fetching glucose data: $e');

      _isLoading = false; // Stop loading in case of error
    }
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  String? _emailErrorMessage;
  String? _passwordErrorMessage;

  void showSlideShowOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(4),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (stfContext, stfSetState) {
              return Container(
                height: MediaQuery.of(stfContext).size.height * 0.6,
                width: MediaQuery.of(stfContext).size.width * 0.92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.85),
                            itemCount: 4,
                            onPageChanged: (int index) {
                              stfSetState(() {});
                            },
                            itemBuilder: (context, index) {
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                margin: EdgeInsets.symmetric(horizontal: 8),
                                padding: EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: _buildSlideContent(
                                    stfContext, index, stfSetState),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSlideContent(
      BuildContext context, int index, Function stfSetState) {
    List<Widget> slides = [
      // Slide 1
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset('images/FSicon.png', height: 100),
                ),
                SizedBox(height: 16),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 1: Set Up and Connecting LibreLink to Your CGM',
                    textAlign:
                        TextAlign.center, // Centers text within the container
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 27),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Download ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' on your phone.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-2.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'Log in or Sign up using your email and password.',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-3.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Connect your Libre 2 CGM sensor to ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Slide 2
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset('images/LLUicon.png', height: 100),
                ),
                SizedBox(height: 20),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 2: Set Up LibreLinkUp',
                    textAlign:
                        TextAlign.center, // Centers text within the container
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 27),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Download ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLinkUp',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 238, 80, 0)),
                            ),
                            TextSpan(text: ' on your phone.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-2.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Sign up with a different email than your ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' account.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Slide 3
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 3: Linking LibreLinkUp to your LibreLink account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Image.asset('images/LLUicon.png', height: 40),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'In ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLinkUp',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 238, 80, 0)),
                            ),
                            TextSpan(text: ' :'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text:
                              'Add yourself as a connection by searching your ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' email.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-2.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Send a follow request to your ',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' account.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Row(
                  children: [
                    Image.asset('images/FSicon.png', height: 40),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'In ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLink',
                              style: TextStyle(
                                  color:
                                      const Color.fromARGB(255, 237, 182, 0)),
                            ),
                            TextSpan(text: ' :'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Color(0xFF023B96),
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('images/circle-1.png',
                          height: 24, width: 24),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Approve the follow request notification to link both accounts.',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

      // Slide 4 (Form Slide)
      Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Container(
                  width: double
                      .infinity, // Ensures the text container takes the full width available
                  padding: EdgeInsets.symmetric(
                      horizontal: 0), // Add padding to prevent overflow
                  child: Text(
                    'Step 4: Connect InsulinSync with your CGM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023B96),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(height: 1),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Input your ',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'LibreLinkUp',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 238, 80, 0)),
                            ),
                            TextSpan(
                                text: ' account details to complete setup:'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      buildTextField(
                          label: 'Email',
                          controller: _emailController,
                          validator: emailValidator,
                          icon: Icons.email,
                          errorText: _emailErrorMessage,
                          readOnly: false),
                      buildTextField(
                          label: 'Password',
                          isObscured: true,
                          controller: _passwordController,
                          validator: passwordValidator,
                          icon: Icons.lock,
                          errorText: _passwordErrorMessage,
                          readOnly: false),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await _loginUser(stfSetState);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          child: Text(
                            'Connect',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontSize: 19.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ];
    return slides[index];
  }

  Future<void> showSlideShowOverlaySignedIn(BuildContext context) async {
    String libreEmail = await userService.getUserAttribute('libreEmail');
    String libreName = await userService.getUserAttribute('libreName');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(4),
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (stfContext, stfSetState) {
              return Container(
                height: MediaQuery.of(stfContext).size.height * 0.6,
                width: MediaQuery.of(stfContext).size.width * 0.92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            padding: EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _buildSlideContentSignedIn(
                                stfContext, libreEmail, libreName, stfSetState),
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSlideContentSignedIn(BuildContext context, String libreEmail,
      String libreName, Function stfSetState) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                width: double
                    .infinity, // Ensures the text container takes the full width available
                padding: EdgeInsets.symmetric(
                    horizontal: 0), // Add padding to prevent overflow
                child: Text(
                  'Connection state',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF023B96),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Your current connection information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 10),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(
                        controller: TextEditingController(text: '$libreEmail'),
                        icon: Icons.email,
                        label: 'Email',
                        readOnly: true),
                    buildTextField(
                        controller: TextEditingController(text: '$libreName'),
                        icon: Icons.person,
                        label: 'Full name',
                        readOnly: true),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _logoutUser(stfSetState);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        child: Text(
                          'Disconnect',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 19.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
      {required String label,
      bool isObscured = false,
      required TextEditingController controller,
      required IconData icon,
      String? Function(String?)? validator,
      String? errorText,
      required bool readOnly}) {
    final FocusNode focusNode = FocusNode();

    Color borderColor = errorText != null && errorText.isNotEmpty
        ? Theme.of(context).colorScheme.error
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 18, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 0, 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
          ),
          Stack(
            children: [
              CustomTextFormField(
                controller: controller,
                focusNode: focusNode,
                validator: validator,
                obscureText: isObscured,
                autofillHint: AutofillHints.name,
                textInputAction: TextInputAction.next,
                prefixIcon: icon,
                readOnly: readOnly,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null && errorText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Text(
                errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Method to disconnect user's Libreview account
  Future<void> _logoutUser(Function stfSetState) async {
    bool logout = await _showConfirmationDialogLibre(
        'Are You Sure you want to disconnet from your Libre freestyle account?\nAll of your data will be removed');
    if (logout) {
      bool loggedout = await cgmAuthService.logout();
      await _showDialogLibreLoginStatus(loggedout, false);
    }
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    // Regular expression for validating email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }

    return null;
  }

  // Method to connect user's Libreview account
  Future<void> _loginUser(Function stfSetState) async {
    stfSetState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      try {
        var isSignedIn = await cgmAuthService.signIn(
            _emailController.text.trim(), _passwordController.text.trim());

        print("cgmAuthService.errorMessage ${cgmAuthService.errorMessage}");

        stfSetState(() {
          _emailErrorMessage = cgmAuthService.errorMessage;
          _passwordErrorMessage = cgmAuthService.errorMessage;
        });

        if (!isSignedIn) {
          return;
        }

        var emailAccounts = await cgmAuthService.fetchPatients();

        _showEmailDialog(context, emailAccounts);
      } catch (e) {
        print('Login Error: $e');
      }
    }
  }

  void _showEmailChoiceDialog(BuildContext context, List<dynamic> emailAccounts,
      Function(String) onEmailSelected) {
    Map<String, dynamic>? selectedPatient;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          title: Text(
            'Select LibreLink account you want to follow:',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF023B96)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: emailAccounts.map((email) {
                return RadioListTile<Map<String, dynamic>>(
                  title: Text(
                    "${email['firstName']} ${email['lastName']}",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  value: email,
                  groupValue: selectedPatient,
                  activeColor:
                      Color(0xFF023B96), // Accent color for selected radio
                  onChanged: (Map<String, dynamic>? value) {
                    selectedPatient = value;
                    (context as Element).markNeedsBuild();
                  },
                );
              }).toList(),
            ),
          ),
          actionsPadding: const EdgeInsetsDirectional.fromSTEB(10, 0, 10, 20),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      if (selectedPatient != null) {
                        bool? confirmationResult =
                            await _showConfirmationDialogLibre(
                                'Are You Sure Want to Follow ${selectedPatient!["firstName"]} ${selectedPatient!["lastName"]}');
                        if (confirmationResult == true) {
                          bool setAttributesResult = await cgmAuthService
                              .setAttributes(selectedPatient!);

                          await _showDialogLibreLoginStatus(
                              setAttributesResult, true);
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      backgroundColor: Color(0xFF023B96),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Confirm'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleEmailSelection(String selectedPatient) {}

  void _showEmailDialog(BuildContext context, List<dynamic> emailAccounts) {
    _showEmailChoiceDialog(context, emailAccounts, _handleEmailSelection);
  }

  void _showLoginSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(Duration(seconds: 4), () {
          Navigator.of(context).pop();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainNavigation()),
            (Route<dynamic> route) => false,
          );
        });

        return Dialog(
          backgroundColor: const Color(0xFF023B95),
          insetPadding: EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            padding:
                const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF024BB1), Color(0xFF012A70)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 120,
                  semanticLabel: 'Success Icon',
                ),
                SizedBox(height: 30),
                Center(
                  child: Text(
                    'You have successfully Connected to your CGM.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Let’s continue optimizing your care and keeping your glucose levels in check',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => MainNavigation()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.3),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      color: Color(0xFF023B95),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
