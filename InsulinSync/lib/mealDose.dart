import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insulin_sync/global_state.dart' as globals;
import 'package:intl/intl.dart';

import 'AddInsulin.dart';
import 'AddPhysicalActivity.dart';
import 'MainNavigation.dart';
import 'corrfact.dart';
import 'home_screen.dart';
import 'models/glucose_model.dart';
import 'models/insulin_model.dart';
import 'models/meal_model.dart';
import 'models/workout_model.dart';
import 'services/user_service.dart';

class mealDose extends StatefulWidget {
  final meal? currentMeal;
  final String? mealId;

  const mealDose({
    super.key,
    this.currentMeal,
    this.mealId,
  });

  @override
  _mealDoseState createState() => _mealDoseState();
}

class _mealDoseState extends State<mealDose> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();

  double? currentBG;
  int? trendArrow;
  double? carbRatio;
  double? correctionRatio;
  String? Gsource;

  final UserService _userService = UserService();
  List<Workout> recentExercises = [];
  List<Workout> upcomingExercises = [];
  List<InsulinDosage> recentBoluses = [];

  TextEditingController _glucoseController = TextEditingController();
  TextEditingController _insulinController = TextEditingController();

  late TextEditingController _timeController;
  late TextEditingController _timeController2;

  Timer? _debounce;

  late DateTime newMealTime;

  CorrFact correctionFactorCalculator = CorrFact();

  @override
  void initState() {
    super.initState();

    // Initialize from currentMeal
    newMealTime = widget.currentMeal!.time;

    _fetchData();

    _timeController = TextEditingController(
      text: DateFormat('HH:mm').format(DateTime.now()),
    );

    _timeController2 = TextEditingController(
      text: DateFormat('HH:mm').format(DateTime.now()),
    );
  }

  Future<void> _fetchData() async {
    try {
      // Fetch exercises from past 2 hours
      recentExercises = await getExercisesInLastHours(2);
      // Fetch exercises from next 2 hours
      upcomingExercises = await getExercisesInNextHours(2);
      // Fetch boluses from past 3 hours
      recentBoluses = await getBolusesInLastHours(3);
      // Fetch current glucose data
      await _userService.fetchCurrentGlucose();

      // Fetch correction and carb ratios
      correctionRatio =
          await _userService.getUserAttribute('correctionRatio') as double?;
      carbRatio = await _userService.getUserAttribute('carbRatio') as double?;

      print("Correction Ratio: $correctionRatio, Carb Ratio: $carbRatio");

      // Listen to glucose stream
      _userService.glucoseStream.listen(
        (value) {
          setState(() {
            currentBG = value;
            Gsource = "CGM";
            _glucoseController.text = value.toString();
          });
          print("Fetched Glucose Level: $value");
        },
        onError: (error) {
          setState(() {
            currentBG = null;
            _glucoseController.text = '';
          });
          print("Error in Glucose Stream: $error");
        },
      );

      _userService.arrowStream.listen(
        (value) {
          setState(() {
            trendArrow = value;
          });
          print("Fetched Trend Arrow: $value");
        },
        onError: (error) {
          setState(() {
            trendArrow = null;
          });
          print("Error in Arrow Stream: $error");
        },
      );

      // Fetch "manual" glucose readings within the last 15 minutes
      final Stream<List<GlucoseReading>> glucoseStream =
          _userService.getGlucoseReadingsStream(source: 'manual');

      // Get the most recent snapshot from the stream
      final List<GlucoseReading> readings = await glucoseStream.first;

      // Calculate the cutoff time
      final DateTime now = DateTime.now();
      final DateTime cutoffTime = now.subtract(const Duration(minutes: 15));

      // Filter readings within the last 15 minutes
      final List<GlucoseReading> recentReadings = readings
          .where((reading) => reading.time.isAfter(cutoffTime))
          .toList();

      // Update `currentBG` if there are recent readings
      if (recentReadings.isNotEmpty) {
        setState(() {
          currentBG = recentReadings.last.reading;
          Gsource = "manual";
        });
        print("Recent Manual Glucose Reading: ${recentReadings.last.reading}");
      }
    } catch (e) {
      print('Error in _fetchData: $e');
      setState(() {
        currentBG = null;
        trendArrow = null;
        correctionRatio = null;
        carbRatio = null;
      });
    }
  }

  Future<double> mealCorrectionDose() async {
    try {
      if (currentBG == null || correctionRatio == null) {
        return -1;
      }

      // Set target BG
      double targetBG = 120.0;
      double corrDose = 0.0;

      // First: BG higher than 120
      if (currentBG! > targetBG) {
        print('currentBG is larger than targetBG');
        // Second: Check for boluses in last 3 hours
        bool hadRecentBolus = await checkBolusInLastHours();

        if (!hadRecentBolus) {
          print('no boluses in last 3 hours');

          // Third: Check for hypos in last 3 hours
          bool hadHypo = await checkHypoInLastHours();

          if (!hadHypo) {
            print('no hypos in last 3 hours');
            // Fourth: Exercise in past 1 hour
            List<Workout> recentWorkouts = await getExercisesInLastHours(1);

            if (recentWorkouts.isEmpty) {
              print('no recentWorkouts in last 1 hour');
              double? tempCF = 0.0;
              try {
                log('Corr: Calculating correction factor...');
                tempCF =
                    await correctionFactorCalculator.calculateCorrectionFactor({
                  'time_of_day': DateFormat.Hm().format(DateTime.now()),
                  'blood_glucose': currentBG!,
                  'weighted_exercise_sum': await calculateWeightedExerciseSum(),
                });
                if (tempCF != null) {
                  if (tempCF >= 30 && tempCF <= 70) {
                    correctionRatio = tempCF;
                  }
                }
              } catch (e) {
                log('Corr: Error calculating correction factor: $e');
                correctionRatio = correctionRatio!;
              }

              // Calculate correction dose
              corrDose = (currentBG! - targetBG) / correctionRatio!;
              return corrDose;
            }
          }
        }
      }
      return 0.0;
    } catch (e) {
      print('Error in calculateing CorrectionDose: $e');
      return -1;
    }
  }

  Future<bool> checkBolusInLastHours() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime threeHoursAgo = now.subtract(const Duration(hours: 3));
      final completer = Completer<bool>();
      _userService.getInsulinDosagesStream().listen(
        (List<InsulinDosage> dosages) {
          final recentBoluses = dosages.where((dosage) =>
              dosage.type.toLowerCase() == 'bolus' &&
              dosage.time.isAfter(threeHoursAgo));

          completer.complete(recentBoluses.isNotEmpty);
        },
        onError: (error) {
          completer.complete(false);
        },
      );

      return completer.future;
    } catch (e) {
      print('Error checking for recent boluses: $e');
      return false;
    }
  }

  Future<bool> checkHypoInLastHours() async {
    try {
      final List<GlucoseReading> allReadings =
          await _userService.getGlucoseReadings();

      // Get the timestamp for 3 hours ago
      DateTime now = DateTime.now();
      DateTime threeHoursAgo = now.subtract(Duration(hours: 3));

      // Filter readings from the last 3 hours
      final past3HoursReadings = allReadings.where((reading) {
        return reading.time.isAfter(threeHoursAgo) &&
            reading.time.isBefore(now);
      }).toList();

      // Check if any reading is below 70
      for (var reading in past3HoursReadings) {
        if (reading.reading < 70) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error fetching glucose data: $e');
      return false;
    }
  }

  Future<List<Workout>> getExercisesInLastHours(int hours) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime checkTime = now.subtract(Duration(hours: hours));

      final Completer<List<Workout>> completer = Completer<List<Workout>>();

      _userService.getWorkoutsStream().listen(
        (List<Workout> workouts) {
          final List<Workout> recentWorkouts = workouts.where((workout) {
            DateTime workoutEndTime =
                workout.time.add(Duration(minutes: workout.duration));

            return workoutEndTime.isAfter(checkTime) &&
                workoutEndTime.isBefore(now);
          }).toList();

          completer.complete(recentWorkouts);
        },
        onError: (error) {
          completer.completeError(error);
        },
      );

      return completer.future;
    } catch (e) {
      print('Error fetching recent exercises: $e');
      return [];
    }
  }

  Future<List<Workout>> getExercisesInNextHours(int hours) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime checkTime = now.add(Duration(hours: hours));

      final Completer<List<Workout>> completer = Completer<List<Workout>>();

      _userService.getWorkoutsStream().listen(
        (List<Workout> workouts) {
          final List<Workout> upcomingWorkouts = workouts.where((workout) {
            return workout.time.isAfter(now) &&
                workout.time.isBefore(checkTime);
          }).toList();
          completer.complete(upcomingWorkouts);
        },
        onError: (error) {
          completer.completeError(error);
        },
      );

      return completer.future;
    } catch (e) {
      print('Error fetching upcoming exercises: $e');
      return [];
    }
  }

  Future<List<InsulinDosage>> getBolusesInLastHours(int hours) async {
    try {
      final DateTime now = DateTime.now();
      final DateTime checkTime = now.subtract(Duration(hours: hours));

      final List<InsulinDosage> dosages =
          await _userService.getInsulinDosages();
      return dosages
          .where((dosage) =>
              dosage.type.toLowerCase() == 'bolus' &&
              dosage.time.isAfter(checkTime))
          .toList();
    } catch (e) {
      print('Error fetching recent boluses: $e');
      return [];
    }
  }

  Future<double> calculateWeightedExerciseSum() async {
    try {
      var referenceTime = DateTime.now();
      // Fetch exercise data from the 16 hours prior to the reference time
      DateTime exerciseStartTime = referenceTime.subtract(Duration(hours: 16));
      List<Workout> workouts = await _userService.getWorkoutsStream().first;

      List<Map<String, dynamic>> exerciseData = workouts
          .where((workout) =>
              workout.time.isAfter(exerciseStartTime) &&
              workout.time.isBefore(referenceTime))
          .map((workout) {
        int intensityCode;
        switch (workout.intensity) {
          case 'High':
            intensityCode = 6;
            break;
          case 'Moderate':
            intensityCode = 3;
            break;
          case 'Low':
            intensityCode = 1;
            break;
          default:
            intensityCode = 0;
        }
        return {
          'time': workout.time,
          'duration': workout.duration.toDouble(),
          'intensity': intensityCode,
        };
      }).toList();

      // Calculate weighted exercise sum
      double weightedExerciseSum = 0.0;
      for (var exercise in exerciseData) {
        DateTime exerciseTime = exercise['time'];
        double duration = exercise['duration'];
        int intensity = exercise['intensity'];
        double timeDifference =
            referenceTime.difference(exerciseTime).inMinutes.toDouble();

        if (timeDifference > 0) {
          weightedExerciseSum += (intensity * duration) / timeDifference;
        }
      }

      return weightedExerciseSum;
    } catch (e) {
      print('Error calculating weighted exercise sum: $e');
      return 0.0;
    }
  }

  double roundInsulinDose(double dose) {
    try {
      double decimalPart = dose % 1;
      if (decimalPart <= 0.3) {
        return dose.floor().toDouble();
      }
      if (decimalPart >= 0.4 && decimalPart <= 0.7) {
        return dose.floor() + 0.5;
      }
      return dose.ceil().toDouble();
    } catch (e) {
      print('Error rounding insulin dose: $e');
      return dose;
    }
  }

  List<InsulinDosage> roundInsulinDoses(List<InsulinDosage> doses) {
    try {
      return doses
          .map((insulin) => InsulinDosage(
                type: "Bolus",
                dosage: roundInsulinDose(insulin.dosage),
                time: insulin.time,
                title: insulin.title,
                isRecommended: true,
              ))
          .toList();
    } catch (e) {
      print('Error rounding insulin doses: $e');
      return doses;
    }
  }

  Future<List<InsulinDosage>> calculateMealDose() async {
    try {
      await Future.delayed(Duration(seconds: 1));

      if (widget.currentMeal == null) {
        print("no meal");
        return [];
      }

      // Get meal components
      double carbs = widget.currentMeal!.totalCarb;
      double fat = widget.currentMeal!.totalFat;
      double protein = widget.currentMeal!.totalProtein;

      DateTime mealtime = widget.currentMeal!.time;

      // Base carb calculation
      double carbDose = carbs / carbRatio!;
      print("carb Dose: $carbDose");

      // Get correction dose
      final double correctionDose = await mealCorrectionDose();
      print("correction Dose: $correctionDose");

      if (correctionDose < 0) {
        throw Exception('Unable to calculate correction dose');
      }

      double mealDose;
      List<Workout> recentWorkouts = await getExercisesInLastHours(2);
      List<Workout> futureWorkouts = await getExercisesInNextHours(2);
      bool hasExercise = futureWorkouts.isNotEmpty || recentWorkouts.isNotEmpty;

      if (fat >= 40) {
        mealDose = futureWorkouts.isNotEmpty
            ? carbDose + correctionDose
            : (carbDose + correctionDose) * 1.25;
        return processMealDose(mealDose, splitDose: !futureWorkouts.isNotEmpty);
      } else if (protein >= 40 && fat >= 30) {
        mealDose = hasExercise
            ? carbDose + correctionDose
            : (carbDose + correctionDose) * 1.25;
        return processMealDose(mealDose);
      } else {
        mealDose = hasExercise
            ? (carbDose + correctionDose) / 2
            : (carbDose + correctionDose);
        List<InsulinDosage> doses = await processMealDose(mealDose);

        int minutesToBolus = getMinutesToBolus();
        final updatedTime =
            widget.currentMeal!.time.add(Duration(minutes: minutesToBolus));

        // Only update if the time actually changed
        if (updatedTime != newMealTime) {
          setState(() {
            newMealTime = updatedTime;
          });

          await _userService.updateMeal(
            mealId: widget.mealId!,
            newTime: updatedTime,
          );
        }
        await _userService.updateMeal(
            mealId: widget.mealId!, newTime: newMealTime);

        return doses;
      }
    } catch (e) {
      print('Error calculating meal dose: $e');
      return [];
    }
  }

  // Function to process insulin dosage with splitting
  Future<List<InsulinDosage>> processMealDose(double mealDose,
      {bool splitDose = false}) async {
    print("meal dose before rounding: $mealDose");

    if (splitDose) {
      double halfDose = mealDose / 2;
      print("half meal dose before rounding: $halfDose");

      InsulinDosage dose1 = createInsulinDosage(halfDose, DateTime.now());
      InsulinDosage dose2 = createInsulinDosage(
          halfDose, DateTime.now().add(Duration(hours: 1)), false);

      return roundInsulinDoses([dose1, dose2]);
    } else {
      InsulinDosage dose = createInsulinDosage(mealDose, DateTime.now());
      return roundInsulinDoses([dose]);
    }
  }

  // Function to create InsulinDosage object
  InsulinDosage createInsulinDosage(double dosage, DateTime time,
      [bool includeCurrentBG = true]) {
    return InsulinDosage(
      title: 'Meal Bolus',
      type: "Bolus",
      dosage: dosage,
      time: time,
      isRecommended: true,
    );
  }

  int getMinutesToBolus() {
    if (currentBG! >= 70 && currentBG! <= 109) {
      switch (trendArrow) {
        case 1:
        case 2:
          return 0;
        case 3:
          return 15;
        case 4:
          return 20;
        case 5:
          return 25;
        default:
          return 15;
      }
    } else if (currentBG! >= 110 && currentBG! <= 179) {
      switch (trendArrow) {
        case 1:
          return 10;
        case 2:
          return 15;
        case 3:
          return 20;
        case 4:
          return 25;
        case 5:
          return 30;
        default:
          return 15;
      }
    } else if (currentBG! >= 180 && currentBG! <= 250) {
      switch (trendArrow) {
        case 1:
          return 20;
        case 2:
          return 25;
        case 3:
          return 30;
        case 4:
          return 35;
        case 5:
          return 40;
        default:
          return 25;
      }
    } else if (currentBG! > 250) {
      switch (trendArrow) {
        case 1:
          return 25;
        case 2:
          return 30;
        case 3:
          return 40;
        case 4:
          return 45;
        case 5:
          return 50;
        default:
          return 30;
      }
    } else {
      throw ArgumentError('Invalid currentBG value');
    }
  }

  @override
  Widget build(BuildContext context) {
    String arrowSymbol = '';

    // Convert trend arrow number to symbol
    if (trendArrow != null) {
      switch (trendArrow) {
        case 1:
          arrowSymbol = '↓';
          break;
        case 2:
          arrowSymbol = '↘';
          break;
        case 3:
          arrowSymbol = '→';
          break;
        case 4:
          arrowSymbol = '↗';
          break;
        case 5:
          arrowSymbol = '↑';
          break;
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(23.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //Current glucose and trend
            Align(
              alignment: AlignmentDirectional(0, 0),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 23.0, bottom: 25.0, left: 0.0, right: 0.0),
                child: Container(
                  width: 357,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    shape: BoxShape.rectangle,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Recommended Dose',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  letterSpacing: 0,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildCardDose(),
            const SizedBox(height: 10),
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        elevation: 5,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Clear the global variables
                        globals.globalDecimal = 0.0;
                        globals.globalTime1 = DateTime.now();
                        globals.globalTime2 = DateTime.now();
                        globals.globalInteger = 0.0;
                        globals.globalDecimal11 = 0.0;
                        globals.globalTime11 = DateTime.now();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => MainNavigation()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Add Button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 5,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          // Fetch the current doses
                          final doses = await calculateMealDose();
                          InsulinDosage? dose1;
                          InsulinDosage? dose2;

                          if (doses.length == 1) {
                            dose1 = doses[0];
                          } else if (doses.length == 2) {
                            dose1 = doses[0];
                            dose2 = doses[1];
                          }
                          // Compare the doses with global values
                          double updatedDosage = dose1!.dosage;
                          DateTime updatedTime = dose1!.time;
                          // DateTime updatedTime3 = dose2!.time;
                          DateTime updatedTime2 = widget.currentMeal!.time;
                          bool updatedisRecommended = dose1.isRecommended!;

                          // Check if globalDecimal is different
                          if (globals.globalDecimal != 0.0 &&
                              globals.globalDecimal != dose1.dosage) {
                            updatedDosage = globals.globalDecimal;
                            updatedisRecommended = false;
                          }

                          if (globals.globalTime1 != DateTime.now() &&
                              globals.globalTime1 != dose1.time) {
                            updatedTime = globals.globalTime1;
                          }

                          if (globals.globalTime2 != DateTime.now() &&
                              globals.globalTime2 != widget.currentMeal!.time) {
                            updatedTime2 = globals.globalTime2;
                          }

                          // Create a new InsulinDosage object with the updated dosage
                          dose1 = InsulinDosage(
                            type: dose1.type,
                            dosage: updatedDosage,
                            time: updatedTime,
                            title: dose1.title,
                            isRecommended: updatedisRecommended,
                          );

                          await _userService.addInsulinDosage(dose1);

                          if (dose2 != null) {
                            double updatedDosage2 = dose2.dosage;
                            DateTime updatedTime3 = dose2.time;
                            bool updatedisRecommended = dose2.isRecommended!;

                            // Check if globalDecimal is different
                            if (globals.globalDecimal11 != 0.0 &&
                                globals.globalDecimal11 != dose2.dosage) {
                              updatedDosage = globals.globalDecimal;
                              updatedisRecommended = false;
                            }

                            if (globals.globalTime11 != DateTime.now() &&
                                globals.globalTime11 != dose2.time) {
                              updatedTime3 = globals.globalTime11;
                            }

                            // Create a new InsulinDosage object with the updated dosage
                            dose2 = InsulinDosage(
                              type: dose2.type,
                              dosage: updatedDosage2,
                              time: updatedTime3,
                              title: dose2.title,
                              isRecommended: updatedisRecommended,
                            );

                            await _userService.addInsulinDosage(dose2);
                          }

                          // Clear the global variables
                          globals.globalDecimal = 0.0;
                          globals.globalTime1 = DateTime.now();
                          globals.globalTime2 = DateTime.now();
                          globals.globalInteger = 0.0;
                          globals.globalDecimal11 = 0.0;
                          globals.globalTime11 = DateTime.now();

                          // Navigate to MainNavigation
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => MainNavigation()),
                            (route) => false,
                          );
                        } catch (e) {
                          print('Error adding insulin doses: $e');
                        }
                      },
                      child: Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 0.0, 40.0, 2.0),
                child: const Text(
                  'This dose is based on these factors:',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Color.fromARGB(255, 120, 120, 120),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 10.0, bottom: 10.0, left: 0.0, right: 0.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 5,
                      color: Color(0x230E151B),
                      offset: Offset(0.0, 2),
                    )
                  ],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 12, 0, 9),
                        child: Text(
                          'Current Glucose',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 10.0, bottom: 10.0, left: 0.0, right: 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsetsDirectional
                                                        .fromSTEB(0, 0, 5, 0),
                                                child: SizedBox(
                                                  width: 20,
                                                  child: TextFormField(
                                                    key: ValueKey(currentBG),
                                                    initialValue: currentBG
                                                            ?.toStringAsFixed(
                                                                1) ??
                                                        '',
                                                    autofocus: false,
                                                    obscureText: false,
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                        borderSide: BorderSide(
                                                          color: const Color
                                                              .fromARGB(255,
                                                              168, 167, 167),
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                        borderSide:
                                                            const BorderSide(
                                                          color: Color.fromARGB(
                                                              255,
                                                              168,
                                                              167,
                                                              167),
                                                          width: 1.0,
                                                        ),
                                                      ),
                                                      errorBorder:
                                                          OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                          width: 1,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      filled: true,
                                                      fillColor:
                                                          Colors.grey[100],
                                                    ),
                                                    style: const TextStyle(
                                                      fontFamily: 'Manrope',
                                                      letterSpacing: 0.0,
                                                    ),
                                                    onChanged: (value) {
                                                      if (_debounce?.isActive ??
                                                          false)
                                                        _debounce!.cancel();
                                                      _debounce = Timer(
                                                          const Duration(
                                                              milliseconds:
                                                                  1500),
                                                          () async {
                                                        try {
                                                          globals.globalInteger =
                                                              double.parse(
                                                                  value);
                                                          print(
                                                              'Updated globalInteger: ${globals.globalInteger}');

                                                          // Refresh the page and recalculate doses
                                                          setState(() {
                                                            currentBG = globals
                                                                .globalInteger;
                                                            //correctionRatio = globals.cfg;
                                                          });
                                                          final updatedDoses =
                                                              await calculateMealDose();
                                                          print(
                                                              'Doses recalculated with updated glucose level: $updatedDoses');
                                                        } catch (e) {
                                                          print(
                                                              'Error parsing input: $e');
                                                        }
                                                      });
                                                    },
                                                    cursorColor:
                                                        Theme.of(context)
                                                            .primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(0, 0, 30, 0),
                                                child: trendArrow != null
                                                    ? Column(
                                                        children: [
                                                          Icon(
                                                            ArrowIconMapper
                                                                .getIcon(
                                                                    trendArrow!),
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                            size: 35.0,
                                                          ),
                                                          Text(
                                                            'mg/dL',
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : Column(
                                                        children: [
                                                          Text(
                                                            '-',
                                                            style: TextStyle(
                                                              fontSize: 35,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                          Text(
                                                            'mg/dL',
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      )),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(0, 0, 20, 0),
                                              child: Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: "Source: ",
                                                      style: TextStyle(
                                                        fontFamily: 'Manrope',
                                                        fontSize: 17,
                                                        color: Color.fromARGB(
                                                            217, 14, 21, 27),
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: (Gsource ??
                                                                  'manual') ==
                                                              'manual'
                                                          ? 'Manual'
                                                          : 'CGM',
                                                      style: TextStyle(
                                                        fontFamily: 'Manrope',
                                                        fontSize: 17,
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 10.0, bottom: 10.0, left: 0.0, right: 0.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 5,
                      color: Color(0x230E151B),
                      offset: Offset(0.0, 2),
                    )
                  ],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(16, 12, 0, 9),
                        child: Text(
                          'Correction Factor',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 20,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20.0, 5.0, 20.0, 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 250,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0, 0, 5, 0),
                                child: SizedBox(
                                  width: 20,
                                  child: TextFormField(
                                    key: ValueKey(correctionRatio),
                                    initialValue:
                                        correctionRatio?.toStringAsFixed(1) ??
                                            ' ',
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                              255, 168, 167, 167),
                                          width: 1.0,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        borderSide: const BorderSide(
                                          color: Color.fromARGB(
                                              255, 168, 167, 167),
                                          width: 1.0,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      letterSpacing: 0.0,
                                    ),
                                    onChanged: (value) {
                                      if (_debounce?.isActive ?? false)
                                        _debounce!.cancel();
                                      _debounce = Timer(
                                          const Duration(milliseconds: 1500),
                                          () async {
                                        try {
                                          globals.globalInteger =
                                              double.parse(value);
                                          setState(() {
                                            currentBG = globals.globalInteger;
                                          });
                                          final updatedDoses =
                                              await calculateMealDose();
                                        } catch (e) {
                                          print('Error parsing input: $e');
                                        }
                                      });
                                    },
                                    cursorColor: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              'mg/dL',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildMealSection(),
            _buildExerciseSection(),
            _buildBolusSection(),
          ],
        ),
      ),
    );
  }

  // Helper function to display workout list
  Widget _buildWorkoutList(List<Workout> workouts, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...workouts.map((workout) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout: ${workout.title}',
                      style: TextStyle(fontSize: 16)),
                  Text('Intensity: ${workout.intensity}',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
                  Text('Duration: ${workout.duration} minutes',
                      style: TextStyle(fontSize: 14, color: Colors.blueGrey)),
                  const SizedBox(height: 8),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildMealSection() {
    if (widget.currentMeal == null) {
      return _buildCard(
        title: "Meal",
        content: Text("No meal found"),
      );
    }
    return _buildCard(
      title: "Meal",
      content: ExpandableItem(
        dataType: "meal",
        title: widget.currentMeal!.title,
        time: DateFormat('HH:mm').format(newMealTime),
        key: ValueKey(newMealTime.toIso8601String()),
        otherAttributes: {
          "foodItems": widget.currentMeal!.foodItems,
          "totalCarb": widget.currentMeal!.totalCarb,
          "totalProtein": widget.currentMeal!.totalProtein,
          "totalFat": widget.currentMeal!.totalFat,
          "totalCalorie": widget.currentMeal!.totalCalorie,
          "mealId": widget.currentMeal!.id,
        },
      ),
    );
  }

  Widget _buildExerciseSection() {
    List<Workout> allExercises = [...recentExercises, ...upcomingExercises];

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCard(
            title: "Exercises",
            content: Column(
              children: [
                if (allExercises.isNotEmpty)
                  ...allExercises.map((workout) {
                    return ExpandableItem(
                      title: workout.title,
                      time: DateFormat('HH:mm')
                          .format(workout.time), // Format time
                      otherAttributes: {
                        'duration': workout.duration,
                        'intensity': workout.intensity,
                        'type': workout.source,
                      },
                      dataType: 'Workout',
                    );
                  }).toList()
                else
                  // Message when no exercises are found
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 10.0),
                    child: Column(
                      children: [
                        Text(
                          "No recent or upcoming exercises. Tap + to log one!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 0),
                      ],
                    ),
                  ),

                // Circular "+" Button at the bottom of the card
                SizedBox(height: 0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddPhysicalActivity(
                            fromDosePage: true,
                            currentMeal: widget.currentMeal,
                            mealId: widget.mealId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(), // Makes the button circular
                    padding: EdgeInsets.all(0), // Adjust padding for size
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary, // Background color
                    foregroundColor: Colors.white,
                  ),
                  child: Icon(Icons.add, size: 25),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBolusSection() {
    return _buildCard(
      title: "Bolus",
      content: Column(
        children: [
          if (recentBoluses.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
              child: Column(
                children: [
                  ...recentBoluses.map((insulin) {
                    return ExpandableItem(
                      title: insulin.title,
                      time: DateFormat('HH:mm').format(insulin.time),
                      otherAttributes: {
                        'type': insulin.type,
                        'dosage': insulin.dosage,
                      },
                      dataType: 'InsulinDosage',
                    );
                  }).toList(),
                ],
              ),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 15.0),
              child: Column(
                children: [
                  Text(
                    "No recent bolus recorded. Tap + to log one!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 0),
                ],
              ),
            ),
          SizedBox(height: 0),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddInsulin(
                      fromDosePage: true,
                      currentMeal: widget.currentMeal,
                      mealId: widget.mealId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(0),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Icon(Icons.add, size: 25),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                blurRadius: 5, color: Color(0x230E151B), offset: Offset(0, 2))
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 10),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDose() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        constraints: BoxConstraints(minWidth: double.infinity),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                blurRadius: 5, color: Color(0x230E151B), offset: Offset(0, 2))
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recommended Dose",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 10),
              FutureBuilder<List<InsulinDosage>>(
                future: calculateMealDose(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final doses = snapshot.data!;

                    if (doses.length == 1) {
                      final dose = doses[0];
                      return Column(
                        children: [
                          buildDoseRow(context, dose, false, false),
                        ],
                      );
                    } else if (doses.length == 2) {
                      final dose1 = doses[0];
                      final dose2 = doses[1];
                      return Column(
                        children: [
                          buildDoseRow(context, dose1, true, false),
                          SizedBox(height: 16),
                          buildDoseRow(context, dose2, true, true),
                        ],
                      );
                    } else {
                      return Text('Unexpected number of doses');
                    }
                  } else {
                    return Text('No doses calculated');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userService.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _textFieldFocusNode.dispose();
    _timeController.dispose();
    _timeController2.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget buildDoseRow(BuildContext context, InsulinDosage dose, bool thereIsTwo,
      bool isSecondDose) {
    if (thereIsTwo == false) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: globals.globalDecimal == 0.0
                    ? dose.dosage.toStringAsFixed(1)
                    : globals.globalDecimal.toStringAsFixed(1),
                readOnly: false,
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.background,
                ),
                style: TextStyle(fontFamily: 'Manrope'),
                onChanged: (value) {
                  try {
                    globals.globalDecimal = double.parse(value);
                    print('Updated globalDecimal: ${globals.globalDecimal}');
                  } catch (e) {
                    print('Error parsing input: $e');
                  }
                },
              ),
            ),
            SizedBox(width: 5),
            Text('Unit', style: TextStyle(fontFamily: 'Manrope')),
            SizedBox(width: 30),
            Text('At:', style: TextStyle(fontFamily: 'Manrope')),
            SizedBox(width: 5),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _timeController,
                readOnly: true,
                decoration: InputDecoration(
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.background,
                ),
                style: TextStyle(fontFamily: 'Manrope'),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(dose.time),
                  );

                  if (pickedTime != null) {
                    dose.time = DateTime(
                      dose.time.year,
                      dose.time.month,
                      dose.time.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    _timeController.text =
                        DateFormat('HH:mm').format(dose.time);
                    globals.globalTime1 = dose.time;
                    log('Updated globalTime1: ${globals.globalTime1}');
                  }
                },
              ),
            ),
          ],
        ),
      );
    } else {
      if (isSecondDose == false) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('1st:',
                  style: TextStyle(
                      fontFamily: 'Manrope', fontWeight: FontWeight.bold)),
              SizedBox(width: 5),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: globals.globalDecimal == 0.0
                      ? dose.dosage.toStringAsFixed(1)
                      : globals.globalDecimal.toStringAsFixed(1),
                  readOnly: false,
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                  ),
                  style: TextStyle(fontFamily: 'Manrope'),
                  onChanged: (value) {
                    try {
                      globals.globalDecimal = double.parse(value);
                      print('Updated globalDecimal: ${globals.globalDecimal}');
                    } catch (e) {
                      print('Error parsing input: $e');
                    }
                  },
                ),
              ),
              SizedBox(width: 5),
              Text('Unit', style: TextStyle(fontFamily: 'Manrope')),
              SizedBox(width: 30),
              Text('At:', style: TextStyle(fontFamily: 'Manrope')),
              SizedBox(width: 5),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                  ),
                  style: TextStyle(fontFamily: 'Manrope'),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(dose.time),
                    );

                    if (pickedTime != null) {
                      dose.time = DateTime(
                        dose.time.year,
                        dose.time.month,
                        dose.time.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      _timeController.text =
                          DateFormat('HH:mm').format(dose.time);
                      globals.globalTime1 = dose.time;
                      log('Updated globalTime1: ${globals.globalTime1}');
                    }
                  },
                ),
              ),
            ],
          ),
        );
      } else {
        _timeController2 = TextEditingController(
          text: DateFormat('HH:mm').format(dose.time),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('2ed:',
                  style: TextStyle(
                      fontFamily: 'Manrope', fontWeight: FontWeight.bold)),
              SizedBox(width: 5),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: globals.globalDecimal11 == 0.0
                      ? dose.dosage.toStringAsFixed(1)
                      : globals.globalDecimal11.toStringAsFixed(1),
                  readOnly: false,
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                  ),
                  style: TextStyle(fontFamily: 'Manrope'),
                  onChanged: (value) {
                    try {
                      globals.globalDecimal11 = double.parse(value);
                      print(
                          'Updated globalDecimal11: ${globals.globalDecimal11}');
                    } catch (e) {
                      print('Error parsing input: $e');
                    }
                  },
                ),
              ),
              SizedBox(width: 5),
              Text('Unit', style: TextStyle(fontFamily: 'Manrope')),
              SizedBox(width: 30),
              Text('At:', style: TextStyle(fontFamily: 'Manrope')),
              SizedBox(width: 5),
              SizedBox(
                width: 100,
                child: TextFormField(
                  controller: _timeController2,
                  readOnly: true,
                  decoration: InputDecoration(
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.background,
                  ),
                  style: TextStyle(fontFamily: 'Manrope'),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(dose.time),
                    );

                    if (pickedTime != null) {
                      dose.time = DateTime(
                        dose.time.year,
                        dose.time.month,
                        dose.time.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                      _timeController2.text =
                          DateFormat('HH:mm').format(dose.time);
                      globals.globalTime11 = dose.time;
                      log('Updated globalTime11: ${globals.globalTime11}');
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

class ExpandableItem extends StatefulWidget {
  final String title;
  final String time;
  final Map<String, dynamic> otherAttributes;
  final String dataType;

  const ExpandableItem({
    required this.title,
    required this.time,
    required this.otherAttributes,
    Key? key,
    required this.dataType,
  }) : super(key: key);

  @override
  _ExpandableItemState createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem> {
  bool _isExpanded = false;
  late TextEditingController _timeController;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(
      text: widget.time ?? '',
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  IconData _getIconForDataType(String dataType) {
    switch (dataType) {
      case 'Note':
        return Icons.note;
      case 'Workout':
        return Icons.fitness_center;
      case 'InsulinDosage':
        return FontAwesomeIcons.syringe;
      case 'GlucoseReading':
        return Icons.bloodtype;
      case 'Carbohydrate':
        return Icons.fastfood;
      case 'meal':
        return Icons.fastfood;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffF5F5F5),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            title: Row(
              children: [
                Icon(
                  _getIconForDataType(widget.dataType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (widget.dataType == 'meal')
                  SizedBox(
                    width: 70,
                    child: TextField(
                        controller: _timeController,
                        readOnly: true,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: const BorderSide(
                                color: Colors.grey, width: 1.0),
                          ),
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onTap: () async {
                          // Default fallback time
                          TimeOfDay initialTime = TimeOfDay.now();

                          try {
                            final text = _timeController.text;
                            print("Current time text: '$text'");

                            // Only parse if it's not empty
                            if (text.isNotEmpty) {
                              DateTime parsedTime =
                                  DateFormat('HH:mm').parseStrict(text);
                              initialTime = TimeOfDay.fromDateTime(parsedTime);
                              print(
                                  "Parsed initial time: ${initialTime.format(context)}");
                            }
                          } catch (e) {
                            print(
                                "Failed to parse initial time, using current time. Error: $e");
                          }

                          try {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );

                            if (pickedTime != null) {
                              final now = DateTime.now();
                              final newDateTime = DateTime(
                                now.year,
                                now.month,
                                now.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );

                              final formattedTime =
                                  DateFormat('HH:mm').format(newDateTime);

                              setState(() {
                                _timeController.text = formattedTime;
                              });

                              log('Meal ID: ${widget.otherAttributes['mealId']}');

                              await _userService.updateMeal(
                                mealId: widget.otherAttributes['mealId'],
                                newTime: DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                ),
                              );

                              print("New meal time updated: $formattedTime");
                            } else {
                              print("User cancelled time picker.");
                            }
                          } catch (e) {
                            print("Error during time picking or update: $e");
                          }
                        }),
                  )
                else
                  Text(
                    widget.time,
                    style: const TextStyle(fontSize: 14),
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded) _buildExpandedView(),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.otherAttributes.entries
              .where((entry) =>
                  entry.value != null &&
                  entry.value.toString().isNotEmpty &&
                  !['totalCarb', 'totalProtein', 'totalFat', 'totalCalorie']
                      .contains(entry.key))
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entry.key != 'comment')
                        Text(
                          entry.key == 'foodItems'
                              ? 'Added Ingredients'
                              : '${capitalizeFirstLetter(entry.key)} ',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          getTextForEntry(entry),
                          textAlign: entry.key == 'comment'
                              ? TextAlign.left
                              : TextAlign.right,
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          if (widget.dataType == 'meal') ...[
            Divider(),
            // Show nutritional totals for meals
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Carbs'),
                    Text(
                        '${widget.otherAttributes['totalCarb']?.toStringAsFixed(1)} g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Protein'),
                    Text(
                        '${widget.otherAttributes['totalProtein']?.toStringAsFixed(1)} g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Fat'),
                    Text(
                        '${widget.otherAttributes['totalFat']?.toStringAsFixed(1)} g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Calories'),
                    Text(
                        '${widget.otherAttributes['totalCalorie']?.toStringAsFixed(1)} kcal'),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String getTextForEntry(MapEntry<String, dynamic> entry) {
  String result;

  switch (entry.key) {
    case 'duration':
      int minutes = entry.value;
      result = '${minutes} Minutes';
      break;

    case 'dosage':
      result = '${entry.value} Units';
      break;

    case 'reading':
      result = '${entry.value} mg/dL';
      break;

    case 'amount':
      result = '${entry.value} g';
      break;

    case 'type':
      if (entry.value == 'Bolus') {
        result = 'Short Acting';
      } else {
        result = 'Long Acting';
      }
      break;

    case 'totalCarb':
      result = '${entry.value.toStringAsFixed(1)} g';
      break;

    case 'totalProtein':
      result = '${entry.value.toStringAsFixed(1)} g';
      break;

    case 'totalFat':
      result = '${entry.value.toStringAsFixed(1)} g';
      break;

    case 'totalCalorie':
      result = '${entry.value.toStringAsFixed(1)} kcal';
      break;

    case 'foodItems':
      if (entry.value is List) {
        var foodItems = entry.value as List;

        if (foodItems.length == 1 && foodItems[0].portion == -1) {
          result = '-';
          break;
        }

        var validItems = foodItems
            .where((item) => item.portion != -1)
            .map((item) => '${item.name} (${item.portion}g)')
            .join('\n');

        result = validItems.isEmpty ? '-' : validItems;
      } else {
        result = '';
      }
      break;

    default:
      result = entry.value.toString();
  }

  return capitalizeFirstLetter(result);
}
