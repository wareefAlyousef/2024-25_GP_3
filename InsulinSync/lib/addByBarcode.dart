import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main.dart';
import '../models/foodItem_model.dart';
import 'AddBySearch.dart';
import 'Cart.dart';

class addByBarcode extends StatefulWidget {
  @override
  final double calorie;
  final double protein;
  final double carb;
  final double fat;
  final String name;
  final List<foodItem>? mealItems;

  addByBarcode(this.calorie, this.protein, this.carb, this.fat, this.name,
      this.mealItems);

  _addByBarcode createState() => _addByBarcode();
}

class _addByBarcode extends State<addByBarcode> {
  final _formKey = GlobalKey<FormState>();
  late double calorie = widget.calorie;
  late double protein = widget.protein;
  late double carb = widget.carb;
  late double fat = widget.fat;
  late String name = widget.name;
  late List<foodItem> mealItems;

  double portion = 0.0;
  double totalProtein = 0.0;
  double totalCarb = 0.0;
  double totalFat = 0.0;
  double totalCalorie = 0.0;

  void initState() {
    super.initState();
    // Initialize mealItems with the passed array or an empty list
    mealItems = widget.mealItems ?? [];
  }

  void updatenutritions(String value) {
    setState(() {
      portion = double.tryParse(value) ?? 0.0;
      totalProtein = (protein * portion) / 100;
      totalCalorie = (calorie * portion / 100);
      totalCarb = (carb * portion) / 100;
      totalFat = (fat * portion) / 100;
    });
  }

  double twoDecimal(double value) {
    return (value * 100).round() / 100;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // If the form is valid

      final newItem = foodItem(
        name: name,
        calorie: (totalCalorie),
        protein: totalProtein,
        carb: totalCarb,
        fat: totalFat,
        portion: portion,
        source: "barcode",
      );

      setState(() {
        mealItems.add(newItem);
      });

      for (var item in mealItems) {
        print(item);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Cart(foodItems: mealItems),
        ),
      );
    }
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
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddBySearch(mealItems: mealItems)),
            );
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
                padding: EdgeInsets.fromLTRB(20, 100, 20, 0),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
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
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Portion size in in grams',
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
                                      return 'Please enter the portion size';
                                    }
                                    // parse the value to a double for validation
                                    final portion = double.tryParse(value);
                                    if (portion == null || portion <= 0) {
                                      return 'Please enter a number greater than 0';
                                    }
                                    if (RegExp(r'^\d+\.?\d{0,2}$')
                                            .hasMatch(value) ==
                                        false) {
                                      return 'Please enter to 2 decimal places only';
                                    }

                                    return null; // If all validations pass
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
                                      width: 10,
                                      height: 10,
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
                                "${totalCarb.toStringAsFixed(2)} g     ",
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
                                "${totalProtein.toStringAsFixed(2)} g     ",
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
                                "${totalFat.toStringAsFixed(2)} g     ",
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
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FaIcon(
                                      FontAwesomeIcons.fire,
                                      color: Color(0xFF99C2FF),
                                      size: 23,
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
                                "${totalCalorie.toStringAsFixed(2)} kcal",
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
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _formKey.currentState!.save();
                                      _submitForm();
                                    }
                                  },
                                  child: Text(
                                    'Add Food Item',
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
