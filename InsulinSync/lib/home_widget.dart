import 'package:flutter/material.dart';
import 'home_screen.dart';

class HomeWidget extends StatelessWidget {
  final int glucoseValue;
  final int arrowDirection;
  final Color backgroundColor;

  const HomeWidget({
    Key? key,
    required this.glucoseValue,
    required this.arrowDirection,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        color: backgroundColor,
        padding: EdgeInsets.all(8.0),
        child: (glucoseValue != -1)
            ? Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$glucoseValue',
                    style: TextStyle(
                      fontSize: 35.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        ArrowIconMapper.getIcon(arrowDirection),
                        color: Colors.white,
                        size: 35.0,
                      ),
                      Text(
                        'mg/dL',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 35.0,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
