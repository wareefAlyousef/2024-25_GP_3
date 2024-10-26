import 'package:cloud_firestore/cloud_firestore.dart';

import 'glucose_model.dart';
import 'insulin_model.dart';
import 'note_model.dart';
import 'workout_model.dart';

// Not sure what is optional, will be modified
class UserModel {
  String firstName;
  String lastName;
  String email;
  bool gender;
  double weight;
  double height;
  DateTime dateOfBirth;
  double dailyBolus;
  double dailyBasal;
  double? carbRatio;
  double? correctionRatio;
  // String? patientId      later for the connection with the cgm
  List<GlucoseReading>? glucoseReadings;
  List<double>? carbohydrates;
  List<Note>? notes;
  List<InsulinDosage>? insulinDosages;
  List<Workout>? workouts;

  UserModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.weight,
    required this.height,
    required this.dateOfBirth,
    required this.dailyBolus,
    required this.dailyBasal,
    this.carbRatio,
    this.correctionRatio,
    this.glucoseReadings,
    this.carbohydrates,
    this.notes,
    this.insulinDosages,
    this.workouts,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String,
      gender: map['gender'] as bool,
      weight: map['weight'].toDouble(),
      height: map['height'].toDouble(),
      dateOfBirth: (map['dateOfBirth'] as Timestamp).toDate(),
      dailyBolus: map['dailyBolus'].toDouble(),
      dailyBasal: map['dailyBasal'].toDouble(),
      carbRatio: map['carbRatio']?.toDouble(),
      correctionRatio: map['correctionRatio']?.toDouble(),
      glucoseReadings: map['glucoseReadings'] != null
          ? (map['glucoseReadings'] as List<dynamic>)
              .map((item) =>
                  GlucoseReading.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
      carbohydrates: map['carbohydrates'] != null
          ? List<double>.from(map['carbohydrates'] as List<dynamic>)
          : [],
      notes: map['notes'] != null
          ? (map['notes'] as List<dynamic>)
              .map((item) => Note.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
      insulinDosages: map['insulinDosages'] != null
          ? (map['insulinDosages'] as List<dynamic>)
              .map(
                  (item) => InsulinDosage.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
      workouts: map['workouts'] != null
          ? (map['workouts'] as List<dynamic>)
              .map((item) => Workout.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'gender': gender,
      'weight': weight,
      'height': height,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'dailyBolus': dailyBolus,
      'dailyBasal': dailyBasal,
      'carbRatio': carbRatio,
      'correctionRatio': correctionRatio,
      'glucoseReadings':
          glucoseReadings?.map((glucose) => glucose.toMap()).toList(),
      'carbohydrates': carbohydrates,
      'notes': notes?.map((note) => note.toMap()).toList(),
      'insulinDosages':
          insulinDosages?.map((dosage) => dosage.toMap()).toList(),
      'workouts': workouts?.map((workout) => workout.toMap()).toList(),
    };
  }
}
