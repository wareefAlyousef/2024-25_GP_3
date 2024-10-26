import 'package:cloud_firestore/cloud_firestore.dart';
import 'glucose_model.dart';

class InsulinDosage {
  String type;
  double dosage;
  DateTime time;
  GlucoseReading? glucoseAtTime;
  String title;

  InsulinDosage({
    required this.type,
    required this.dosage,
    required this.time,
    this.glucoseAtTime,
    required this.title,
  });

  factory InsulinDosage.fromMap(Map<dynamic, dynamic> map) {
    return InsulinDosage(
      title: map['title'] as String,
      type: map['type'] as String,
      dosage: (map['dosage'] as num).toDouble(),
      time: (map['time'] as Timestamp).toDate(),
      glucoseAtTime: map['glucoseAtTime'] != null
          ? GlucoseReading.fromMap(
              map['glucoseAtTime'] as Map<dynamic, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'dosage': dosage,
      'time': Timestamp.fromDate(time),
      'glucoseAtTime': glucoseAtTime != null ? glucoseAtTime?.toMap() : null,
    };
  }
}
