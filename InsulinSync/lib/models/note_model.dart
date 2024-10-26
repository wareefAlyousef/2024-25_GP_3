import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  DateTime time;
  String title;
  String comment;

  Note({
    required this.time,
    required this.title,
    required this.comment,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      time: (map['time'] as Timestamp).toDate(),
      title: map['title'] ?? '',
      comment: map['comment'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': Timestamp.fromDate(time),
      'title': title,
      'comment': comment,
    };
  }
}
