import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class foodItem {
  final String name;
  final double portion;
  final double protein;
  final double fat;
  final double carb;
  final double calorie;
  final String source;
  String? id;
  String? favoriteId;
  String? imageUrl;
  File? image;

  // Optional predicted values
  final double? predictedPortion;
  final double? predictedProtein;
  final double? predictedFat;
  final double? predictedCarb;
  final double? predictedCalorie;
  final String? predictedName;

  foodItem({
    required this.name,
    required this.portion,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.calorie,
    required this.source,
    this.id,
    this.favoriteId,
    this.imageUrl,
    this.image,
    this.predictedPortion,
    this.predictedProtein,
    this.predictedFat,
    this.predictedCarb,
    this.predictedCalorie,
    this.predictedName,
  });

  factory foodItem.fromMap(Map<String, dynamic> map,
      {String? id, String? favoriteId}) {
    return foodItem(
      name: map['name'] as String,
      portion: (map['portion'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carb: (map['carb'] as num).toDouble(),
      calorie: (map['calorie'] as num).toDouble(),
      source: map['source'] as String,
      id: id,
      favoriteId: favoriteId,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  /// Regular save to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'portion': portion,
      'protein': protein,
      'fat': fat,
      'carb': carb,
      'calorie': calorie,
      'source': source,
      'imageUrl': imageUrl,
    };
  }

  /// Prediction-specific map
  Map<String, dynamic> predictedToMap() {
    return {
      'predictedName': predictedName,
      'predictedPortion': predictedPortion,
      'predictedProtein': predictedProtein,
      'predictedFat': predictedFat,
      'predictedCarb': predictedCarb,
      'predictedCalorie': predictedCalorie,
    };
  }

  @override
  String toString() {
    return 'foodItem(name: $name, calorie: $calorie, protein: $protein, carb: $carb, fat: $fat, portion: $portion, source: $source, id: $id, favoriteId: $favoriteId, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! foodItem) return false;

    return other.name == name &&
        other.portion == portion &&
        other.protein == protein &&
        other.fat == fat &&
        other.carb == carb &&
        other.calorie == calorie &&
        other.source == source &&
        other.id == id &&
        other.favoriteId == favoriteId &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        portion.hashCode ^
        protein.hashCode ^
        fat.hashCode ^
        carb.hashCode ^
        calorie.hashCode ^
        source.hashCode ^
        id.hashCode ^
        favoriteId.hashCode ^
        imageUrl.hashCode;
  }
}
