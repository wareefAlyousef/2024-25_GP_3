import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'history.dart';
import 'Setting.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    History(),
    Home(),
    Setting(),
    // Container()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        height: 60,
        index: _currentIndex,
        items: <Widget>[
          Icon(
            FontAwesomeIcons.clockRotateLeft,
            size: 27,
            color: Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.home,
            size: 30,
            color: Theme.of(context).primaryColor,
          ),
          Icon(
            Icons.settings,
            size: 30,
            color: Colors.grey,
          ),
        ],
        backgroundColor: Colors.transparent,
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
