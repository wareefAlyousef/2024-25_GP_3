import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_sync/MainNavigation.dart';
import '../models/workout_model.dart';
import '../services/user_service.dart';
import 'models/meal_model.dart';
import 'mealDose.dart';

class AddPhysicalActivity extends StatefulWidget {
  final bool? fromDosePage;
  final meal? currentMeal;
  final String? mealId;

  const AddPhysicalActivity(
      {Key? key, this.fromDosePage, this.currentMeal, this.mealId})
      : super(key: key);

  @override
  _AddPhysicalActivity createState() => _AddPhysicalActivity();
}

class _AddPhysicalActivity extends State<AddPhysicalActivity> {
  String _title = "";
  String _selectedIntensity = "";
  String _duration = "";
  TimeOfDay _timeOfDay = TimeOfDay.now();
  DateTime _now = new DateTime.now();
  FocusNode myfocus = FocusNode();
  FocusNode myfocus2 = FocusNode();

  // late bool fromDosePage;
  // late meal currentMeal;
  // late String mealId;

  final _formKey = GlobalKey<FormState>();

  void _showIntensityInfo(BuildContext context) {
    myfocus.unfocus();
    myfocus2.unfocus();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Activity Intensity Levels',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff023b96),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Low: Activities that require minimal effort.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Moderate: Activities that elevate your heart rate and breathing.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'High: Activities that significantly raise your heart rate and breathing.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
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
      setState(() {
        _timeOfDay = value!;
      });
    });
  }

  String? _errorMessage = null;
  void _validate() {
    _validateIntensity();
    _submitForm();
  }

// form validation for intesity (choices)
  void _validateIntensity() {
    setState(() {
      if (_selectedIntensity == null || _selectedIntensity == "") {
        _errorMessage = "Please select an intensity level";
      } else {
        _errorMessage = null;
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
        String $title = _title;
        String $selectedIntensity = _selectedIntensity;
        String $duration = _duration;
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
                      Icons.fitness_center,
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
                            'Intensity: ',
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
                            $selectedIntensity,
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
                            'Duration: ',
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
                            $duration,
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

// form submission method

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _errorMessage == null) {
      DateTime _newDateTime = DateTime(_now.year, _now.month, _now.day,
          _timeOfDay.hour, _timeOfDay.minute, 0);
      double _durationdouble = double.parse(_duration);

      Workout activity = Workout(
          title: _title,
          time: _newDateTime,
          duration: _durationdouble.toInt(),
          intensity: _selectedIntensity,
          source: "Manual");
      UserService sevice = UserService();
      if (await sevice.addWorkout(activity)) {
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
                    'Physical activity is added successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 30),
                  OutlinedButton(
                    //                   onPressed: () {
                    //                     Navigator.pushAndRemoveUntil(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => MainNavigation()),
                    //   (Route<dynamic> route) => false,
                    // );
                    //                   },
                    onPressed: () {
                      if (widget.fromDosePage == true) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => mealDose(
                                  currentMeal: widget.currentMeal,
                                  mealId: widget.mealId)),
                          (Route<dynamic> route) => false,
                        );
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MainNavigation()),
                          (Route<dynamic> route) => false,
                        );
                      }
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
// Future.delayed(Duration(seconds: 3), () {
//   Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (context) => MainNavigation()),
//     (Route<dynamic> route) => false,
//   );
// });
        Future.delayed(Duration(seconds: 3), () {
          if (widget.fromDosePage == true) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => mealDose(
                      currentMeal: widget.currentMeal, mealId: widget.mealId)),
              (Route<dynamic> route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainNavigation()),
              (Route<dynamic> route) => false,
            );
          }
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
                    'Failed adding the physical activity!',
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

      ;
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
                  'Add Physical Activity',
                  style: TextStyle(
                    fontSize: 30,
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
                              //form validator
                              validator: (value) {
                                if (value != null && value.length > 20) {
                                  return 'Title cannot exceed 20 characters';
                                }
                                return null; // validation passed
                              },
                              onSaved: (value) {
                                _title = (value == null || value.isEmpty)
                                    ? 'Physical Activity'
                                    : value;
                              },
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 20, 0, 0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  Text(
                                    'Intensity',
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Color.fromRGBO(96, 106, 133, 1),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Color.fromRGBO(96, 106, 133, 1),
                                    ),
                                    onPressed: () {
                                      _showIntensityInfo(context);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

//user input 2

                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 0, 25, 0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8.0,
                                    children: [
                                      ChoiceChip(
                                        backgroundColor: Colors.grey[100],
                                        label: Text('Low'),
                                        selected: _selectedIntensity == 'Low',
                                        selectedColor: Color(0x4C095AEC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          side: BorderSide(
                                            color: (_selectedIntensity == "" &&
                                                    _errorMessage != null)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                : Color(0xFF023B95),
                                            width: 1.0,
                                          ),
                                        ),
                                        onSelected: (bool selected) {
                                          setState(() {
                                            _selectedIntensity = 'Low';
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        backgroundColor: Colors.grey[100],
                                        label: Text('Moderate'),
                                        selected:
                                            _selectedIntensity == 'Moderate',
                                        selectedColor: Color(0x4C095AEC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          side: BorderSide(
                                            color: (_selectedIntensity == "" &&
                                                    _errorMessage != null)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                : Color(0xFF023B95),
                                            width: 1.0,
                                          ),
                                        ),
                                        onSelected: (bool selected) {
                                          setState(() {
                                            _selectedIntensity = 'Moderate';
                                          });
                                        },
                                      ),
                                      ChoiceChip(
                                        backgroundColor: Colors.grey[100],
                                        label: Text('High'),
                                        selected: _selectedIntensity == 'High',
                                        selectedColor: Color(0x4C095AEC),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          side: BorderSide(
                                            color: (_selectedIntensity == "" &&
                                                    _errorMessage != null)
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .error
                                                : Color(0xFF023B95),
                                            width: 1.0,
                                          ),
                                        ),
                                        onSelected: (bool selected) {
                                          setState(() {
                                            _selectedIntensity = 'High';
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  // Conditional rendering of the error message
                                  if (_errorMessage != null)
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(7, 0, 0, 0),
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 194, 43, 98),
                                            fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 15, 0, 0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Color.fromRGBO(96, 106, 133, 1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          //user input 3
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 5, 25, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    // Duration form field
                                    focusNode: myfocus2,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      // Allow numbers and decimals
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*')),
                                    ],
                                    decoration: InputDecoration(
                                      hintText: 'Activity duration in minutes',
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
                                        return 'Please enter the actvity duration';
                                      }

                                      if (RegExp(r'^\d+$').hasMatch(value) ==
                                          false) {
                                        return 'Please enter a whole number';
                                      }

                                      int minutes = int.parse(value);

                                      if (minutes < 1) {
                                        return 'Please enter a number greater than 0';
                                      }

                                      _duration = value;
                                      return null; // If all validations pass
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                  child: Text(
                                    'minute',
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
                      padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _validateIntensity();
                                // Validate the form and then open the dialog
                                if (_formKey.currentState!.validate() &&
                                    _errorMessage == null) {
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
