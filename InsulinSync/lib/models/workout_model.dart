// not sure what is optional

import 'package:cloud_firestore/cloud_firestore.dart';

class Workout {
  String title;
  DateTime time;
  String? intensity;
  int duration;
  String source;
  String? id;

  Workout({
    required this.title,
    required this.time,
    this.intensity,
    required this.duration,
    required this.source,
    this.id,
  });

  factory Workout.fromMap(Map<dynamic, dynamic> map,{String? id}) {
    return Workout(
         id:map['id'],
      title: map['title'] as String,
      time: (map['time'] as Timestamp).toDate(),
      intensity: map['intensity'] as String?,
      duration: map['duration']?.toInt(),
      source: map['source'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': Timestamp.fromDate(time),
      'intensity': intensity,
      'duration': duration,
      'source': source,
    };
  }
}
