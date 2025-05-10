import 'package:flutter/cupertino.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetConfig {
  static Future<void> update(Widget widget) async {
    // Render new widget
    print('Rendering new widget...');
    final result = await HomeWidget.renderFlutterWidget(
      widget,
      key: 'filename', // Unique key
      pixelRatio: 2, // Reduced from 4 for better performance
      logicalSize: const Size(170, 170),
    );

    // Update the widget
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'com.example.insulin_sync.CustomHomeView',
    );
  }

  static Future<void> initialize() async {}
}
