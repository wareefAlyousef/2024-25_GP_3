import 'package:flutter/material.dart';
import 'services/user_service.dart';

class DoseChart extends StatefulWidget {
  final DateTime date;
  const DoseChart({
    Key? key,
    required this.date,
  }) : super(key: key);

  @override
  State<DoseChart> createState() => _DoseChartState();
}

class _DoseChartState extends State<DoseChart> {
  late DateTime currentDate;
  late UserService userService;
  late Future<Column> syncInsulinDosagesBolus;
  late Future<Column> syncInsulinDosagesBasal;

  @override
  void initState() {
    super.initState();
    currentDate = widget.date;
    userService = UserService();
    _loadData();
  }

  @override
  void didUpdateWidget(DoseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      setState(() {
        currentDate = widget.date;
        _loadData(); // Reload data when date changes
      });
    }
  }

  void _loadData() {
    setState(() {
      syncInsulinDosagesBolus = insulinDosages('Bolus');
      syncInsulinDosagesBasal = insulinDosages('Basal');
    });
  }

  Future<Column> insulinDosages(String type) async {
    double? userBasal;
    double? userBolus;

    try {
      userBasal = await userService.getUserAttribute('dailyBasal');
      userBolus = await userService.getUserAttribute('dailyBolus');
    } catch (e) {
      debugPrint('Error fetching user attributes: $e');
    }

    final totalDosage = await userService.getTotalDosages(type, currentDate);

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: AlignmentDirectional(-1.0, -1.0),
          child: Text(
            type.toLowerCase() == 'bolus'
                ? 'Short Acting Dose'
                : 'Long Acting Dose',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0, fontWeight: FontWeight.w300, fontSize: 15),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
          child: Container(
            width: 145.0,
            height: 67.0,
            child: Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 25.0),
                child: Builder(builder: (context) {
                  double value = 0;
                  if (type == 'Bolus' && userBolus != null && userBolus != 0) {
                    value = totalDosage / userBolus;
                  } else if (userBasal != null && userBasal != 0) {
                    value = totalDosage / userBasal;
                  }

                  final color = value > 1
                      ? Theme.of(context).colorScheme.error
                      : value == 1
                          ? const Color(0xff66B266)
                          : Theme.of(context).primaryColor;

                  return Column(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${totalDosage.toStringAsFixed(1)}/${type == 'Bolus' ? userBolus?.toStringAsFixed(1) ?? '-' : userBasal?.toStringAsFixed(1) ?? '-'} Units',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => _showInfo(
                                  context,
                                  "Limit of ${type == 'Bolus' ? 'Short Acting' : 'Long Acting'} dosage",
                                  Text(type == 'Bolus'
                                      ? 'You have taken ${totalDosage.toStringAsFixed(1)} out of your daily dosage of ${userBolus?.toStringAsFixed(1) ?? '?'} units of bolus insulin today, which quickly manages blood sugar spikes after meals.'
                                      : 'You have taken ${totalDosage.toStringAsFixed(1)} out of your daily dosage of ${userBasal?.toStringAsFixed(1) ?? '?'} units of basal insulin today, which helps maintain stable blood sugar levels.')),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color.fromRGBO(96, 106, 133, 1),
                                size: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.grey[200],
                          color: color,
                          minHeight: 5,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String title, Widget body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        content: body,
        actions: [
          Center(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xff023b96),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(100, 44),
              ),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FutureBuilder<Column>(
                  future: syncInsulinDosagesBolus,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    return snapshot.data ?? const Text('-');
                  },
                ),
                FutureBuilder<Column>(
                  future: syncInsulinDosagesBasal,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    return snapshot.data ?? const Text('-');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
