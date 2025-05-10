import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_widget_config.dart';
import 'services/auth_service.dart';
import 'splash.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Singleton class to manage app state
class AppState {
  static final AppState _instance = AppState._internal();
  bool isAppInForeground = true;

  factory AppState() {
    return _instance;
  }

  AppState._internal();
}

// this will be used as notification channel id
const notificationChannelId = 'my_background';
const notificationChannelName = 'Background Service';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global variable to hold the service instance
UserService? userService; // Global instance of UserService

// Top-level function to start background service
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(); // Load .env

  // Initialize notifications plugin and create channel
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    notificationChannelName, // title
    description: 'This channel is used for continuous glucose monotoring.',
    importance: Importance.low,
    enableVibration: false,
    playSound: false,
    showBadge: false,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Initialize and configure the background service
  try {
    await initializeService();
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      print('Service not running');
      await service.startService();
    } else {
      print('Service already running');
    }
  } catch (e) {
    print('Error initializing background service: $e');
  }

  // Initialize Firebase first
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();

  // Handle lastWarning
  String? lastWarning = prefs.getString('LastWarning');
  if (lastWarning == null) {
    DateTime twelveHoursAgo = DateTime.now().subtract(Duration(hours: 12));
    await prefs.setString('LastWarning', twelveHoursAgo.toIso8601String());
    print('Set LastWarning to 12 hours ago');
  }

  // Handle showCorrectionBox
  bool? showCorrectionBox = prefs.getBool('showCorrectionBox');
  if (showCorrectionBox == null) {
    await prefs.setBool('showCorrectionBox', true);
    print('Set showCorrectionBox to true (default value)');
  }
}

Future<void> requestNotificationPermission() async {
  final permission = Permission.notification;

  if (await permission.isDenied) {
    PermissionStatus status = await permission.request();

    if (status.isGranted) {
      final service = FlutterBackgroundService();
      print("Notification permission granted");
      service.startService();
    } else {
      print("Notification permission denied");
    }
  } else if (await permission.isGranted) {
    print("Notification permission already granted");
    FlutterBackgroundService().startService();
  } else if (await permission.isPermanentlyDenied) {
    print("Permission permanently denied. Ask user to go to settings.");
    openAppSettings();
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Glucose Reading',
      initialNotificationContent: 'Processing glucose data',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    // Immediately set as foreground service
    print('starting the service');

    service.setAsForegroundService();
  }

  // Initialize Firebase if not already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  bool isAppInForeground = true;

  service.on('updateAppState').listen((event) {
    isAppInForeground = event?['isAppInForeground'] ?? true;

    if (isAppInForeground) {
      // Cancel all notifications when the app is in the foreground
      flutterLocalNotificationsPlugin.cancelAll();
      print("All notifications canceled as the app is now in the foreground.");
    }
  });

  void updateGlucoseReadingBackground(int reading) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    if (service is AndroidServiceInstance) {
      // Update the permenant notification
      service.setForegroundNotificationInfo(
        title: "Glucose Reading",
        content:
            '${reading != -1 ? '${reading.toString()} mg/dL' : 'No reading'}',
      );
    }
  }

  // Initialize the service
  userService = UserService(
    isAppInForeground: () => isAppInForeground,
    updateGlucoseReadingBackground: updateGlucoseReadingBackground,
  );

  updateGlucoseReadingBackground(-1);

  userService!.startPeriodicGlucoseFetch(isBackgroundTask: true);
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      HomeWidgetConfig.initialize();
    });

    requestNotificationPermission();
    loadPreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Update the singleton without calling setState
    bool oldValue = AppState().isAppInForeground;
    AppState().isAppInForeground = state == AppLifecycleState.resumed;
    if (oldValue != AppState().isAppInForeground) {}

    // Send the app state to the background service
    final service = FlutterBackgroundService();
    service.invoke('updateAppState', {
      'isAppInForeground': AppState().isAppInForeground,
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InsulinSync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF023B96), // Seed color
          primary: Color(0xFF023B96), // Primary color
          secondary: Color(0xFFD8E6FD), // Secondary color
          background: Color(0xFFF1F4F8), // Set the app background color
          surface: Colors.white,
          error: Color.fromARGB(255, 194, 43, 98),
        ),
        textTheme: GoogleFonts.robotoTextTheme(),
        scaffoldBackgroundColor:
            Color(0xFFF1F4F8), // Set Scaffold background color
        useMaterial3: true, // Enable Material 3
      ),
      home: FutureBuilder<Widget>(
        future: redirect(context.read<AuthService>()), // Handle async redirect
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return snapshot.data!;
          }
          return Scaffold(
            body: Center(child: Text('Error loading app')),
          );
        },
      ),
    );
  }

  Future<Widget> redirect(AuthService authService) async {
    // Check if the user is logged in
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final service = FlutterBackgroundService();
        if (snapshot.hasData) {
          print('Debug background user is logged in');

          if (userService?.glucoseTimer == null) {
            userService?.startPeriodicGlucoseFetch(isBackgroundTask: true);
          }

          return MainNavigation();
        } else {
          if (userService?.glucoseTimer == null) {
            userService?.startPeriodicGlucoseFetch(isBackgroundTask: true);
          }
          return OnboardingWidget();
        }
      },
    );
  }
}
