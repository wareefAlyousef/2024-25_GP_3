import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:insulin_sync/AddFoodItem.dart';
import 'package:insulin_sync/EditNutritions.dart';
import 'package:insulin_sync/models/foodItem_model.dart';
import '../models/meal_model.dart';
import '../services/user_service.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'package:fl_chart/fl_chart.dart';
import "AddBySearch.dart";
import 'addByImage.dart';
import 'mealDose.dart';
import 'models/glucose_model.dart';

////////
class Cart extends StatefulWidget {
  final List<foodItem>? foodItems; // Nullable list of food items
  final bool isFavorite; // Boolean for favorite state
  final String? favoriteId; // Nullable favoriteId
  final DateTime time; // Final DateTime to store time
  final String title; // Title for the Cart
  final String id; // Cart identifier

  // Constructor for Cart widget
  Cart({
    this.foodItems,
    this.isFavorite = false, // Default value for isFavorite is false
    this.favoriteId, // Nullable favoriteId
    DateTime? time, // Default time if null
    required this.id, // Default id if null
    String? title, // Default title if null
  })  : this.time =
            time ?? DateTime(1990, 1, 1, 12), // Default DateTime if null
        this.title = title ?? "Title is not defined"; // Default title if null
  // this.id = id ?? "-1"; // Default id if null

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  late DateTime initialTime1;
  late String initialTitle;
  late String initialId;
  late TimeOfDay initialTimeOfDay;
  late TextEditingController initialTitle1;
  late TimeOfDay initialTimeOfDay2;
  late String addOrEdit;
  late String addOrEdit2;
  final _formKey = GlobalKey<FormState>();
  String _title = "";
  // if date not null, assign it to timeofday, otherwise assign today

  TimeOfDay _timeOfDay = TimeOfDay.now();
  final DateTime _now = DateTime.now();
  late List<foodItem> foodItems;
  FocusNode myFocusNode = FocusNode();
  FocusNode myfocus = FocusNode();
  FocusNode myfocus2 = FocusNode();
  bool showWarning = false;
  // var titleController = TextEditingController();

  UserService user_service = UserService();

  late bool isFavorite;
  late String? favoriteId;

  late FocusNode titleFocusNode;

  @override
  void initState() {
    super.initState();

    _timeOfDay = TimeOfDay.fromDateTime(widget.time);
    foodItems = widget.foodItems ?? [];

    isFavorite = widget.isFavorite;
    favoriteId = widget.favoriteId;

    saveFavorite();

    titleFocusNode = FocusNode();
    initialTitle = widget.title;
    initialId = widget.id;
    initialTime1 = widget.time;
    initialTimeOfDay = TimeOfDay.fromDateTime(initialTime1);
    if (initialTitle != "Title is not defined") {
      initialTitle1 = TextEditingController(text: initialTitle);
    } else {
      initialTitle1 = TextEditingController(text: "");
    }
    if (initialId == "-1") {
      initialTimeOfDay2 = TimeOfDay.now();
      _timeOfDay = TimeOfDay.now();
      addOrEdit = "Add";
      addOrEdit2 = "added";
    } else {
      initialTimeOfDay2 = initialTimeOfDay;
      _timeOfDay = initialTimeOfDay;
      addOrEdit = "Save";
      addOrEdit2 = "edited";
    }
  }

  void _showTimePicker() {
    myFocusNode.unfocus();
    showTimePicker(
      context: context,
      initialTime: initialTimeOfDay2,
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

  bool checkEditedNutrutions(foodItem item) {
    bool edited = false;

    // Loop on each item that has 'image' as its source

    if (item.calorie != item.predictedCalorie) {
      edited = true;
    }
    if (item.protein != item.predictedProtein) {
      edited = true;
    }
    if (item.carb != item.predictedCarb) {
      edited = true;
    }
    if (item.fat != item.predictedFat) {
      edited = true;
    }
    if (item.portion != item.predictedPortion) {
      edited = true;
    }

    return edited;
  }

  bool checkEditedName(foodItem item) {
    if (item.predictedName == null) {
      return false; // No prediction available, no edit needed
    }

    print('checkEditedName: 2');
    List<String> originalIngredients = item.predictedName!
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .toList();
    List<String> editedIngredients =
        item.name.split(',').map((e) => e.trim().toLowerCase()).toList();

    originalIngredients.sort();
    editedIngredients.sort();

    bool edited = !listEquals(originalIngredients, editedIngredients);

    return edited;
  }

  void writeCorrectedPrediction(
      foodItem item, bool editedNutritions, bool editedName) {
    final firestore = FirebaseFirestore.instance;

    final Map<String, dynamic> actualValues = item.toMap();
    final Map<String, dynamic> predictedValues = item.predictedToMap();

    final Map<String, dynamic> flatData = {
      ...actualValues,
      ...predictedValues,
      'editedName': editedName,
      'editedNutritions': editedNutritions,
      'imageUrl': item.imageUrl, // Include imageUrl explicitly
      'timestamp': FieldValue.serverTimestamp(),
    };

    firestore
        .collection('correctedPredictions')
        .add(flatData)
        .then((docRef) {})
        .catchError((error) {
      print("Failed to write corrected prediction: $error");
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
                            addOrEdit,
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

  String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  Future<String?> uploadImage(File image) async {
    try {
      // get the extenstion of the image
      String fileExtension = image.path.split('.').last;

      // Create a unique file name for the image
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String randomString =
          _generateRandomString(10); // Generate a random string
      String? userId = user_service
          .currentUserId; // Replace with actual user ID retrieval logic

      // Combining user ID, timestamp, and random string to form a unique file name
      String fileName =
          '${userId ?? 'defaultUserId'}_$timestamp$randomString.$fileExtension';

      final storage = FirebaseStorage.instanceFor(
          bucket: 'gs://insulinsync.firebasestorage.app');

      // Debug: File name generated
      print('debug uploadImage: Generated file name: $fileName');

      // Reference to Firebase Storage
      Reference ref =
          storage.ref().child(userId ?? 'defaultUserId').child(fileName);

      // Upload the image file to Firebase Storage
      UploadTask uploadTask = ref.putFile(image);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => null);

      // Check if upload was successful
      if (snapshot.state == TaskState.success) {
        // Get the download URL of the uploaded image
        String downloadUrl = await snapshot.ref.getDownloadURL();

        return downloadUrl;
      } else {
        return null;
      }
    } catch (e) {
      //Error occurred during upload
      print('debug uploadImage: Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff023b96)),
          ),
        ),
      );

      UserService service = UserService();
      double? currentBG;

      try {
        // Fetch current glucose data
        await service.fetchCurrentGlucose();

        // Listen to glucose stream
        final glucoseSubscription = service.glucoseStream.listen(
          (value) {
            if (mounted) {
              setState(() {
                currentBG = value;
              });
            }
            print("Fetched Glucose Level: $value");
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                currentBG = null;
              });
            }
            print("Error in Glucose Stream: $error");
          },
        );

        // Fetch manual glucose readings
        final Stream<List<GlucoseReading>> glucoseStream =
            service.getGlucoseReadingsStream(source: 'manual');
        final List<GlucoseReading> readings = await glucoseStream.first;
        final DateTime now = DateTime.now();
        final DateTime cutoffTime = now.subtract(const Duration(minutes: 15));
        final List<GlucoseReading> recentReadings = readings
            .where((reading) => reading.time.isAfter(cutoffTime))
            .toList();

        if (recentReadings.isNotEmpty) {
          if (mounted) {
            setState(() {
              currentBG = recentReadings.last.reading;
            });
          }
          print(
              "Recent Manual Glucose Reading: ${recentReadings.last.reading}");
        }

        DateTime _newDateTime = DateTime(
          _now.year,
          _now.month,
          _now.day,
          _timeOfDay.hour,
          _timeOfDay.minute,
          0,
        );

        // Calculate allowed range
        DateTime thirtyMinutesBefore = now.subtract(Duration(minutes: 30));
        DateTime thirtyMinutesAfter = now.add(Duration(minutes: 30));

        // Set default title if empty
        if (_title.trim().isEmpty) {
          _title = 'Meal';
        }

        meal myMeal =
            meal(time: _newDateTime, title: _title, foodItems: foodItems);

        if (initialId != "-1") {
          await user_service.deleteMeal(initialId);
        }

        // Upload images
        for (var item in foodItems) {
          if ((item.imageUrl == null || item.imageUrl!.isEmpty) &&
              item.image != null) {
            String? imageUrl = await uploadImage(item.image!);
            if (imageUrl != null) {
              item.imageUrl = imageUrl;
            }
          }
        }

        // Process corrected predictions
        for (var item in foodItems) {
          if (item.source == 'image') {
            bool editedNutritions = checkEditedNutrutions(item);
            bool editedName = checkEditedName(item);
            writeCorrectedPrediction(item, editedNutritions, editedName);
          }
        }

        String? mealId = await service.addMeal(myMeal);
        glucoseSubscription.cancel();

        // Remove loading spinner
        Navigator.of(context).pop();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(context).pop();
              _navigateAfterSubmit(
                context,
                currentBG,
                _newDateTime,
                thirtyMinutesBefore,
                thirtyMinutesAfter,
                myMeal,
                mealId,
              );
            });

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
                    'Meal is $addOrEdit2 successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _navigateAfterSubmit(
                        context,
                        currentBG,
                        _newDateTime,
                        thirtyMinutesBefore,
                        thirtyMinutesAfter,
                        myMeal,
                        mealId,
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
      } catch (error) {
        // Remove loading spinner on error
        Navigator.of(context).pop();

        showDialog(
          context: context,
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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
        print('Error submitting form: $error');
      }
    }
  }

  void _navigateAfterSubmit(
    BuildContext context, // Add this parameter
    double? currentBG,
    DateTime mealTime,
    DateTime thirtyMinutesBefore,
    DateTime thirtyMinutesAfter,
    meal myMeal,
    String? mealId,
  ) {
    if (currentBG == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainNavigation()),
        (Route<dynamic> route) => false,
      );
    } else if (mealTime.isAfter(thirtyMinutesBefore) &&
        mealTime.isBefore(thirtyMinutesAfter) &&
        currentBG! > 70) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => mealDose(
            currentMeal: myMeal,
            mealId: mealId,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainNavigation()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildSuccessDialog(String addOrEdit2) {
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
            'Meal is $addOrEdit2 successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22),
          ),
          SizedBox(height: 30),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
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
                              saveFavorite();
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

  void _showEmptyFoodItemsDialog(BuildContext context) {
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
                    Icons.warning_amber_rounded,
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
                    (widget.id != -1)
                        ? 'The meal will not be saved. Do you still want to go back?'
                        : "Your edits will not be saved. Do you still want to go back?",
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
                    // Cancel Button
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
                    // Confirm Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MainNavigation()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size(120, 44),
                        ),
                        child: Text(
                          'Yes',
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var totals = _calculateTotals();
    return Scaffold(
      backgroundColor: const Color(0xFFf1f4f8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf1f4f8),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(255, 0, 0, 0),
            size: 30,
          ),
          onPressed: () {
            if (foodItems.isNotEmpty) {
              _showEmptyFoodItemsDialog(context); // Show confirmation dialog
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MainNavigation()),
              );
            }
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
                                builder: (context) => AddBySearch(
                                    id: widget.id,
                                    title: initialTitle1.text,
                                    time: initialTime1,
                                    mealItems: foodItems,
                                    isFavorite: isFavorite,
                                    favoriteId: favoriteId)),
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
                        child: Text(
                          addOrEdit,
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

// Meal info card
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: initialTitle1,
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
                        _title =
                            (value == null || value.isEmpty) ? 'Meal' : value;
                      },
                      onFieldSubmitted: (_) {
                        saveFavorite();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });

                      if (isFavorite) {
                        saveFavorite();
                      } else {
                        removeFromFavorite();
                      }
                    },
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Theme.of(context).colorScheme.error
                          : const Color(0xFF023B96),
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
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
                  const SizedBox(width: 16),
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
                              builder: (context) => Addfooditem(
                                id: initialId,
                                title: initialTitle1.text,
                                timeOfDay: _timeOfDay,
                                calorie: item.calorie,
                                protein: item.protein,
                                carb: item.carb,
                                fat: item.fat,
                                name: item.name,
                                portion: item.portion,
                                source: item.source,
                                mealItems: foodItems,
                                index: index,
                                favoriteId: favoriteId,
                                isFavorite: isFavorite,
                                favoriteItemId: item.favoriteId,
                              ),
                            ),
                          );
                        }
                        if (item.source == "nutritions") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditNutritions(
                                id: initialId,
                                title: initialTitle1.text,
                                index: index,
                                mealItems: foodItems,
                                favoriteId: favoriteId,
                                isFavorite: isFavorite,
                                favoriteItemId: item.favoriteId,
                              ),
                            ),
                          );
                        }
                        if (item.source == "FatSecret API") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Addfooditem(
                                id: initialId,
                                title: initialTitle1.text,
                                timeOfDay: _timeOfDay,
                                calorie: item.calorie,
                                protein: item.protein,
                                carb: item.carb,
                                fat: item.fat,
                                name: item.name,
                                portion: item.portion,
                                source: item.source,
                                mealItems: foodItems,
                                index: index,
                                favoriteId: favoriteId,
                                isFavorite: isFavorite,
                                favoriteItemId: item.favoriteId,
                              ),
                            ),
                          );
                        }

                        if (item.source.toLowerCase() == "image") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddByImage(
                                id: widget.id,
                                index: index,
                                name: item.name,
                                source: "Image",
                                image: item.image,
                                imageUrl: item.imageUrl,
                                portion: item.portion,
                                fat: item.fat,
                                carb: item.carb,
                                protein: item.protein,
                                calorie: item.calorie,
                                title: initialTitle1.text,
                                time: initialTime1,
                                mealItems: foodItems,
                                favoriteId: favoriteId,
                                isFavorite: isFavorite,
                                favoriteItemId: item.favoriteId,
                                // predections
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
                        saveFavorite();
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

  Padding buildCustomPadding(String title, Widget content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20, top: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5.0,
              color: Color(0x230E151B),
              offset: Offset(0.0, 2.0),
            ),
          ],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(25, 15, 0, 0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void saveFavorite() async {
    if (!isFavorite) return;
    // Check if foodItems is empty and return early if so
    if (foodItems.isEmpty) {
      return;
    }

    // Create the meal object
    meal myMeal = meal(
      time: DateTime(_now.year, _now.month, _now.day, _timeOfDay.hour,
          _timeOfDay.minute, 0),
      title: initialTitle1.text.isEmpty ? "Favorite Meal" : initialTitle1.text,
      foodItems: foodItems,
    );

    // If favoriteId is null, it's a new favorite, so add it
    if (favoriteId == null) {
      favoriteId = await user_service.addToFavorite(myMeal);
    } else {
      // Otherwise, update the existing favorite
      user_service.updateFavoriteMeal(
          mealId: favoriteId!,
          newFoodItems: foodItems,
          newTitle: initialTitle1.text);
    }
  }

  void removeFromFavorite() {
    if (favoriteId != null) {
      user_service.removeFromFavorite(favoriteId!);
      favoriteId = null;
    }
  }
}
