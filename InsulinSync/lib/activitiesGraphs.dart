import 'package:flutter/material.dart';
import 'caloriesLineChart .dart';
import 'services/user_service.dart';
import 'stepsBarchart.dart';

class ActivitiesGraphs extends StatefulWidget {
  const ActivitiesGraphs({Key? key}) : super(key: key);

  @override
  _ActivitiesGraphsState createState() => _ActivitiesGraphsState();
}

class _ActivitiesGraphsState extends State<ActivitiesGraphs> {
  late DateTime selectedDate;
  late UserService userService;

  @override
  void initState() {
    super.initState();
    userService = UserService();
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
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
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
                                alignment: Alignment
                                    .centerLeft, // Force left alignment
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      5, 0, 0.0, 0),
                                  child: Text(
                                    'Steps History',
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
                                    // width: 366.0,
                                    // height: 700.0,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                    child: Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Padding(
                                            padding: EdgeInsets.all(0),
                                            child: SizedBox(
                                              height: 400, // Adjust as needed
                                              child: StepsBarchart(),
                                            )
                                            // child: SizedBox()

                                            )))),
                          ]),
                        )),
                    SizedBox(height: 15),
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
                              offset: Offset(0.0, 2.0),
                            )
                          ],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
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
                                    'Burned Calories History',
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
                                    child: const Align(
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: const Padding(
                                            padding: EdgeInsets.all(0),
                                            child: const SizedBox(
                                              height: 400, // Adjust as needed
                                              child: const CaloriesLineChart(),
                                            ))))),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )),
        ));
  }
}
