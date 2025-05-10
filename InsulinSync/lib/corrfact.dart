import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'excercise.dart';
import 'models/glucose_model.dart';
import 'models/insulin_model.dart';
import 'models/workout_model.dart';
import 'services/user_service.dart';
import 'dart:math' as math;

class CorrFact {
  final UserService _userService = UserService();

  List<InsulinDosage> insulinDosages = [];

  Future<List<InsulinDosage>> getBolusesInLast7Days() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime sevenDaysAgo = now.subtract(Duration(days: 7));

      final List<InsulinDosage> insulinDosages =
          await _userService.getInsulinDosages();
      return insulinDosages
          .where((insulinDosages) =>
              insulinDosages.type.toLowerCase() == 'bolus' &&
              insulinDosages.time.isAfter(sevenDaysAgo))
          .toList();
    } catch (e) {
      print('Corr: Error fetching boluses from the last 7 days: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _prepareFeatureVector() async {
    List<Map<String, dynamic>> featureVectors = [];

    DateTime now = DateTime.now();
    DateTime oneWeekAgo = now.subtract(Duration(days: 7));

    try {
      insulinDosages = await getBolusesInLast7Days();
      print('Corr: Insulin dosages in the last week: $insulinDosages');

      if (insulinDosages.isEmpty) {
        print('Corr: No insulin doses found in the last week.');
        return featureVectors;
      }

      for (var dosage in insulinDosages) {
        DateTime doseTime = dosage.time;
        double insulinDose = dosage.dosage.toDouble();

        // Fetch glucose readings
        List<GlucoseReading> glucoseReadings =
            (await _userService.getGlucoseReadingsStream().first);
        print('Corr: Glucose readings: $glucoseReadings');

        // Find closest glucose reading before insulin dose
        GlucoseReading? closestReading;
        Duration? smallestDifference;
        for (var reading in glucoseReadings) {
          Duration difference = doseTime.difference(reading.time).abs();
          if (smallestDifference == null || difference < smallestDifference) {
            smallestDifference = difference;
            closestReading = reading;
            print("Corr: Closest reading found: $closestReading");
          }
        }

        double bloodGlucose = closestReading?.reading?.toDouble() ?? 0.0;
        print("Corr: Blood glucose reading: $bloodGlucose");

        // Fetch exercise data from previous 16 hours
        DateTime exerciseStartTime = doseTime.subtract(Duration(hours: 16));
        List<Workout> workouts = await _userService.getWorkoutsStream().first;

        List<Map<String, dynamic>> exerciseData = workouts
            .where((workout) =>
                workout.time.isAfter(exerciseStartTime) &&
                workout.time.isBefore(doseTime))
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

        print("Corr: Exercise data: $exerciseData");

        // Calculate weighted exercise sum
        double weightedExerciseSum = 0.0;
        DateTime now = DateTime.now();
        for (var exercise in exerciseData) {
          DateTime exerciseTime = exercise['time'];
          double duration = exercise['duration'];
          int intensity = exercise['intensity'];
          double timeDifference =
              now.difference(exerciseTime).inMinutes.toDouble();

          if (timeDifference > 0) {
            weightedExerciseSum += (intensity * duration) / timeDifference;
          }
        }

        print("Corr: Weighted exercise sum: $weightedExerciseSum");

        // Calculate BG 3 hours after dose
        DateTime threeHoursLater = doseTime.add(Duration(hours: 3));
        List<GlucoseReading> postDoseReadings =
            await UserService().getGlucoseReadingsStream().first;

        GlucoseReading? postReading;
        Duration? postDifference;
        for (var reading in postDoseReadings) {
          Duration difference = threeHoursLater.difference(reading.time).abs();
          if (postDifference == null || difference < postDifference) {
            postDifference = difference;
            postReading = reading;
          }
        }

        double bgThreeHoursAfter = postReading?.reading?.toDouble() ?? 0.0;

        print("Corr: BG 3 hours after dose: $bgThreeHoursAfter");

        featureVectors.add({
          'time_of_day': DateFormat.Hm().format(doseTime),
          //'dose_datetime': doseTime,
          'blood_glucose': bloodGlucose,
          'insulin_dose': insulinDose,
          //'exercise_data': exerciseData,
          'weighted_exercise_sum': weightedExerciseSum,
          'bg_three_hours_after': bgThreeHoursAfter,
        });

        print("Corr: Feature vector added: ${featureVectors}");
      }

      return featureVectors;
    } catch (e) {
      print('Corr: Error in _prepareFeatureVector: $e');
      return featureVectors;
    }
  }

  List<Map<String, dynamic>> _findKNearestNeighbors(
    List<Map<String, dynamic>> featureVectors,
    Map<String, dynamic> currentState,
    int k,
  ) {
    List<Map<String, dynamic>> distances = [];

    for (var vector in featureVectors) {
      double timeOfDayDistance = _calculateTimeOfDayDistance(
          currentState['time_of_day'], vector['time_of_day']);
      double bloodGlucoseDistance =
          (currentState['blood_glucose'] - vector['blood_glucose']).abs();
      double exerciseDistance = (currentState['weighted_exercise_sum'] -
              vector['weighted_exercise_sum'])
          .abs();

      double euclideanDistance = math.sqrt(
        math.pow(timeOfDayDistance, 2) +
            math.pow(bloodGlucoseDistance, 2) +
            math.pow(exerciseDistance, 2),
      );

      distances.add({'vector': vector, 'distance': euclideanDistance});
    }

    distances.sort((a, b) => a['distance'].compareTo(b['distance']));

    return distances
        .take(k)
        .map<Map<String, dynamic>>((entry) => entry['vector'])
        .toList();
  }

  double _calculateTimeOfDayDistance(String time1, String time2) {
    DateTime parsedTime1 = DateFormat.Hm().parse(time1);
    DateTime parsedTime2 = DateFormat.Hm().parse(time2);
    int diff = (parsedTime1.difference(parsedTime2).inMinutes).abs();
    return math.min(diff, 1440 - diff).toDouble();
  }

  List<double> calculateCorrectionFactors(
      List<Map<String, dynamic>> neighbors) {
    List<double> correctionFactors = [];

    for (var neighbor in neighbors) {
      double bgThreeHoursAfter =
          neighbor['bg_three_hours_after']?.toDouble() ?? 0.0;
      double insulinDose = neighbor['insulin_dose']?.toDouble() ?? 0.0;
      double bloodGlucose = neighbor['blood_glucose']?.toDouble() ?? 0.0;

      if (bgThreeHoursAfter != 0.0 && insulinDose > 0) {
        double factor = (bloodGlucose - bgThreeHoursAfter) / insulinDose;
        correctionFactors.add(factor);
      }
    }

    if (correctionFactors.isEmpty) {
      print('Corr: No correction factors calculated.');
    }

    return correctionFactors;
  }

  double predictCorrectionFactor(
    List<Map<String, dynamic>> neighbors,
    List<Map<String, dynamic>> distances,
  ) {
    double numerator = 0.0;
    double denominator = 0.0;

    for (int i = 0; i < neighbors.length; i++) {
      List<double> factors = calculateCorrectionFactors([neighbors[i]]);
      if (factors.isEmpty) {
        print('Corr: No correction factors for neighbor $i.');
        continue;
      }

      double factor = factors.first;
      double distance = distances[i]['distance']?.toDouble() ?? 1.0;

      if (distance > 0) {
        numerator += (1 / distance) * factor;
        denominator += (1 / distance);
      }
    }

    if (denominator == 0) {
      print('Corr: No valid neighbors for prediction.');
      return 0.0;
    }

    return numerator / denominator;
  }

  Future<double> calculateCorrectionFactor(
      Map<String, dynamic> currentState) async {
    print("Corr: inside calculateCorrectionFactor: $currentState");

    int k = 5;
    List<Map<String, dynamic>> featureVectors = await _prepareFeatureVector();

    if (featureVectors.isEmpty) {
      print('Corr: No feature vectors available.');
      return 0.0;
    }

    List<Map<String, dynamic>> neighbors =
        _findKNearestNeighbors(featureVectors, currentState, k);
    if (neighbors.isEmpty) {
      print('Corr: No neighbors found.');
      return 0.0;
    }

    List<Map<String, dynamic>> distances =
        _findKNearestNeighbors(featureVectors, currentState, k);
    if (distances.isEmpty) {
      print('Corr: No distances calculated.');
      return 0.0;
    }

    return predictCorrectionFactor(neighbors, distances);
  }
}
