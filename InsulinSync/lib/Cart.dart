import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insulin_sync/AddFoodItem.dart';
import 'package:insulin_sync/EditNutritions.dart';
import 'package:insulin_sync/models/foodItem_model.dart';
import '../models/meal_model.dart';
import '../services/user_service.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'package:fl_chart/fl_chart.dart';
import "EditFoodItem.dart";
import "AddBySearch.dart";
import 'AddFoodItem.dart';

////////
class Cart extends StatefulWidget {
  final List<foodItem>? foodItems;

  Cart({this.foodItems});

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  final _formKey = GlobalKey<FormState>();
  String _title = "";
  TimeOfDay _timeOfDay = TimeOfDay.now();
  final DateTime _now = DateTime.now();
  late List<foodItem> foodItems;
  FocusNode myFocusNode = FocusNode();
  FocusNode myfocus = FocusNode();
  FocusNode myfocus2 = FocusNode();
  bool showWarning = false;

  @override
  void initState() {
    super.initState();
    foodItems = widget.foodItems ?? [];
  }

  void _showTimePicker() {
    myFocusNode.unfocus();
    showTimePicker(
      context: context,
      initialTime: _timeOfDay,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF023B96),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF023B96),
              secondary: Colors.grey,
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() {
          _timeOfDay = value;
        });
      }
    });
  }

  // Method to show confirmation dialog
  void _showConfirmationDialog() {
    myfocus.unfocus();
    myfocus2.unfocus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String $title = (_title == null || _title.isEmpty) ? 'Meal' : _title;
        String $time = _timeOfDay.format(context);
        String ingredients = foodItems.map((item) => item.name).join(', ');
        double totalCarb = foodItems.fold(0, (sum, item) => sum + item.carb);
        double totalProtein =
            foodItems.fold(0, (sum, item) => sum + item.protein);
        double totalFat = foodItems.fold(0, (sum, item) => sum + item.fat);
        double totalCalories =
            foodItems.fold(0, (sum, item) => sum + item.calorie);

        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color.fromARGB(200, 210, 227, 255),
                    child: Icon(
                      Icons
                          .fastfood, //////////////////////////////////////////////////
                      size: 80,
                      color: Color(0xFF023B96),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Are You Sure?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Title: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            $title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Time: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            $time,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Added Meal: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: [
                          Text(
                            ingredients,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Carb Column
                      Column(
                        children: [
                          Text(
                            'Carbs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            totalCarb.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Protein Column
                      Column(
                        children: [
                          Text(
                            'Protein',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            totalProtein.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Fat Column
                      Column(
                        children: [
                          Text(
                            'Fat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            totalFat.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Calories Column
                      Column(
                        children: [
                          Text(
                            'Calories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            totalCalories.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Cancel button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF023B96),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // Add button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _submitForm();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF023B96)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: Color(0xFF023B96),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

  void _validate() {
    if (foodItems.isEmpty) {
      // Reject add request and show warning
      setState(() {
        showWarning = true;
      });
    } else {
      _showConfirmationDialog();
    }
  }

  // Form submission method
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      DateTime _newDateTime = DateTime(_now.year, _now.month, _now.day,
          _timeOfDay.hour, _timeOfDay.minute, 0);

      // Set default title if empty
      if (_title.trim().isEmpty) {
        _title = 'Meal';
      }

      meal myMeal =
          meal(time: _newDateTime, title: _title, foodItems: foodItems);

      UserService sevice = new UserService();
      if (await sevice.addMeal(myMeal)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xff023b96),
                    size: 80,
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Meal is added successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: () {
                     _askDosage();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Color(0xff023b96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(100, 44),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        
       
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: Color.fromARGB(255, 194, 43, 98),
                    size: 80,
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Failed adding the meal!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Something went wrong, please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15),
                  )
                ],
              ),
              actions: [
                Center(
                  // Center the button
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Color(0xff023b96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(100, 44),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Method to show CLEAR confirmation dialog
  void _showClearDialog(BuildContext context) {
    myfocus.unfocus();
    myfocus2.unfocus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color.fromARGB(41, 248, 77, 117),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 80,
                    ),
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Are You Sure?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Clicking "Clear All" Will Delete All The Added Ingredients',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
// buttons
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), // Make buttons the same size
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            setState(() {
                              foodItems.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(120, 44),
                          ),
                          child: Text(
                            'Clear All',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

  void _askDosage() {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
     
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color.fromARGB(200, 210, 227, 255),
                    child: Icon(
                      FontAwesomeIcons.syringe, //////////////////////////////////////////////////
                      size: 80,
                      color: Color(0xFF023B96),
                    ),
                  ),
                  SizedBox(height: 20),
                 Center(
  child: Text(
    'Would you like an insulin dosage recommendation based on your meal?',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center, 
  ),
),
                  SizedBox(height: 30),
              

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // no button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                               Navigator.pushAndRemoveUntil( context,
    MaterialPageRoute(builder: (context) => MainNavigation()),
    (Route<dynamic> route) => false,);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF023B96),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), 
                          ),
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // yes button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                           asksport() ;
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Color(0xFF023B96)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44),
                          ),
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              color: Color(0xFF023B96),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

void asksport() {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
     
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color.fromARGB(200, 210, 227, 255),
                    child: Icon(
                      Icons.fitness_center, //////////////////////////////////////////////////
                      size: 80,
                      color: Color(0xFF023B96),
                    ),
                  ),
                  SizedBox(height: 20),
                 Center(
  child: Text(
    'Do you have any plans to exercise in the next two hours?',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center, 
  ),
),
                  SizedBox(height: 30),
              

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // no button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            //show recommended and confirmation
                            showDosage() ;
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF023B96),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), 
                          ),
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // yes button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                           //show add exercise page
                            Navigator.pushAndRemoveUntil( context,
    MaterialPageRoute(builder: (context) => MainNavigation()),
    (Route<dynamic> route) => false,);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Color(0xFF023B96)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44),
                          ),
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              color: Color(0xFF023B96),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }

  void showDosage() {
     double totalCarb = foodItems.fold(0, (sum, item) => sum + item.carb);
        double totalProtein = foodItems.fold(0, (sum, item) => sum + item.protein);
        double totalFat = foodItems.fold(0, (sum, item) => sum + item.fat);
        double totalCalories = foodItems.fold(0, (sum, item) => sum + item.calorie);

    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
     
        return AlertDialog(
            contentPadding: EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Color.fromARGB(200, 210, 227, 255),
                    child: Icon(
                      FontAwesomeIcons.syringe, //////////////////////////////////////////////////
                      size: 80,
                      color: Color(0xFF023B96),
                    ),
                  ),
                  SizedBox(height: 20),
              Text(
    'Meal Details:',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),

  ),
                    SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Carb Column
                  Column(
                    children: [
                      Text(
                        'Carbs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        totalCarb.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Protein Column
                  Column(
                    children: [
                      Text(
                        'Protein',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        totalProtein.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Fat Column
                  Column(
                    children: [
                      Text(
                        'Fat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        totalFat.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Calories Column
                  Column(
                    children: [
                      Text(
                        'Calories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        totalCalories.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 25),
              Text(
    'Exercise Details:',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.left,

  ),
SizedBox(height: 10),
   Text(
                        'Not planning to exercise in the next 2 hours',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                          textAlign: TextAlign.center,
                      ),
               SizedBox(height: 25),
 Text(
    'The Recomended insulin dosage:',
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),

  ),

                  SizedBox(height: 30),
              

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // no button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            //will not take it
                             Navigator.pushAndRemoveUntil( context,
    MaterialPageRoute(builder: (context) => MainNavigation()),
    (Route<dynamic> route) => false,);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF023B96),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), 
                          ),
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // yes button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                           // will take it
                            Navigator.pushAndRemoveUntil( context,
    MaterialPageRoute(builder: (context) => MainNavigation()),
    (Route<dynamic> route) => false,);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Color(0xFF023B96)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44),
                          ),
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              color: Color(0xFF023B96),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ));
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    var totals = _calculateTotals();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 240, 240, 240),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 30.0),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(255, 0, 0, 0),
            size: 30,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainNavigation()),
            );
          },
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(5, 10, 15, 10),
                child: Text(
                  'Added ingredients',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(15.0, 20.0, 0.0, 5.0),
                child: Text(
                  'Meal information',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Color.fromARGB(255, 120, 120, 120),
                  ),
                ),
              ),
              _buildMealInfoForm(),

              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(15.0, 20.0, 0.0, 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                          child: Text(
                            'Added Ingredients',
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Color.fromARGB(255, 120, 120, 120),
                            ),
                          ),
                        ),
                        // Show Clear All button only if foodItems is not empty
                        foodItems.isNotEmpty
                            ? TextButton(
                                onPressed: () {
                                  _showClearDialog(context);
                                },
                                child: Text(
                                  'Clear All',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding:
                                      EdgeInsets.fromLTRB(0, 20.0, 20.0, 0.0),
                                ),
                              )
                            : SizedBox
                                .shrink(), // Placeholder widget when foodItems is empty
                      ],
                    ),
                  ),

                  // Check if foodItems is empty
                  foodItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 50.0, bottom: 0.0),
                            child: Text(
                              'There Are No Added Ingredients Yet!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: showWarning
                                    ? Theme.of(context).colorScheme.error
                                    : Color.fromARGB(255, 140, 140, 140),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: foodItems.length,
                          itemBuilder: (context, index) {
                            return _buildFoodItemCard(foodItems[index], index);
                          },
                        ),
// Add Ingredient Button
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: showWarning
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).primaryColor,
                      ),
                      width: 40.0,
                      height: 40.0,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AddBySearch(mealItems: foodItems)),
                          );
                        },
                        icon: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        tooltip: 'Add Ingredient',
                      ),
                    ),
                  )
                ],
              ),

//Meal totals title
              const Padding(
                padding: EdgeInsets.fromLTRB(15.0, 20.0, 0.0, 5.0),
                child: Text(
                  'Meal totals',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Color.fromARGB(255, 120, 120, 120),
                  ),
                ),
              ),

//Meal totals Container
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(25, 5, 25, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
// Pie Chart
                      SizedBox(
                        height: 150, // Adjust height as needed
                        child: PieChart(
                          PieChartData(
                            sections: (totals.values.every(
                                    (value) => value == null || value == 0))
                                ? [
                                    PieChartSectionData(
                                      color: Colors.grey,
                                      value: 1,
                                      title: '',
                                      borderSide: BorderSide.none,
                                    ),
                                  ]
                                : [
                                    PieChartSectionData(
                                      color: Color(0xFF5594FF),
                                      value: totals['carb'] ?? 0,
                                      title: '',
                                      borderSide: BorderSide.none,
                                    ),
                                    PieChartSectionData(
                                      color: Color(0xFF0352CF),
                                      value: totals['protein'] ?? 0,
                                      title: '',
                                      borderSide: BorderSide.none,
                                    ),
                                    PieChartSectionData(
                                      color: Color(0xFF023B95),
                                      value: totals['fat'] ?? 0,
                                      title: '',
                                      borderSide: BorderSide.none,
                                    ),
                                    // PieChartSectionData(
                                    //   color: Color(0xFF99C2FF),
                                    //   value: totals['calories'] ?? 0,
                                    //   title: '',
                                    //   borderSide: BorderSide.none,
                                    // ),
                                  ],
                            sectionsSpace: 0,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
// Total rows
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
                              'Total Carbs',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              '${totals['carb']?.toStringAsFixed(1)} g',
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
                              'Total Protein',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              '${totals['protein']?.toStringAsFixed(1)} g',
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
                              'Total Fat',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              '${totals['fat']?.toStringAsFixed(1)} g',
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
                              'Total Calories',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 17, 4, 4),
                            child: Text(
                              '${totals['calories']?.toStringAsFixed(1)} kcal',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

//main add button
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 50, 0, 50),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _validate,
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF023B96),
                          minimumSize: const Size(double.infinity, 44),
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
      ),
    );
  }

//Meal info card
  Widget _buildMealInfoForm() {
    return Form(
      key: _formKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: const Color(0x33000000),
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 15, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Title',
                  style: TextStyle(
                    fontSize: 25,
                    color: Color(0xFF023B96),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 5, 25, 0),
              child: TextFormField(
                focusNode: myFocusNode,
                decoration: InputDecoration(
                  hintText: 'Title (Optional)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 15),
                validator: (value) {
                  if (value != null && value.length > 20) {
                    return 'Title cannot exceed 20 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = (value == null || value.isEmpty) ? 'Meal' : value;
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(25, 20, 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Time',
                  style: TextStyle(
                    fontSize: 25,
                    color: Color(0xFF023B96),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 5, 0, 20),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _showTimePicker,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: const Color(0xFF023B96),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.timer_sharp, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Pick Time',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 25),
                  Text(
                    _timeOfDay.format(context),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

//added ingredients cards
  Widget _buildFoodItemCard(foodItem item, int index) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 4.0,
              color: const Color(0x32000000),
              offset: const Offset(0.0, 2.0),
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE6F2FF),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(19.0, 15.0, 10.0, 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF023B96),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Divider(
                            color: Color.fromARGB(255, 140, 140, 140),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildItemColumn(
                              item.portion == -1 ? '-' : '${item.portion} g',
                              'Portion Size',
                            ),
                            _buildItemColumn(
                              '${item.carb.toStringAsFixed(2)} g',
                              'Carbs',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color.fromARGB(255, 51, 51, 51),
                        size: 25.0,
                      ),
                      onPressed: () {
//edit button
                        if (item.source == "barcode") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditFoodItem(index, foodItems),
                            ),
                          );
                        }
                        if (item.source == "nutritions") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditNutritions(index, foodItems),
                            ),
                          );
                        }
                        if (item.source == "FatSecret API") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Addfooditem(
                                calorie: item.calorie,
                                protein: item.protein,
                                carb: item.carb,
                                fat: item.fat,
                                name: item.name,
                                portion: item.portion,
                                source: item.source,
                                mealItems: foodItems,
                                index: index,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 25.0,
                      ),
                      onPressed: () {
                        setState(() {
                          foodItems.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// for Portion Size and carb col
  Widget _buildItemColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 51, 51, 51),
            ),
          ),
        ),
        SizedBox(width: 100),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 102, 102, 102),
            ),
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateTotals() {
    double totalCarb = 0.0;
    double totalProtein = 0.0;
    double totalFat = 0.0;
    double totalCalories = 0.0;

    for (var item in foodItems) {
      totalCarb += item.carb;
      totalProtein += item.protein;
      totalFat += item.fat;
      totalCalories += item.calorie;
    }

    return {
      'carb': totalCarb,
      'protein': totalProtein,
      'fat': totalFat,
      'calories': totalCalories,
    };
  }
}
