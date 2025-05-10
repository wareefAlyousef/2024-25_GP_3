import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_sync/MainNavigation.dart';
import '../models/carbohydrate_model.dart';
import '../services/user_service.dart';

class AddCarb extends StatefulWidget {
  @override
  _AddCarb createState() => _AddCarb();
}

class _AddCarb extends State<AddCarb> {
  String _title = "";
  String _carb = "";
  TimeOfDay _timeOfDay = TimeOfDay.now();
  DateTime _now = new DateTime.now();
  final _formKey = GlobalKey<FormState>();
  FocusNode myfocus = FocusNode();
  FocusNode myfocus2 = FocusNode();

  void _showTimePicker() {
    myfocus.unfocus();
    myfocus2.unfocus();
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFF023B96),
            colorScheme: ColorScheme.light(
              primary: Color(0xFF023B96), // Primary color for the theme

              secondary: Colors.grey, // Secondary color for other elements
            ),
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    ).then((value) {
      setState(() {
        _timeOfDay = value!;
      });
    });
  }

  String? _errorMessage = null; //not in addnote(?)

  void _validate() {
    _submitForm();
  }

  // Method to show confirmation dialog
  void _showConfirmationDialog() {
    myfocus.unfocus();
    myfocus2.unfocus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String $title = _title;
        String $carb = _carb;
        String $time = _timeOfDay.format(context);

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
                      Icons.fastfood, //FontAwesomeIcons.syringe
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
                            'Carb amount: ',
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
                            $carb,
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

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Cancel button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF023B96),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), // Make buttons the same size
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
                            Navigator.of(context).pop(); // Close the dialog
                            _submitForm();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF023B96)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize:
                                Size(120, 44), // Make buttons the same size
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

// Form submission method
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // If the form is valid we should replace this with our submission logic
      DateTime _newDateTime = DateTime(_now.year, _now.month, _now.day,
          _timeOfDay.hour, _timeOfDay.minute, 0);

      double _carbdouble = double.parse(_carb);
      Carbohydrate myCarb =
          Carbohydrate(amount: _carbdouble, time: _newDateTime, title: _title);

      UserService sevice = new UserService();
      if (await sevice.addCarbohydrate(myCarb)) {
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissal by tapping outside
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min, // Fit the content
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xff023b96),
                    size: 80, // Large icon size
                  ),
                  SizedBox(height: 25), // Space between icon and text
                  Text(
                    'Carb is added successfully!',
                    textAlign: TextAlign.center, // Center the text
                    style: TextStyle(fontSize: 22), // Larger text
                  ),
                ],
              ),
            );
          },
        );
        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainNavigation()),
            (Route<dynamic> route) => false,
          );
        });
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
                    'Failed adding the carb!',
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
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Color(0xff023b96),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(100, 44), // Make buttons the same size
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf1f4f8),
      appBar: AppBar(
        backgroundColor: Color(0xFFf1f4f8),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 30.0,
          ),
          onPressed: () {
            Navigator.pop(context);
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
                  'Add Carbs',
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
                              focusNode: myfocus,
                              decoration: InputDecoration(
                                hintText: 'Title (Optional)',
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
                                  return 'Title cannot exceed 20 characters';
                                }
                                return null; // validation passed
                              },
                              onSaved: (value) {
                                _title = (value == null || value.isEmpty)
                                    ? 'Carb'
                                    : value;
                              },
                            ),
                          ),
// container for amount title
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Carb Amount ',
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Color.fromRGBO(96, 106, 133, 1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
//user input 2

                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 5, 25, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
// Carb form field
                                    focusNode: myfocus2,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [
                                      // Allow numbers and decimals
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: 'Amount of carbs in grams',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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
                                        return 'Please enter the amount of carbs';
                                      }
                                      // parse the value to a double for validation
                                      final carbValue = double.tryParse(value);
                                      if (carbValue == null || carbValue <= 0) {
                                        return 'Please enter a number greater than 0';
                                      }
                                      if (RegExp(r'^\d+\.?\d{0,2}$')
                                              .hasMatch(value) ==
                                          false) {
                                        return 'Please enter to 2 decimal places only';
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

// container for time title
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 20, 0, 0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Time',
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Color.fromRGBO(96, 106, 133, 1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),

// container for time user input 3
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 5, 0, 20),
                            child: Row(
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: ElevatedButton(
                                    onPressed: _showTimePicker,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      backgroundColor: Colors.grey[100],
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(width: 3),
                                        Icon(Icons.timer_sharp,
                                            size: 24, color: Colors.black),
                                        SizedBox(width: 10),
                                        Text(
                                          'Pick Time',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                      ],
                                    ),
                                  ),
                                ),
//displaying the chosen time
                                Padding(
                                  padding: EdgeInsets.fromLTRB(25, 5, 0, 0),
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _timeOfDay.format(context).toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
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

                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 150, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validate the form and then open the dialog
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _showConfirmationDialog();
                                }
                              },
                              child: Text(
                                'Add',
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
