import 'package:cloud_firestore/cloud_firestore.dart';
import 'foodItem_model.dart';

class meal {
  DateTime time;
  String title;
  List<foodItem> foodItems;
  String? id;

  meal({
    // Make it optional
    required this.time,
    required this.title,
    required this.foodItems,
    this.id,
  });

  double get totalCarb {
    return foodItems.fold(0, (sum, item) => sum + item.carb);
  }

  double get totalProtein {
    return foodItems.fold(0, (sum, item) => sum + item.protein);
  }

  double get totalFat {
    return foodItems.fold(0, (sum, item) => sum + item.fat);
  }

  double get totalCalorie {
    return foodItems.fold(0, (sum, item) => sum + item.calorie);
  }

  factory meal.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    return meal(
      id: map['id'],
      time: (map['time'] as Timestamp).toDate(),
      title: map['title'] ?? '',
      foodItems: map['foodItems'] != null
          ? (map['foodItems'] as List<dynamic>)
              .map((item) => foodItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': Timestamp.fromDate(time),
      'title': title,
      'foodItems': foodItems?.map((foodItem) => foodItem.toMap()).toList(),
      'totalCarb': totalCarb,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCalorie': totalCalorie,
    };
  }
}
