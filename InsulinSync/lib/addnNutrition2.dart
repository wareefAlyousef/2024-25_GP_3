import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insulin_sync/MainNavigation.dart';
import '../models/foodItem_model.dart';
import '../services/user_service.dart';
import '../models/meal_model.dart';
import 'mealDose.dart';
import 'models/glucose_model.dart';

class AddNutrition2 extends StatefulWidget {
  @override
  AddNutrition2();

  _AddNutrition2 createState() => _AddNutrition2();
}

class _AddNutrition2 extends State<AddNutrition2> {
  late List<foodItem> mealItems;
  String _carb = "";
  String _fat = "";
  String _protein = "";
  String _calorie = "";
  String _name = "";
  final _formKey = GlobalKey<FormState>();
  TimeOfDay _timeOfDay = TimeOfDay.now();
  DateTime _now = new DateTime.now();
  FocusNode myfocus1 = FocusNode();
  FocusNode myfocus2 = FocusNode();
  FocusNode myfocus3 = FocusNode();
  FocusNode myfocus4 = FocusNode();
  FocusNode myfocus5 = FocusNode();

  bool isItemFavorite = false;
  String? favoriteItemId = null;
  UserService user_service = UserService();

  var titleController = TextEditingController();
  var carbController = TextEditingController();
  var proteinController = TextEditingController();
  var fatController = TextEditingController();
  var calorieController = TextEditingController();

  void _showTimePicker() {
    myfocus1.unfocus();
    myfocus2.unfocus();
    myfocus3.unfocus();
    myfocus4.unfocus();
    myfocus5.unfocus();

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

  void _showConfirmationDialog() {
    myfocus1.unfocus();
    myfocus2.unfocus();
    myfocus3.unfocus();
    myfocus4.unfocus();
    myfocus5.unfocus();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String $carb = _carb;
        String $protein = _protein;
        String $fat = _fat;
        String $calorie = _calorie;

        String $title = _name;
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
                      Icons.fastfood,
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
                            'Carb: ',
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
                            'Protein: ',
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
                            $protein,
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
                            'Fat: ',
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
                            $fat,
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
                            'Calorie: ',
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
                            $calorie,
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

  Future<void> _submitForm() async {
    print("submit1111");
    if (_formKey.currentState!.validate()) {
      DateTime _newDateTime = DateTime(_now.year, _now.month, _now.day,
          _timeOfDay.hour, _timeOfDay.minute, 0);
      double _carbdouble = double.parse(_carb);
      double _proteindouble = double.parse(_protein);
      double _fatdouble = double.parse(_fat);
      double _caloriedouble = double.parse(_calorie);
      String name = _name;

      final newItem = foodItem(
        name: name,
        calorie: _caloriedouble,
        protein: _proteindouble,
        carb: _carbdouble,
        fat: _fatdouble,
        portion: -1,
        source: "nutritions",
      );

      _formKey.currentState!.save();
      UserService service = UserService();

      double? currentBG;

      // Fetch current glucose data
      await service.fetchCurrentGlucose();

      // Listen to glucose stream
      service.glucoseStream.listen(
        (value) {
          setState(() {
            currentBG = value; // Update glucose level
          });
          print("Fetched Glucose Level: $value");
        },
        onError: (error) {
          setState(() {
            currentBG = null; // Reset glucose level on error
          });
          print("Error in Glucose Stream: $error");
        },
      );

      // Fetch "manual" glucose readings within the last 15 minutes
      final Stream<List<GlucoseReading>> glucoseStream =
          service.getGlucoseReadingsStream(source: 'manual');

      // Get the most recent snapshot from the stream
      final List<GlucoseReading> readings = await glucoseStream.first;

      // Calculate the cutoff time
      final DateTime now = DateTime.now();
      final DateTime cutoffTime = now.subtract(const Duration(minutes: 15));

      // Filter readings within the last 15 minutes
      final List<GlucoseReading> recentReadings = readings
          .where((reading) => reading.time.isAfter(cutoffTime))
          .toList();

      // Update `currentBG` if there are recent readings
      if (recentReadings.isNotEmpty) {
        setState(() {
          currentBG = recentReadings.last.reading;
        });
        print("Recent Manual Glucose Reading: ${recentReadings.last.reading}");
      }

      DateTime _mealDateTime = DateTime(
        _now.year,
        _now.month,
        _now.day,
        _timeOfDay.hour,
        _timeOfDay.minute,
        0,
      );

      // Calculate the allowed range
      DateTime thirtyMinutesBefore = now.subtract(Duration(minutes: 30));
      DateTime thirtyMinutesAfter = now.add(Duration(minutes: 30));

      meal mymeal = meal(time: _newDateTime, title: name, foodItems: [newItem]);
      print("meal created");

      UserService sevice = new UserService();
      String? mealId = await sevice.addMeal(mymeal);
      if (mealId != null) {
        print("meal added");
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
                    'Nutritions are added successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close dialog manually if needed
                      if (currentBG == null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainNavigation(),
                          ),
                        );
                        // } else if (_newDateTime.isBefore(thirtyMinutesBefore)) {
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //   builder: (context) => tookDose(),
                        //   ),
                        // );
                      } else if (_newDateTime.isAfter(thirtyMinutesBefore) &&
                          _newDateTime.isBefore(thirtyMinutesAfter) &&
                          currentBG! > 70) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => mealDose(
                              currentMeal: mymeal,
                              mealId: mealId,
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainNavigation(),
                          ),
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
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop(); // Close the dialog
          // Navigate based on the time condition
          if (currentBG == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(),
              ),
            );
            // } else if (_newDateTime.isBefore(thirtyMinutesBefore)) {
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //   builder: (context) => tookDose(),
            //   ),
            // );
          } else if (_newDateTime.isAfter(thirtyMinutesBefore) &&
              _newDateTime.isBefore(thirtyMinutesAfter) &&
              currentBG! > 70) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => mealDose(
                  currentMeal: mymeal,
                  mealId: mealId,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigation(),
              ),
            );
          }
        });
      } else {
        print("meal not added");
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
                    'Failed adding the Nutritions!',
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
                  'Add Nutritions',
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(0, 10, 20, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isItemFavorite =
                                          !isItemFavorite; // Toggle favorite state
                                    });

                                    // Call the appropriate function based on the state
                                    if (isItemFavorite) {
                                      saveFavorite(); // Call function when favorited
                                    } else {
                                      removeFromFavorite(); // Call function when removed from favorites
                                    }
                                  },
                                  child: Container(
                                    width: 21,
                                    padding: const EdgeInsets.all(0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      // border:
                                      //     Border.all(color: const Color(0xFF023B96)),
                                    ),
                                    child: Icon(
                                      isItemFavorite
                                          ? Icons.favorite
                                          : Icons
                                              .favorite_border, // Dynamic icon
                                      color: isItemFavorite
                                          ? Theme.of(context).colorScheme.error
                                          : const Color(
                                              0xFF023B96), // Dynamic color
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
//user input 1
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 30, 25, 0),
                            child: TextFormField(
                              controller: titleController,
                              focusNode: myfocus1,
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
                                if (value == null || value.length == 0) {
                                  value = "Nutritions";
                                }

                                _name = value;
                                return null; // validation passed
                              },
                            ),
                          ),

                          // SizedBox(height: 20),
// user input 1
                          Padding(
                            padding: EdgeInsets.fromLTRB(25, 15, 0, 0),
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
                                            controller: carbController,
                                            focusNode: myfocus2,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
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
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter the carb';
                                              }

                                              final carbValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }

                                              _carb = value;

                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
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
// user input 3
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
                                            controller: proteinController,
                                            focusNode: myfocus3,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Optional',
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
                                              if (value == null ||
                                                  value.isEmpty) {
                                                value = "0";
                                              }

                                              final proteinValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _protein = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                                            controller: fatController,
                                            focusNode: myfocus4,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Optional',
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
                                              if (value == null ||
                                                  value.isEmpty) {
                                                value = "0";
                                              }

                                              final fatValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _fat = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
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

                          // user input 5
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
                                            controller: calorieController,
                                            focusNode: myfocus5,
                                            keyboardType:
                                                TextInputType.numberWithOptions(
                                                    decimal: true),
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp(r'^\d*\.?\d*')),
                                            ],
                                            decoration: InputDecoration(
                                              hintText: 'Optional',
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
                                              if (value == null ||
                                                  value.isEmpty) {
                                                value = "0";
                                              }

                                              final calorieValue =
                                                  double.tryParse(value);

                                              if (!RegExp(r'^\d+\.?\d{0,2}$')
                                                  .hasMatch(value)) {
                                                return '2 decimal places only';
                                              }
                                              _calorie = value;
                                              return null; // If all validations pass
                                            },
                                            onFieldSubmitted: (_) {
                                              saveFavorite(); // This will trigger the focus listener in initState
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                          SizedBox(height: 10),
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

  void saveFavorite() async {
    if (!isItemFavorite) return;

    if (carbController.text.isEmpty) {
      removeFromFavorite();
      return;
    }

    foodItem item = foodItem(
      name: titleController.text.isEmpty ? "food item" : titleController.text,

      calorie: calorieController.text.isEmpty
          ? 0.0
          : double.tryParse(calorieController.text) ??
              0.0, // Check if empty, then parse
      protein: proteinController.text.isEmpty
          ? 0.0
          : double.tryParse(proteinController.text) ??
              0.0, // Check if empty, then parse
      carb: carbController.text.isEmpty
          ? 0.0
          : double.tryParse(carbController.text) ??
              0.0, // Check if empty, then parse
      fat: fatController.text.isEmpty
          ? 0.0
          : double.tryParse(fatController.text) ??
              0.0, // Check if empty, then parse
      portion: -1,
      source: "nutritions",
      favoriteId: favoriteItemId,
    );

    // If favoriteId is null, it's a new favorite, so add it
    if (favoriteItemId == null) {
      favoriteItemId = await user_service.addItemToFavorite(item);
    } else {
      // Otherwise, update the existing favorite
      user_service.updateFavoriteItem(
        itemId: favoriteItemId!,
        newName: item.name,
        newCalorie: item.calorie, // Use tryParse and default to 0.0
        newProtein: item.protein, // Use tryParse and default to 0.0
        newCarb: item.carb, // Use tryParse and default to 0.0
        newFat: item.fat, // Use tryParse and default to 0.0
        newPortion: -1,
        newSource: "nutritions",
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
