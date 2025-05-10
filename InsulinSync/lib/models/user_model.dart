import 'package:cloud_firestore/cloud_firestore.dart';

import 'glucose_model.dart';
import 'insulin_model.dart';
import 'note_model.dart';
import 'workout_model.dart';
import 'meal_model.dart';
import 'contact_model.dart';

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
  String? patientId, token, libreEmail, libreAccountId;
  int? minRange, maxRange;
  bool? recieveNotifications;
  List<GlucoseReading>? glucoseReadings;
  List<double>? carbohydrates;
  List<Note>? notes;
  List<InsulinDosage>? insulinDosages;
  List<Workout>? workouts;
  List<meal>? meals;
  List<Contact>? emergencyContacts;

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
    this.patientId,
    this.token,
    this.libreEmail,
    this.libreAccountId,
    this.minRange,
    this.maxRange,
    this.glucoseReadings,
    this.carbohydrates,
    this.notes,
    this.insulinDosages,
    this.workouts,
    this.meals,
    this.emergencyContacts, // Initialize emergencyContacts
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
      patientId: map['patientId'] as String?,
      token: map['token'] as String?,
      libreEmail: map['libreEmail'] as String?,
      libreAccountId: map['libreAccountId'] as String?,
      minRange: map['minRange'] as int?,
      maxRange: map['maxRange'] as int?,
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
      meals: map['meals'] != null
          ? (map['meals'] as List<dynamic>)
              .map((item) => meal.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
      emergencyContacts: map['emergencyContacts'] != null
          ? (map['emergencyContacts'] as List<dynamic>)
              .map((item) => Contact.fromMap(item as Map<String, dynamic>, id: item['id'] as String)) ///////////if an error happend try to delete the last argument
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
      'patientId': patientId,
      'token': token,
      'libreEmail': libreEmail,
      'libreAccountId': libreAccountId,
      'minRange': minRange,
      'maxRange': maxRange,
      'glucoseReadings':
          glucoseReadings?.map((glucose) => glucose.toMap()).toList(),
      'carbohydrates': carbohydrates,
      'notes': notes?.map((note) => note.toMap()).toList(),
      'insulinDosages':
          insulinDosages?.map((dosage) => dosage.toMap()).toList(),
      'workouts': workouts?.map((workout) => workout.toMap()).toList(),
      'meals': meals?.map((meal) => meal.toMap()).toList(),
      'emergencyContacts':
          emergencyContacts?.map((contact) => contact.toMap()).toList(),
    };
  }
}
