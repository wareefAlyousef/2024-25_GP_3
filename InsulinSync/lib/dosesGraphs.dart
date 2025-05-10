import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'doseChart.dart';
import 'doseTrendChart.dart';
import 'widgets.dart';
import 'services/user_service.dart';

class DosesGraphs extends StatefulWidget {
  const DosesGraphs({Key? key}) : super(key: key);

  @override
  _DosesGraphsState createState() => _DosesGraphsState();
}

class _DosesGraphsState extends State<DosesGraphs> {
  late DateTime selectedDate;
  late UserService userService;

  late Future<void> minMaxFuture;

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
                                  'Insulin Intake on ${DateFormat('dd/MM').format(selectedDate)}',
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
                                            height: 160, // Adjust as needed
                                            child:
                                                DoseChart(date: selectedDate),
                                          )
                                          // child: SizedBox()

                                          )))),
                        ]),
                      )),
                  SizedBox(height: 10),
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
                                  'Insulin Intake History',
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
                                            child: DoseTrendChart(),
                                          )
                                          // child: SizedBox()

                                          )))),
                        ]),
                      ))
                ],
              ),
            ),
          ),
        )));
  }
}
