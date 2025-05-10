import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'AGPChart.dart';
import 'glucoseChart.dart';
import 'timeInRange.dart';
import 'widgets.dart';
import 'services/user_service.dart';

class GlucoseGraphs extends StatefulWidget {
  const GlucoseGraphs({Key? key}) : super(key: key);

  @override
  _GlucoseGraphsState createState() => _GlucoseGraphsState();
}

class _GlucoseGraphsState extends State<GlucoseGraphs> {
  final GlobalKey _menuKey = GlobalKey();

  late DateTime selectedDate;
  late UserService userService;

  late Future<void> minMaxFuture;

  int selectedDays = 90;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    userService = UserService();
  }

  Future<bool> getIsCgmConnectedFuture() {
    return userService.isCgmConnected(); // Always create a new Future
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        print("debug glucose graphs: selected date: $picked");
        selectedDate = picked;
      });
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
            child: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(7.0, 7.0, 7.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: SelectedDateWidget(
                      selectedDate: selectedDate,
                      onDateSelected: _selectDate,
                    ),
                  ),
                  // SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Color(0x33000000),
                            offset: Offset(
                              0.0,
                              2.0,
                            ),
                          )
                        ],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.max, children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 16.0),
                              child: Align(
                                alignment: Alignment
                                    .centerLeft, // Force left alignment
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      5, 0, 0.0, 0),
                                  child: Text(
                                    'Glucose Levels on ${DateFormat('dd/MM').format(selectedDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                                padding: EdgeInsets.all(0),
                                child:
                                    GlucoseChart(specificDate: selectedDate)),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 16.0),
                              child: Align(
                                alignment: Alignment
                                    .centerLeft, // Force left alignment
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      5, 0, 0.0, 0),
                                  child: Text(
                                    'Time-in-Range',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            TimeInRange(date: selectedDate),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final RenderBox buttonRenderBox =
                              _menuKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          final RenderBox overlay = Overlay.of(context)
                              .context
                              .findRenderObject() as RenderBox;

                          final Offset buttonPosition = buttonRenderBox
                              .localToGlobal(Offset.zero, ancestor: overlay);
                          final Size buttonSize = buttonRenderBox.size;

                          final RelativeRect position = RelativeRect.fromLTRB(
                            buttonPosition.dx,
                            buttonPosition.dy + buttonSize.height,
                            overlay.size.width -
                                (buttonPosition.dx + buttonSize.width),
                            overlay.size.height -
                                (buttonPosition.dy + buttonSize.height),
                          );

                          // Open a simple list of options for selecting days
                          showMenu(
                            context: context,
                            position: position,
                            items: [
                              PopupMenuItem<int>(
                                value: 7,
                                child: Text('7 days'),
                              ),
                              PopupMenuItem<int>(
                                value: 14,
                                child: Text('14 days'),
                              ),
                              PopupMenuItem<int>(
                                value: 30,
                                child: Text('30 days'),
                              ),
                              PopupMenuItem<int>(
                                value: 90,
                                child: Text('90 days'),
                              ),
                            ],
                          ).then((value) {
                            if (value != null) {
                              setState(() {
                                selectedDays = value; // Update selected days
                              });
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 7.0),
                          child: Container(
                            key: _menuKey,
                            height: 50.0,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 0.0),
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
                                  '$selectedDays days', // Display selected days
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
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
                  ),
                  Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 4.0,
                              color: Color(0x33000000),
                              offset: Offset(
                                0.0,
                                2.0,
                              ),
                            )
                          ],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child:
                            Column(mainAxisSize: MainAxisSize.max, children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 16.0),
                            child: Align(
                              alignment:
                                  Alignment.centerLeft, // Force left alignment
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    5, 0, 0.0, 0),
                                child: Text(
                                  'Daily Patterns',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        letterSpacing: 0,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 16.0, 16.0),
                              child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                  child: Align(
                                      alignment: AlignmentDirectional(0.0, 0.0),
                                      child: Padding(
                                          padding: EdgeInsets.all(0),
                                          child: SizedBox(
                                            height: 400, // Adjust as needed
                                            child: GlucoseAGPScreen(
                                                selectedDays: selectedDays),
                                          ))))),
                        ]),
                      )),
                ],
              ),
            ),
          ),
        )));
  }
}
