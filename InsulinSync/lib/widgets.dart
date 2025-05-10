import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'excercise.dart';
import 'models/carbohydrate_model.dart';
import 'models/glucose_model.dart';
import 'models/insulin_model.dart';
import 'models/note_model.dart';
import 'models/meal_model.dart';
import 'models/workout_model.dart';
import 'services/user_service.dart';
import 'main.dart';
import 'editNote.dart';
import 'editInsulin.dart';
import 'editGlucose.dart';
import 'editPhysicalActivity.dart';
import 'edittNutritions.dart';
import 'Cart.dart';
import 'models/foodItem_model.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final String? autofillHint;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final bool? readOnly;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    this.focusNode,
    this.obscureText = false,
    this.autofillHint,
    this.textInputAction,
    this.prefixIcon,
    this.validator,
    this.readOnly = false,
  }) : super(key: key);

  @override
  _CustomTextFormFieldState createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: widget.readOnly ?? false,
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: false,
      autofillHints:
          widget.autofillHint != null ? [widget.autofillHint!] : null,
      textCapitalization: TextCapitalization.words,
      textInputAction: widget.textInputAction,
      obscureText: _isObscured,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF023B95),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF023B95),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: widget.readOnly == false || widget.readOnly == null
            ? Color(0xFFFFFFFF) // White color when readOnly is true or null
            : Colors.grey[200],
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_off_outlined
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
      ),
      style: TextStyle(
        fontSize: 18,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w500,
        height: 1,
      ),
      minLines: 1,
      cursorColor: Theme.of(context).colorScheme.primary,
      validator: widget.validator,
    );
  }
}

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 24, 0, 0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          minimumSize: const Size(double.infinity, 50),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 19.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

class MyBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios,
        color: Color.fromARGB(255, 0, 0, 0),
        size: 30,
      ),
      onPressed: () {
        // Pop the current route and return to the previous page
        Navigator.pop(context);
      },
      padding: EdgeInsets.all(8),
      constraints: BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
    );
  }
}

class ExpandableItem extends StatefulWidget {
  final String title;
  final String time;
  final DateTime date;
  final Map<String, dynamic> otherAttributes;
  final String dataType;
  final String? id;

  const ExpandableItem({
    required this.title,
    required this.time,
    required this.otherAttributes,
    this.id,
    Key? key,
    required this.dataType,
    required this.date,
  }) : super(key: key);

  @override
  _ExpandableItemState createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<ExpandableItem> {
  bool _isExpanded = false;

  IconData _getIconForDataType(String dataType) {
    switch (dataType) {
      case 'Note':
        return Icons.note;
      case 'Workout':
        return Icons.fitness_center;
      case 'InsulinDosage':
        return FontAwesomeIcons.syringe;
      case 'GlucoseReading':
        return Icons.bloodtype;
      case 'Carbohydrate':
        return Icons.fastfood;
      case 'meal':
        return Icons.fastfood;
      default:
        return Icons.help;
    }
  }

  Widget build(BuildContext context) {
    return Card(
      color: Color(0xffF5F5F5),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            title: Row(
              children: [
                // widget.dataType == 'meal'
                //? ColorFiltered(
                //colorFilter: ColorFilter.mode(
                //Theme.of(context).colorScheme.primary,
                //BlendMode.srcIn,
                //),
                //child: Image.asset('images/salad.png', height: 24),
                //)
                Icon(
                  _getIconForDataType(widget.dataType),
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  widget.time,
                  style: TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (_isExpanded) _buildExpandedView(),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.otherAttributes.entries
              .where((entry) =>
                  entry.value != null &&
                  entry.value.toString().isNotEmpty &&
                  !['totalCarb', 'totalProtein', 'totalFat', 'totalCalorie']
                      .contains(entry.key))
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: (entry.key != 'id')
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.key != 'comment')
                              Text(
                                entry.key == 'foodItems'
                                    ? 'Added Ingredients'
                                    : '${capitalizeFirstLetter(entry.key)} ',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                getTextForEntry(entry),
                                textAlign: entry.key == 'comment'
                                    ? TextAlign.left
                                    : TextAlign.right,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(),
                ),
              )
              .toList(),
          if (widget.dataType == 'meal') ...[
            Divider(),
            // Show nutritional totals for meals
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Carbs'),
                    Text(
                        '${widget.otherAttributes['totalCarb']?.toStringAsFixed(1)} g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Protein'),
                    Text(
                        '${widget.otherAttributes['totalProtein']?.toStringAsFixed(1)} g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Fat'),
                    Text(
                        '${widget.otherAttributes['totalFat']?.toStringAsFixed(1)} g'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Calories'),
                    Text(
                        '${widget.otherAttributes['totalCalorie']?.toStringAsFixed(1)} kcal'),
                  ],
                ),
              ],
            ),
          ],
          SizedBox(height: 10),
          if (widget.otherAttributes["source"] != "Health Connect")
            if (widget.date.year == DateTime.now().year &&
                widget.date.month == DateTime.now().month &&
                widget.date.day == DateTime.now().day)
              Column(children: [
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 3),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () async {
                        print("delete");

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
                                        backgroundColor:
                                            Color.fromARGB(41, 248, 77, 117),
                                        child: Icon(
                                          Icons.delete_outline,
                                          size: 80,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
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

                                      // Buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          // Cancel button
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                side: BorderSide(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .error),
                                                backgroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                minimumSize: Size(120, 44),
                                              ),
                                              child: Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                  backgroundColor: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          //confirm
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                print("confirm");

                                                UserService userService =
                                                    UserService();
                                                switch (widget.dataType) {
                                                  case 'Note':
                                                    print("note");

                                                    print(widget.id);

                                                    if (widget.id != null) {
                                                      String id = widget.id!;
                                                      userService
                                                          .deleteNote(id);
                                                    }

                                                  case 'GlucoseReading':
                                                    print("delte glucose");
                                                    print("id");
                                                    print(widget.id);

                                                    if (widget.id != null) {
                                                      String id = widget.id!;
                                                      print(userService
                                                          .deleteGlucoseReading(
                                                              id));
                                                      print("fin");
                                                      print(id);
                                                    }
                                                    break;

                                                  case 'meal':
                                                    print("meal");

                                                    if (widget.id != null) {
                                                      print("id found");
                                                      print(widget.id);
                                                      String id = widget.id!;
                                                      print(userService
                                                          .deleteMeal(id));
                                                      print("fin");
                                                    }

                                                    break;

                                                  case 'InsulinDosage':
                                                    print("InsulinDosage");

                                                    if (widget.id != null) {
                                                      String id = widget.id!;
                                                      userService
                                                          .deleteInsulinDosage(
                                                              id);
                                                    }

                                                    break;

                                                  case 'Workout':
                                                    if (widget.id != null) {
                                                      String id = widget.id!;
                                                      userService
                                                          .deleteWorkout(id);
                                                    }

                                                    break;

                                                  default:
                                                    print(
                                                        'No delete action defined for this entry type.');
                                                }
                                                Navigator.pushAndRemoveUntil(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          MainNavigation()),
                                                  (Route<dynamic> route) =>
                                                      false,
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                side: BorderSide(
                                                    color: Color(0xFF023B96)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                minimumSize: Size(120, 44),
                                              ),
                                              child: Text(
                                                'Confirm',
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
                      },
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        print("edit");

                        switch (widget.dataType) {
                          case 'GlucoseReading':
                            print("glucose");

                            if (widget.id != null) {
                              String glucoseid = widget.id!;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => editGlucose(
                                    time: widget.date,
                                    title: widget.title,
                                    id: glucoseid,
                                    glucoseReading:
                                        widget.otherAttributes["reading"],
                                  ),
                                ),
                              );
                            }

                            break;

                          case 'Note':
                            print("note");

                            print(widget.time);

                            if (widget.id != null) {
                              String noteid = widget.id!;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => editNote(
                                    time: widget.date,
                                    title: widget.title,
                                    comment: widget.otherAttributes["comment"],
                                    id: noteid,
                                  ),
                                ),
                              );
                            }

                          case 'meal':
                            print("meal");
                            print(widget.otherAttributes);
                            if (widget.otherAttributes["foodItems"][0]
                                    ['portion'] ==
                                -1) {
                              print("CARB");
                              if (widget.id != null) {
                                String mealid = widget.id!;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => edittNutrition2(
                                        time: widget.date,
                                        title: widget.title,
                                        id: mealid,
                                        carb:
                                            widget.otherAttributes["foodItems"]
                                                [0]['carb'],
                                        protein:
                                            widget.otherAttributes["foodItems"]
                                                [0]['protein'],
                                        fat: widget.otherAttributes["foodItems"]
                                            [0]['fat'],
                                        calorie:
                                            widget.otherAttributes["foodItems"]
                                                [0]['calorie']),
                                  ),
                                );
                              }
//add
                            } else {
                              print("real meal");
                              if (widget.id != null) {
                                String mealid = widget.id!;

                                List<foodItem>? foodItems =
                                    (widget.otherAttributes["foodItems"]
                                            as List<Map<String, dynamic>>?)
                                        ?.map((item) {
                                  return foodItem(
                                    name: item['name'] as String,
                                    portion:
                                        (item['portion'] as num).toDouble(),
                                    protein:
                                        (item['protein'] as num).toDouble(),
                                    fat: (item['fat'] as num).toDouble(),
                                    carb: (item['carb'] as num).toDouble(),
                                    calorie:
                                        (item['calorie'] as num).toDouble(),
                                    source: item['source'] as String,
                                    imageUrl: item['imageUrl'] as String?,
                                  );
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Cart(
                                      foodItems: foodItems,
                                      time: widget.date,
                                      title: widget.title,
                                      id: mealid,
                                    ),
                                  ),
                                );
                              }
                            }
                            break;

                          case 'InsulinDosage':
                            print(widget.otherAttributes);

                            if (widget.id != null) {
                              String dosageid = widget.id!;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => editInsulin(
                                    type: widget.otherAttributes["type"],
                                    dosage: widget.otherAttributes["dosage"],
                                    time: widget.date,
                                    title: widget.title,
                                    id: dosageid,
                                  ),
                                ),
                              );
                            }

                            break;

                          case 'Workout':
                            print("workout");
                            print(widget.otherAttributes);
                            if (widget.id != null) {
                              String glucoseid = widget.id!;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => editPhysicalActivity(
                                    time: widget.date,
                                    title: widget.title,
                                    id: glucoseid,
                                    duration:
                                        widget.otherAttributes["duration"],
                                    type: widget.otherAttributes["intensity"],
                                  ),
                                ),
                              );
                            }

                            break;

                          default:
                            print(
                                'No delete action defined for this entry type.');
                        }
                      },
                    ),
                  ],
                ),
              ])
        ],
      ),
    );
  }
}

String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String getTextForEntry(MapEntry<String, dynamic> entry) {
  String result;

  switch (entry.key) {
    case 'duration':
      int minutes = entry.value;
      result = '${minutes} Minutes';
      break;

    case 'dosage':
      result = '${entry.value} Units';
      break;

    case 'reading':
      result = '${entry.value} mg/dL';
      break;

    case 'amount':
      result = '${entry.value} g';
      break;

    case 'type':
      if (entry.value == 'Bolus') {
        result = 'Short Acting';
      } else {
        result = 'Long Acting';
      }
      break;

    case 'totalCarb':
      result = '${entry.value.toStringAsFixed(1)} g';
      break;

    case 'totalProtein':
      result = '${entry.value.toStringAsFixed(1)} g';
      break;

    case 'totalFat':
      result = '${entry.value.toStringAsFixed(1)} g';
      break;

    case 'totalCalorie':
      result = '${entry.value.toStringAsFixed(1)} kcal';
      break;

    case 'foodItems': // Add handling for food items
      if (entry.value is List) {
        var foodItems = entry.value as List;

        // If there's only one item with portion -1, return empty string
        if (foodItems.length == 1 && foodItems[0]['portion'] == -1) {
          result = '-';
          break;
        }

        // Filter out items with portion -1 and create the string
        var validItems = foodItems
            .where((item) => item['portion'] != -1)
            .map((item) => '${item['name']} (${item['portion']}g)')
            .join('\n');

        result = validItems.isEmpty ? '-' : validItems;
      } else {
        result = '';
      }
      break;

    default:
      result = entry.value.toString();
  }

  return capitalizeFirstLetter(result);
}

class DateEntryWidget extends StatefulWidget {
  final String date;
  final List<dynamic> entries;
  final bool isHome;
  final bool isSelected;

  const DateEntryWidget({
    required this.date,
    required this.entries,
    this.isHome = false,
    Key? key,
    required this.isSelected,
  }) : super(key: key);

  @override
  _DateEntryWidgetState createState() => _DateEntryWidgetState();
}

class _DateEntryWidgetState extends State<DateEntryWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = (widget.isHome || widget.isSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 13.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.isHome ? "Logbook" : widget.date,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            letterSpacing: 0,
                            fontSize: 20,
                          ),
                    ),
                    if (widget.isHome)
                      Container(
                        height: 50,
                      ),
                    if (!widget.isHome)
                      IconButton(
                        icon: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                  ],
                ),
              ),
              if (_isExpanded)
                ...widget.entries.map((entry) {
                  return ExpandableItem(
                    dataType: '${entry.runtimeType}',
                    id: entry.id ?? 'No ID',
                    date: entry.time,
                    title: entry.title ?? 'No Title',
                    time: DateFormat('HH:mm').format(
                      entry.time is Timestamp
                          ? (entry.time as Timestamp).toDate()
                          : entry.time,
                    ),
                    otherAttributes: Map<String, dynamic>.from(entry.toMap())
                      ..remove('title')
                      ..remove('time'),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

class LogbookWidget extends StatefulWidget {
  final DateTime? specificDate;
  final bool isHome;

  const LogbookWidget({
    this.specificDate,
    this.isHome = false,
    Key? key,
  }) : super(key: key);

  @override
  _LogbookWidgetState createState() => _LogbookWidgetState();
}

class _LogbookWidgetState extends State<LogbookWidget> {
  UserService userService = UserService();

  Future<List<Workout>> fetchWorkouts() async {
    try {
      var startTime = DateTime.now().subtract(const Duration(days: 500));
      var endTime = DateTime.now();
      var val = await HealthConnectFactory.getRecord(
        startTime: startTime,
        endTime: endTime,
        type: HealthConnectDataType.ExerciseSession,
      ) as Map<String, dynamic>;

      List<Workout> workouts = [];

      if (val.containsKey('records') && val['records'] is List) {
        var records = val['records'] as List;

        for (var record in records) {
          DateTime start = DateTime.fromMillisecondsSinceEpoch(
            record['startTime']['epochSecond'] * 1000,
          );
          DateTime end = DateTime.fromMillisecondsSinceEpoch(
            record['endTime']['epochSecond'] * 1000,
          );

          double durationInSeconds = end.difference(start).inSeconds.toDouble();
          double durationInMinutes = durationInSeconds / 60;
          int ceilingMinutes = durationInMinutes.ceil();

          int type = record['exerciseType'];
          String title = ExerciseConstants.getExerciseTypeString(type);

          workouts.add(
            Workout(
              title: title,
              time: start,
              intensity: null,
              duration: ceilingMinutes,
              source: "Health Connect",
            ),
          );
        }
      }

      return workouts;
    } catch (e) {
      return [];
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  List<dynamic> filterEntriesForSpecificDate(List<dynamic> entries) {
    if (widget.specificDate != null) {
      DateTime targetDate = widget.specificDate!;

      return entries.where((entry) {
        DateTime entryDate = entry.time;
        return isSameDay(entryDate, targetDate);
      }).toList();
    }

    return entries;
  }

  Map<String, List<dynamic>> separateEntriesByDate(List<dynamic> entries) {
    Map<String, List<dynamic>> entriesByDate = {};

    for (var entry in entries) {
      DateTime entryDate;
      if (entry.time is Timestamp) {
        entryDate = (entry.time as Timestamp).toDate();
      } else if (entry.time is DateTime) {
        entryDate = entry.time;
      } else {
        continue;
      }

      String dateKey = DateFormat('dd-MM-yyyy').format(entryDate);

      if (!entriesByDate.containsKey(dateKey)) {
        entriesByDate[dateKey] = [];
      }
      entriesByDate[dateKey]!.add(entry);
    }

    return entriesByDate;
  }

  List<Widget> buildDateEntries(Map<String, List<dynamic>> entriesByDate) {
    bool isSelected = false;
    if (widget.specificDate != null) {
      isSelected = true;
    }
    return entriesByDate.entries.map((entry) {
      return DateEntryWidget(
        isSelected: isSelected,
        date: entry.key,
        entries: entry.value,
        isHome: widget.isHome,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Note>>(
      future: userService.getNotes(),
      builder: (context, noteSnapshot) {
        return FutureBuilder<List<InsulinDosage>>(
          future: userService.getInsulinDosages(),
          builder: (context, insulinSnapshot) {
            return FutureBuilder<List<Workout>>(
              future: userService.getWorkouts(),
              builder: (context, workoutSnapshot) {
                return FutureBuilder<List<Carbohydrate>>(
                  future: userService.getCarbohydrates(),
                  builder: (context, carbSnapshot) {
                    return FutureBuilder<List<GlucoseReading>>(
                      future: userService.getGlucoseReadings(source: 'manual'),
                      builder: (context, glucoseSnapshot) {
                        return FutureBuilder<List<Workout>>(
                          future: fetchWorkouts(),
                          builder: (context, workoutSnapshotHealth) {
                            return FutureBuilder<List<meal>>(
                              future: userService.getMeal(),
                              builder: (context, mealSnapshot) {
                                if (noteSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    insulinSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    workoutSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    workoutSnapshotHealth.connectionState ==
                                        ConnectionState.waiting ||
                                    carbSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    glucoseSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    mealSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }

                                if (noteSnapshot.hasError ||
                                    insulinSnapshot.hasError ||
                                    workoutSnapshot.hasError ||
                                    carbSnapshot.hasError ||
                                    glucoseSnapshot.hasError ||
                                    mealSnapshot.hasError) {
                                  // Added meal error check
                                  return Center(
                                      child: Text('Error loading data'));
                                }

                                final notes = noteSnapshot.data ?? [];
                                final insulinDosages =
                                    insulinSnapshot.data ?? [];
                                final workouts = workoutSnapshot.data ?? [];
                                final workoutsHealth =
                                    workoutSnapshotHealth.data ?? [];
                                final carbohydrates = carbSnapshot.data ?? [];
                                final glucoseReadings =
                                    glucoseSnapshot.data ?? [];
                                final meals = mealSnapshot.data ?? [];

                                List<dynamic> combinedEntries = [
                                  ...notes,
                                  ...insulinDosages,
                                  ...workouts,
                                  ...workoutsHealth,
                                  ...carbohydrates,
                                  ...glucoseReadings,
                                  ...meals,
                                ];

                                for (var r in glucoseReadings) {
                                  print("@%#@#%%% ${r.id}");
                                }

                                combinedEntries = filterEntriesForSpecificDate(
                                    combinedEntries);
                                combinedEntries
                                    .sort((a, b) => b.time.compareTo(a.time));

                                if (combinedEntries.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.all(16.0),
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            4.0, 4.0, 4.0, 13.0),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (widget.isHome)
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(16.0, 12.0, 0.0,
                                                          19.0),
                                                  child: Text(
                                                    'Logbook',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          letterSpacing: 0,
                                                          fontSize: 20,
                                                        ),
                                                  ),
                                                ),
                                              Center(
                                                child: Text(
                                                  widget.isHome
                                                      ? 'Nothing Today'
                                                      : 'No data for the selected date',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                Map<String, List<dynamic>> entriesByDate =
                                    separateEntriesByDate(combinedEntries);

                                return Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    children: buildDateEntries(entriesByDate),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class SelectedDateWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onDateSelected;
  final VoidCallback? onClearDate;
  // final bool allowsClear;

  const SelectedDateWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    this.onClearDate,
    // required this.allowsClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onDateSelected,
          child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              height: 50.0,
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    selectedDate == null
                        ? 'No date selected'
                        : DateFormat('dd-MM-yyyy').format(selectedDate!),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      if (selectedDate != null)
                        if (onClearDate != null)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 20,
                            ),
                            onPressed: onClearDate,
                          ),
                      Icon(
                        Icons.arrow_drop_down,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
