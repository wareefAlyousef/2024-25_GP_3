import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/foodItem_model.dart';
import 'Cart.dart';
import 'services/user_service.dart';

class Addfooditem extends StatefulWidget {
  String? title;
  TimeOfDay? timeOfDay;
  final double calorie;
  final double protein;
  final double carb;
  final double fat;
  final String name;
  final double portion;
  final String source;
  final List<foodItem>? mealItems;
  final int? index;
  final DateTime time;
  final String title2;
  final String id;
  final bool isFavorite;
  final String? favoriteId;

  // final bool isItemFavorite;
  final String? favoriteItemId;

  Addfooditem({
    this.title,
    this.timeOfDay,
    required this.calorie,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.name,
    required this.portion,
    required this.source,
    this.mealItems,
    this.index,
    this.isFavorite = false,
    this.favoriteId = null,
    this.favoriteItemId = null,
    DateTime? time,
    String? title2,
    String? id,
  })  : this.time = time ?? DateTime(1990, 1, 1, 12),
        this.title2 = title ?? "Title is not defined",
        this.id = id ?? "-1";

  @override
  _Addfooditem createState() => _Addfooditem();
}

class _Addfooditem extends State<Addfooditem> {
  final _formKey = GlobalKey<FormState>();
  late DateTime initialTime1;
  late String initialTitle;
  late String initialId;
  late double calorie = widget.calorie;
  late double protein = widget.protein;
  late double carb = widget.carb;
  late double fat = widget.fat;
  late String name = widget.name;
  late double portion = widget.portion;
  late String source = widget.source;
  late int? index = widget.index;

  double totalProtein = 0.0;
  double totalCarb = 0.0;
  double totalFat = 0.0;
  double totalCalorie = 0.0;

  late List<foodItem> mealItems;
  late bool isFavorite;
  late String? favoriteId;

  late bool isItemFavorite;
  late String? favoriteItemId;

  UserService user_service = UserService();

  @override
  void initState() {
    super.initState();
    // Initialize mealItems with the passed array or an empty list
    mealItems = widget.mealItems ?? [];

    isFavorite = widget.isFavorite;
    favoriteId = widget.favoriteId;

    favoriteItemId = widget.favoriteItemId;

// Set isItemFavorite to true if favoriteItemId is not null
    isItemFavorite = favoriteItemId != null;

    if (widget.index != null) {
      mealItems.removeAt(widget.index!);
    }
    _calculateTotalNutrients();
    initialTitle = widget.title2;
    initialId = widget.id;
    initialTime1 = widget.time;
  }

  void _calculateTotalNutrients() {
    // Ensure calculations are based on the default portion size
    setState(() {
      totalProtein = protein; // Nutrients for default portion
      totalCalorie = calorie;
      totalCarb = carb;
      totalFat = fat;
    });
  }

  var inputPortion = 0.0;

  // Updates nutritional values based on portion size entered by the user
  void updatenutritions(String value) {
    setState(() {
      inputPortion = double.tryParse(value) ?? 0.0;

      if (inputPortion > 0) {
        // Scale nutrients proportionally based on input portion
        totalProtein = (protein / portion) * inputPortion;
        totalCalorie = (calorie / portion) * inputPortion;
        totalCarb = (carb / portion) * inputPortion;
        totalFat = (fat / portion) * inputPortion;
      } else {
        // Handle invalid or zero input by resetting values to zero
        totalProtein = 0.0;
        totalCalorie = 0.0;
        totalCarb = 0.0;
        totalFat = 0.0;
      }
    });
  }

  void addFoodItemToMeal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Use inputPortion if it's greater than 0, otherwise use original portion
      final double portionToUse = inputPortion > 0 ? inputPortion : portion;

      // Calculate nutrients based on the portion to use
      final double adjustedCalorie =
          double.parse((calorie / portion * portionToUse).toStringAsFixed(1));
      final double adjustedProtein =
          double.parse((protein / portion * portionToUse).toStringAsFixed(1));
      final double adjustedCarb =
          double.parse((carb / portion * portionToUse).toStringAsFixed(1));
      final double adjustedFat =
          double.parse((fat / portion * portionToUse).toStringAsFixed(1));
      final double roundedPortion =
          double.parse(portionToUse.toStringAsFixed(1));

      final newItem = foodItem(
        name: name,
        calorie: adjustedCalorie,
        protein: adjustedProtein,
        carb: adjustedCarb,
        fat: adjustedFat,
        portion: roundedPortion,
        source: source,
        favoriteId: favoriteItemId,
      );

      setState(() {
        mealItems.add(newItem);
      });
    }
  }

  void navigateToNextPage() {
    addFoodItemToMeal();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(
            title: widget.title,
            foodItems: mealItems,
            isFavorite: isFavorite,
            favoriteId: favoriteId,
            id: initialId,
            time: initialTime1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF1F4F8),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 30.0,
          ),
          onPressed: () {
            if (widget.index != null && widget.mealItems != null) {
              // Create a new foodItem with the original values
              final originalItem = foodItem(
                name: widget.name,
                calorie: widget.calorie,
                protein: widget.protein,
                carb: widget.carb,
                fat: widget.fat,
                portion: widget.portion,
                source: widget.source,
                favoriteId: favoriteItemId,
              );

              // Insert the original item back at its index
              mealItems.insert(widget.index!, originalItem);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Cart(
                    id: widget.id,
                    title: widget.title,
                    time: widget.time,
                    foodItems: mealItems,
                    isFavorite: isFavorite,
                    favoriteId: favoriteId,
                  ),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(top: 100, left: 20, right: 20),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // white container
              Padding(
                padding: EdgeInsets.all(0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Portion Size',
                              style: TextStyle(
                                fontSize: 25,
                                color: Color.fromRGBO(96, 106, 133, 1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isItemFavorite =
                                      !isItemFavorite; // Toggle favorite state
                                });

                                if (isItemFavorite) {
                                  saveFavorite();
                                } else {
                                  removeFromFavorite();
                                }
                              },
                              child: Container(
                                width: 21,
                                padding: const EdgeInsets.all(0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isItemFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isItemFavorite
                                      ? Theme.of(context).colorScheme.error
                                      : const Color(0xFF023B96),
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: portion.toString(),
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Portion size in grams',
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  onChanged: updatenutritions,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter portion';
                                    }
                                    final portionValue = double.tryParse(value);
                                    if (portionValue == null ||
                                        portionValue <= 0) {
                                      return 'Please enter a number greater than 0';
                                    }
                                    if (RegExp(r'^\d+\.?\d{0,2}$')
                                            .hasMatch(value) ==
                                        false) {
                                      return 'Please enter to 2 decimal places only';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    if (_formKey.currentState!.validate()) {
                                      // Validate before calling method
                                      saveFavorite();
                                    }
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: Text(
                                  'g',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'images/wheat.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Carb',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                "${totalCarb.toStringAsFixed(2)}   g   ",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'images/leg.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Protein',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                "${totalProtein.toStringAsFixed(2)}   g   ",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'images/lipid.png',
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Fat',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                "${totalFat.toStringAsFixed(2)}   g   ",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE6F2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FaIcon(
                                      FontAwesomeIcons.fire,
                                      color: Color(0xFF99C2FF),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                'Calories',
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Spacer(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                              child: Text(
                                "${totalCalorie.toStringAsFixed(2)} Kcal",
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

// add button
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: navigateToNextPage,
                                  child: Text(
                                    widget.index != null
                                        ? 'Edit Food Item'
                                        : 'Add Food Item',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF023B96),
                                    minimumSize: Size(double.infinity, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveFavorite() async {
    if (!isItemFavorite) return;
    // Create the foodItem object
    foodItem item = foodItem(
      name: name,
      calorie: totalCalorie,
      protein: totalProtein,
      carb: totalCarb,
      fat: totalFat,
      portion: inputPortion > 0 ? inputPortion : portion,
      source: source,
      favoriteId: favoriteItemId,
    );

    // If favoriteId is null, it's a new favorite, so add it
    if (favoriteItemId == null) {
      favoriteItemId = await user_service.addItemToFavorite(item);
    } else {
      // Otherwise, update the existing favorite
      user_service.updateFavoriteItem(
        itemId: favoriteItemId!,
        newName: name,
        newCalorie: totalCalorie,
        newProtein: totalProtein,
        newCarb: totalCarb,
        newFat: totalFat,
        newPortion: inputPortion > 0 ? inputPortion : portion,
        newSource: source,
      );
    }
  }

  void removeFromFavorite() {
    if (favoriteItemId != null) {
      user_service.removeItemFromFavorite(favoriteItemId!);
      favoriteItemId = null;
    }
  }
}
