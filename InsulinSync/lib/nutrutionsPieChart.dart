import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'services/user_service.dart';

class NutritionPieChart extends StatefulWidget {
  final DateTime date;

  const NutritionPieChart({
    super.key,
    required this.date,
  });

  @override
  State<NutritionPieChart> createState() => _NutritionPieChartState();
}

class _NutritionPieChartState extends State<NutritionPieChart> {
  final UserService userService = UserService();
  bool _isLoading = false;
  Map<String, double> _nutritionData = {
    "totalCarb": 0.0,
    "totalFat": 0.0,
    "totalProtein": 0.0,
  };

  Color carbColor = const Color(0xFF5594FF);
  Color proteinColor = const Color(0xFF0352CF);
  Color fatColor = const Color(0xFF023B95);

  @override
  void initState() {
    super.initState();
    _loadNutritionData();
  }

  @override
  void didUpdateWidget(NutritionPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      _loadNutritionData(); // Reload data when date changes
    }
  }

  Future<void> _loadNutritionData() async {
    setState(() => _isLoading = true);
    final startDate =
        DateTime(widget.date.year, widget.date.month, widget.date.day);
    final endDate = DateTime(
        widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    final data = await userService.getTotalMeal(
      startDate: startDate,
      endDate: endDate,
    );

    print('Nutrition data for ${widget.date}: $data');
    setState(() {
      _nutritionData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pie chart
        SizedBox(
          height: 200,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildChart(),
        ),
        const SizedBox(height: 16),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildChart() {
    final carb = _nutritionData['totalCarb'] ?? 0;
    final fat = _nutritionData['totalFat'] ?? 0;
    final protein = _nutritionData['totalProtein'] ?? 0;
    final total = carb + fat + protein;

    return PieChart(
      PieChartData(
        sections: (total == 0)
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
                  color: carbColor,
                  value: carb,
                  title: '',
                  borderSide: BorderSide.none,
                ),
                PieChartSectionData(
                  color: proteinColor,
                  value: protein,
                  title: '',
                  borderSide: BorderSide.none,
                ),
                PieChartSectionData(
                  color: fatColor,
                  value: fat,
                  title: '',
                  borderSide: BorderSide.none,
                ),
              ],
        sectionsSpace: 0,
        centerSpaceRadius: 30,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(carbColor, 'Carbs', _nutritionData['totalCarb'] ?? 0),
        _buildLegendItem(fatColor, 'Fat', _nutritionData['totalFat'] ?? 0),
        _buildLegendItem(
            proteinColor, 'Protein', _nutritionData['totalProtein'] ?? 0),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
        Text('${value.toStringAsFixed(1)}g'),
      ],
    );
  }
}
