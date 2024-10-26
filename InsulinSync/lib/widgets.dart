import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'excercise.dart';
import 'models/carbohydrate_model.dart';
import 'models/glucose_model.dart';
import 'models/insulin_model.dart';
import 'models/note_model.dart';
import 'models/workout_model.dart';
import 'services/user_service.dart';
import 'main.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final String? autofillHint;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
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
        fillColor: Color(0xFFFFFFFF),
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
        fontSize: 16,
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
                letterSpacing: 0.0,
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
  final Map<String, dynamic> otherAttributes;
  final String dataType;

  const ExpandableItem({
    required this.title,
    required this.time,
    required this.otherAttributes,
    Key? key,
    required this.dataType,
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
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.otherAttributes.entries
            .where((entry) =>
                entry.value != null && entry.value.toString().isNotEmpty)
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.key != 'comment')
                      Text(
                        '${capitalizeFirstLetter(entry.key)} ',
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
                ),
              ),
            )
            .toList(),
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
                      future: userService.getGlucoseReadings(),
                      builder: (context, glucoseSnapshot) {
                        return FutureBuilder<List<Workout>>(
                          future: fetchWorkouts(),
                          builder: (context, workoutSnapshotHealth) {
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
                                    ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (noteSnapshot.hasError ||
                                insulinSnapshot.hasError ||
                                workoutSnapshot.hasError ||
                                carbSnapshot.hasError ||
                                glucoseSnapshot.hasError) {
                              return Center(child: Text('Error loading data'));
                            }

                            final notes = noteSnapshot.data ?? [];
                            final insulinDosages = insulinSnapshot.data ?? [];
                            final workouts = workoutSnapshot.data ?? [];
                            final workoutsHealth =
                                workoutSnapshotHealth.data ?? [];
                            final carbohydrates = carbSnapshot.data ?? [];
                            final glucoseReadings = glucoseSnapshot.data ?? [];

                            List<dynamic> combinedEntries = [
                              ...notes,
                              ...insulinDosages,
                              ...workouts,
                              ...workoutsHealth,
                              ...carbohydrates,
                              ...glucoseReadings,
                            ];

                            combinedEntries =
                                filterEntriesForSpecificDate(combinedEntries);

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
                                        offset: Offset(
                                          0.0,
                                          2.0,
                                        ),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(8.0),
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
                                                  .fromSTEB(
                                                      16.0, 12.0, 0.0, 19.0),
                                              child: Text(
                                                'Logbook',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                        letterSpacing: 0,
                                                        fontSize: 20),
                                              ),
                                            ),
                                          Center(
                                              child: Text(
                                            widget.isHome
                                                ? 'Nothing Today'
                                                : 'No data for the selected date',
                                          ))
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
  }
}

class SelectedDateWidget extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onDateSelected;
  final VoidCallback onClearDate;

  const SelectedDateWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onClearDate,
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
