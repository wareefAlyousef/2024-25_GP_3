import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:insulin_sync/MainNavigation.dart';
//import 'home_screen.dart';
import 'main.dart';
//import '../models/note_model.dart';
//import '../services/user_service.dart';
import 'AddBysearch.dart';
import 'models/foodItem_model.dart';
import 'Cart.dart';

class Addfooditem extends StatefulWidget {
  final double calorie;
  final double protein;
  final double carb;
  final double fat;
  final String name;
  final double portion;
  final String source;
  final List<foodItem>? mealItems;
  final int? index;

  Addfooditem({
    required this.calorie,
    required this.protein,
    required this.carb,
    required this.fat,
    required this.name,
    required this.portion,
    required this.source,
    this.mealItems,
    this.index,
  });

  @override
  _Addfooditem createState() => _Addfooditem();
}

class _Addfooditem extends State<Addfooditem> {
  final _formKey = GlobalKey<FormState>();

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


  @override
  void initState() {
    super.initState();
    // Initialize mealItems with the passed array or an empty list
    mealItems = widget.mealItems ?? [];

    if (widget.index != null) {
      mealItems.removeAt(widget.index!);
    }
    _calculateTotalNutrients();
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

      // Debug prints
      print('Input Portion: $inputPortion g');
      print('Total Calories: $totalCalorie kcal');
      print('Total Protein: $totalProtein g');
      print('Total Carbs: $totalCarb g');
      print('Total Fat: $totalFat g');
    });
  }

  void addFoodItemToMeal() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Use inputPortion if it's greater than 0, otherwise use original portion
      final double portionToUse = inputPortion > 0 ? inputPortion : portion;

      // Calculate nutrients based on the portion to use
      final double adjustedCalorie = double.parse((calorie / portion * portionToUse).toStringAsFixed(1));
      final double adjustedProtein = double.parse((protein / portion * portionToUse).toStringAsFixed(1));
      final double adjustedCarb = double.parse((carb / portion * portionToUse).toStringAsFixed(1));
      final double adjustedFat = double.parse((fat / portion * portionToUse).toStringAsFixed(1));
      final double roundedPortion = double.parse(portionToUse.toStringAsFixed(1));

      final newItem = foodItem(
        name: name,
        calorie: adjustedCalorie,
        protein: adjustedProtein,
        carb: adjustedCarb,
        fat: adjustedFat,
        portion: roundedPortion,
        source: source,
      );
      
      setState(() {
        mealItems.add(newItem);
      });

      // Debug: Print the entire mealItems list
      print('Meal items after addition:');
      for (var item in mealItems) {
        print(
            'Name: ${item.name}, Calories: ${item.calorie}, Protein: ${item.protein}, Carbs: ${item.carb}, Fat: ${item.fat}, Portion: ${item.portion}, Source: ${item.source}');
      }
    }
  }

  void navigateToNextPage() {
    addFoodItemToMeal();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Cart(foodItems: mealItems), 
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
            );
            
            // Insert the original item back at its index
            mealItems.insert(widget.index!, originalItem);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Cart(foodItems: mealItems),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        },
      ),
    ),
    body:  SingleChildScrollView(
          child: Form(
                key: _formKey,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(top: 100),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(fontSize: 30, 
                    fontWeight: FontWeight.bold
                    ),
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
                        Text(
                          'Portion Size',
                          style: TextStyle(
                            fontSize: 25,
                            color: Color.fromRGBO(96, 106, 133, 1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
  padding: EdgeInsets.only(top: 5),
  child: Row(
    children: [
      Expanded(
        child: TextFormField(
          initialValue: portion.toString(),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
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
            if (portionValue == null || portionValue <= 0) {
              return 'Please enter a number greater than 0';
            }
            if (RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value) == false) {
              return 'Please enter to 2 decimal places only';
            }
            return null;
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
                                widget.index != null ? 'Edit Food Item' : 'Add Food Item',
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
}
