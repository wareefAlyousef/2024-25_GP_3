import 'package:cloud_firestore/cloud_firestore.dart';

class Carbohydrate {
  final double amount;
  final DateTime time;
  final String title;
    String? id;

  Carbohydrate({
    required this.amount,
    required this.time,
    required this.title,
     this.id
  });

  factory Carbohydrate.fromMap(Map<String, dynamic> map,{String? id}) {
    return Carbohydrate(
       id:map['id'],
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
