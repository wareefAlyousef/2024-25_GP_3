import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:insulin_sync/MainNavigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:insulin_sync/history.dart';
import 'package:provider/provider.dart';
import 'AddCarb.dart';
import 'AddGlucose.dart';
import 'AddInsulin.dart';
import 'AddNote.dart';
import 'AddPhysicalActivity.dart';
import 'home_screen.dart';
import 'signUp.dart';
import 'services/auth_service.dart';
import 'splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
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
      // Define the home property with the redirect method
      home:
          redirect(context.read<AuthService>()), // Redirect based on auth state
      routes: {
        '/home': (context) => Home(),
        '/add_note': (context) => AddNote(),
        '/add_activity': (context) => AddPhysicalActivity(),
        '/add_glucose': (context) => AddGlucose(),
        '/add_insulin': (context) => AddInsulin(),
        '/add_carb': (context) => AddCarb(),
        '/history': (context) => History(),
      },
    );
  }

  // Redirect user based on authentication state
  Widget redirect(AuthService authService) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return MainNavigation();
        } else {
          return OnboardingWidget();
        }
      },
    );
  }
}
