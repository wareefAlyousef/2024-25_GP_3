import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'widgets.dart';
import '../services/auth_service.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  DateTime? selectedDate;

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

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      backgroundColor: Color(0xFFf1f4f8),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshData();
        },
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
                      width: 357.0,
                      height: 50.0,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'History',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                    letterSpacing: 0,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: SelectedDateWidget(
                      selectedDate: selectedDate,
                      onDateSelected: _selectDate,
                      onClearDate: () {
                        setState(() {
                          selectedDate = null;
                        });
                      },
                    ),
                  ),
                  LogbookWidget(
                    specificDate: selectedDate,
                  ),
                  SizedBox(height: 60)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
