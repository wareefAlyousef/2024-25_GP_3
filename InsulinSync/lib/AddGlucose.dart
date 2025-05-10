import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_sync/MainNavigation.dart';
import '../models/glucose_model.dart';
import '../services/user_service.dart';

class AddGlucose extends StatefulWidget {
  @override
  _AddGlucose createState() => _AddGlucose();
}

class _AddGlucose extends State<AddGlucose> {
  String _title = "";
  String _glucose = "";
  TimeOfDay _timeOfDay = TimeOfDay.now();
  DateTime _now = new DateTime.now();
  final _formKey = GlobalKey<FormState>();
  FocusNode myfocus = FocusNode();
  FocusNode myfocus2 = FocusNode();

  String? _timeErrorMessage;

  void _showTimePicker() {
    myfocus.unfocus();
    myfocus2.unfocus();

    // Get the current time
    TimeOfDay now = TimeOfDay.now();

    showTimePicker(
      context: context,
      initialTime: now, // Start from the current time
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
        // Validate selected time
        if (value.hour < now.hour ||
            (value.hour == now.hour && value.minute <= now.minute)) {
          setState(() {
            _timeOfDay = value;
            _timeErrorMessage = null; // Clear error message
          });
        } else {
          setState(() {
            _timeErrorMessage = "Please select a time in the past";
          });
        }
      }
    });
  }

  String? _errorMessage = null; //not in addnote(?)

  void _validate() {
    //not in addnote(?)
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
        String $glucose = _glucose;
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
                      Icons.bloodtype, //FontAwesomeIcons.syringe
                      size: 100,
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
                            $title, // Display time with title
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
                            'Glucose Reading: ',
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
                            $glucose,
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

      double _glucosedouble = double.parse(_glucose);
      GlucoseReading myReading = GlucoseReading(
          source: 'manual',
          time: _newDateTime,
          reading: _glucosedouble,
          title: _title);

      UserService sevice = new UserService();
      if (await sevice.addGlucoseReading(myReading)) {
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
                    'Glucose is added successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MainNavigation()),
                        (Route<dynamic> route) => false,
                      );
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
                    'Failed adding the glucose!',
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
    } else {}
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
                  'Add Glucose Reading',
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
                                    ? 'Glucose Reading'
                                    : value;
                              },
                            ),
                          ),
// container for reading title
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 25, 0, 0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Glucose Reading ',
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
// Glucose form field
                                    focusNode: myfocus2,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      // Allow numbers and decimals
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: InputDecoration(
                                      hintText:
                                          'Glucose in milligrams per deciliter',
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
                                        return 'Please enter the glucose reading';
                                      }
                                      // parse the value to a double for validation
                                      final glucoseValue =
                                          double.tryParse(value);
                                      if (glucoseValue == null ||
                                          glucoseValue <= 0) {
                                        return 'Please enter a number greater than 0';
                                      }
                                      if (RegExp(r'^\d+$').hasMatch(value) ==
                                          false) {
                                        return 'Please enter a whole number for the reading';
                                      }
                                      _glucose = value;
                                      return null; // If all validations pass
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                  child: Text(
                                    'mg/dL',
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
                            padding: EdgeInsets.fromLTRB(25, 5, 0, 4),
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
                          // Error message display for Time Picker
                          if (_timeErrorMessage != null)
                            Padding(
                              padding: EdgeInsets.only(left: 35, bottom: 10),
                              child: Align(
                                alignment: Alignment
                                    .centerLeft, // Aligns text to the left
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    _timeErrorMessage!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(0, 150, 0, 0), // check at the end
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
