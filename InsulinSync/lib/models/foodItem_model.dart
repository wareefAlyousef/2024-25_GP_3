import 'package:cloud_firestore/cloud_firestore.dart';

class foodItem {
  final String name;
  final double portion;
  final double protein;
  final double fat;
  final double carb;
  final double calorie;
  final String source;



  foodItem({
    required this.name,
    required this.portion,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.calorie,
    required this.source,
  });

  
 factory foodItem.fromMap(Map<String, dynamic> map) {
    return foodItem(
      name: map['name'] as String,
      portion: (map['portion'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carb: (map['carb'] as num).toDouble(),
      calorie: (map['calorie'] as num).toDouble(),
      source: map['source'] as String,
    );
  }

  
   Map<String, dynamic> toMap() {
    return {
      'name': name,
      'portion': portion,
      'protein': protein,
      'fat': fat,
      'carb': carb,
      'calorie': calorie,
      'source': source,
    };
  }
String toString() {
    return 'foodItem(name: $name, calorie: $calorie, protein: $protein, carb: $carb, fat: $fat, portion: $portion, source: $source)';
  }


}
