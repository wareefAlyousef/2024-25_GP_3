import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'history.dart';
import 'Setting.dart';
import 'dashboard.dart'; // Import your Dashboard page

class MainNavigation extends StatefulWidget {
  int index;

  MainNavigation({this.index = 1});
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Default to Home (middle item)

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
  }

  final List<Widget> _pages = [
    History(),
    Home(),
    Dashboard(), // Add Dashboard as the third page
    Setting(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        height: 60,
        index: _currentIndex.clamp(0, 3), // Ensure index stays within bounds
        items: <Widget>[
          Icon(
            FontAwesomeIcons.clockRotateLeft,
            size: 25,
            color: _currentIndex == 0
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          Icon(
            Icons.home,
            size: 30,
            color: _currentIndex == 1
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          Icon(
            FontAwesomeIcons.chartLine,
            size: 27,
            color: _currentIndex == 2
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          Icon(
            Icons.settings,
            size: 30,
            color: _currentIndex == 3
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ],
        backgroundColor: Colors.transparent,
        color: Theme.of(context).cardColor, // Use theme color for the bar
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 300),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
