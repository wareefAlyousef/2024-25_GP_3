import 'package:flutter/material.dart';
import 'package:insulin_sync/activitiesGraphs.dart';
import 'package:insulin_sync/dosesGraphs.dart';

import 'glucoseGraphs.dart';
import 'nutritionsGraphs.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  // static String routeName = 'dashbordCopy';
  // static String routePath = '/dashbordCopy';

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F8),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(7.0, 7.0, 7.0, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (matches Settings page exactly)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: 357.0,
                      height: 50.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Statistics',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  letterSpacing: 0,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildCard('Glucose Levels', 'images/vis_glucose.png',
                          const GlucoseGraphs()),
                      const SizedBox(height: 16),
                      _buildCard('Insulin Dosages', 'images/vis_ins.png',
                          const DosesGraphs()),
                      const SizedBox(height: 16),
                      _buildCard('Food Intake', 'images/vis_food.png',
                          const NutritionsGraphs()),
                      const SizedBox(height: 16),
                      _buildCard('Physical Activities',
                          'images/vis_physical.png', const ActivitiesGraphs()),
                      const SizedBox(height: 16),
                      // _buildCard('Steps', 'images/vis_steps.png'),
                      // const SizedBox(height: 44),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String imagePath, Widget page) {
    // wrap the container in a clickable widget
    return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Ensures content stretches
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 16.0), // Only left padding for text
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8), // Match container's right side
                  bottomRight: Radius.circular(8),
                ),
                child: Image.asset(
                  imagePath,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover, // Changed to cover for edge-to-edge
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey,
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
