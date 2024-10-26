import 'package:cloud_firestore/cloud_firestore.dart';

class Carbohydrate {
  final double amount;
  final DateTime time;
  final String title;

  Carbohydrate({
    required this.amount,
    required this.time,
    required this.title,
  });

  factory Carbohydrate.fromMap(Map<String, dynamic> map) {
    return Carbohydrate(
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      time: (map['time'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'time': Timestamp.fromDate(time),
    };
  }
}
