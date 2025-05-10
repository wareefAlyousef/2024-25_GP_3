import 'package:cloud_firestore/cloud_firestore.dart';
import 'foodItem_model.dart';
import 'meal_model.dart';

class FavoriteMeal {
  String? id;
  String title;
  List<foodItem> foodItems;
  // DateTime lastTimeAdded;

  // Constructor that directly takes title and foodItems
  FavoriteMeal({
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

  // Constructor that takes a meal object and assigns its title and foodItems
  FavoriteMeal.fromMeal(meal currentMeal)
      : title = currentMeal.title,
        foodItems = currentMeal.foodItems;

  // Convert FavoriteMeal to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'foodItems': foodItems.map((foodItem) => foodItem.toMap()).toList(),
      // 'lastTimeAdded': Timestamp.fromDate(lastTimeAdded),
      'totalCarb': totalCarb,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'totalCalorie': totalCalorie,
    };
  }

  // Factory constructor to create FavoriteMeal from Firestore map data
  factory FavoriteMeal.fromMap(Map<dynamic, dynamic> map, {String? id}) {
    return FavoriteMeal(
      id: id,
      title: map['title'] ?? '',
      foodItems: map['foodItems'] != null
          ? (map['foodItems'] as List<dynamic>)
              .map((item) => foodItem.fromMap(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
