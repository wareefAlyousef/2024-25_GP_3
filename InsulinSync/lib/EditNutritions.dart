import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'home_screen.dart';
import 'main.dart';
import 'AddBySearch.dart';
import '../models/foodItem_model.dart';
import '../services/user_service.dart';
import 'Cart.dart';

class EditNutritions extends StatefulWidget {
  @override
  final int index; 
  final List<foodItem>? mealItems;
  


EditNutritions( this.index, this.mealItems

);
  _EditNutritions createState() => _EditNutritions();
}

class _EditNutritions extends State<EditNutritions> {
 late List<foodItem> mealItems;
 late int index;
  String _carb = "";
  String _fat = "";
  String _protein = "";
  String _calorie= "";
  String? _name = "";
  late foodItem item; 
  final _formKey = GlobalKey<FormState>();
   double protein = 0.0;
  double carb = 0.0;
  double fat = 0.0;
  double calorie = 0.0;
String title= ""; 
 
 void initState() {
    super.initState();
    // Initialize mealItems with the passed array or an empty list
    mealItems = widget.mealItems ?? [];
    index = widget.index;
    if (index >= 0 && index < mealItems.length) {
      item = mealItems[index];}
protein = item.protein;
carb = item.carb;
fat = item.fat;
calorie = item.calorie;
title = item.name;


  }




  


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // If the form is valid 
double _carbdouble = double.parse(_carb);
double _proteindouble = double.parse(_protein);
double _fatdouble = double.parse(_fat);
double _caloriedouble = double.parse(_calorie);
String name = _name ?? "food item";

    if (name == null || name == "")
   {
name = "food item";
    }

 final newItem = foodItem(
        name: name,
        calorie: _caloriedouble,
        protein: _proteindouble,
        carb: _carbdouble,
        fat: _fatdouble,
        portion: -1, 
        source: "nutritions",
      );

setState(() {
      mealItems[index] = newItem; 
      print("edit  item: $newItem"); // Debugging print
    });

    print('Meal items after edit:');
    for (var item in mealItems) {
      print(item); 
    }


 print('Meal items done');

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
      backgroundColor: Color.fromARGB(255, 240, 240, 240),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 240, 240, 240),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 30.0,
          ),
          onPressed: () {
                      Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>   Cart(foodItems: mealItems)
              ),
              ); 
                    },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
//page title
              Padding(
                padding: EdgeInsets.fromLTRB(5, 20, 15, 10),
                child: Text(
                  'Add Nutritions',
                  style: TextStyle(
                    
                    fontSize: 30, //check with raneem
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
//form
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
// white square
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4,
                            color: Color(0x33000000),
                            offset: Offset(0, 2),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8),
                      ),
//inside the container
                      child: Column(
                        children: [
//user input 1
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 30, 25, 0),
                            child: TextFormField(
                              initialValue: title,
                          
                              decoration: InputDecoration(
                                hintText: 'Item Name (Optional)',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding:
                                    EdgeInsets.fromLTRB(0, 16, 16, 8),
                              ),
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                              validator: (value) {
                                if (value != null && value.length > 20) {
                                  return 'Name cannot exceed 20 characters';
                                }
                                _name = value;
                                return null; // validation passed
                              },
                             
                            ),
                          ),
// user input 1
Padding(
  padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center, 
    children: [
      Container(
        alignment: Alignment.centerLeft,
        child: Text(
          'Carb * ',
          style: TextStyle(
            fontSize: 25,
            color: Color.fromRGBO(96, 106, 133, 1),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(width: 16), 
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: carb.toString(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Amount in grams',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the carb';
                    }
                    
                    final carbValue = double.tryParse(value);
                    if (carbValue == null || carbValue <= 0) {
                      return 'greater than 0';
                    }
                    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value)) {
                      return '2 decimal places only';
                    }
                    _carb = value;
                    return null; // If all validations pass
                  },
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Text(
                  '     g',
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
      ),
    ],
  ),
),
// user input 2
Padding(
  padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center, 
    children: [
      Container(
        alignment: Alignment.centerLeft,
        child: Text(
          'Protein',
          style: TextStyle(
            fontSize: 25,
            color: Color.fromRGBO(96, 106, 133, 1),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(width: 16), 
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: protein.toString(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Amount in grams',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      value="0";
                    }
                    
                    final proteinValue = double.tryParse(value);
                    
                    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value)) {
                      return '2 decimal places only';
                    }
                    _protein = value;
                    return null; // If all validations pass
                  },
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Text(
                  '     g',
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
      ),
    ],
  ),
),
                         // user input 1
Padding(
  padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center, 
    children: [
      Container(
        alignment: Alignment.centerLeft,
        child: Text(
          'Fat       ',
          style: TextStyle(
            fontSize: 25,
            color: Color.fromRGBO(96, 106, 133, 1),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(width: 16), 
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: fat.toString(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Amount in grams',
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
                  validator: (value) {
                    
                    if (value == null || value.isEmpty) {
                      value="0";
                    }
                    
                    final fatValue = double.tryParse(value);
                   
                    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value)) {
                      return '2 decimal places only';
                    }
                    _fat = value;
                    return null; // If all validations pass
                  },
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Text(
                  '     g',
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
      ),
    ],
  ),
),
                         
 // user input 4
Padding(
  padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center, 
    children: [
      Container(
        alignment: Alignment.centerLeft,
        child: Text(
          'Calorie',
          style: TextStyle(
            fontSize: 25,
            color: Color.fromRGBO(96, 106, 133, 1),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      SizedBox(width: 16), 
      Expanded(
        child: Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 25, 0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: calorie.toString(),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Amount in grams',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      value="0";
                    }
                    
                    final calorieValue = double.tryParse(value);
                    
                    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value)) {
                      return '2 decimal places only';
                    }
                    _calorie = value;
                    return null; // If all validations pass
                  },
                ),
              ),
              SizedBox(width: 8),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Text(
                  'kcal',
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
      ),
    ],
  ),
),
        SizedBox(height: 35),                 

                          
                         
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate the form and then open the dialog
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _submitForm();
                                }
                              },
                              child: Text(
                                'Edit Food Item',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
