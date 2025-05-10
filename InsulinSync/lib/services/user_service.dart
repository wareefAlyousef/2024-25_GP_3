import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as firebase_database;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_permissions/notification_permissions.dart';
import '../home_widget.dart';
import '../home_widget_config.dart';
import '../models/carbohydrate_model.dart';
import '../models/contact_model.dart';
import '../models/user_model.dart';
import '../models/glucose_model.dart';
import '../models/insulin_model.dart';
import '../models/note_model.dart';
import '../models/workout_model.dart';
import "../models/meal_model.dart";
import "../models/foodItem_model.dart";
import 'package:http/http.dart' as http;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String? currentUserId;

  StreamController<double>? _glucoseStreamController;
  StreamController<int>? _arrowStreamController;
  Timer? glucoseTimer;

  Stream<double> get glucoseStream =>
      _glucoseStreamController!.stream.asBroadcastStream();
  Stream<int> get arrowStream =>
      _arrowStreamController!.stream.asBroadcastStream();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final bool Function()? isAppInForeground; // Callback to check app state
  final void Function(int reading)? updateGlucoseReadingBackground;

  UserService({this.isAppInForeground, this.updateGlucoseReadingBackground}) {
    currentUserId = _auth.currentUser?.uid;
    _glucoseStreamController = StreamController<double>();
    _arrowStreamController = StreamController<int>();
  }

  Future<void> createUser(UserModel user) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).set(user.toMap());
  }

  void clearUser() {
    currentUserId = null;
    glucoseTimer?.cancel();
    glucoseTimer = null;
    _glucoseStreamController?.close();
    _glucoseStreamController = null;
    _arrowStreamController?.close();
    _arrowStreamController = null;
  }

  Stream<UserModel> getUser() {
    if (currentUserId == null) throw Exception("User not authenticated");
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  Stream<DocumentSnapshot> getUserStream() {
    if (currentUserId != null) {
      return _firestore.collection('users').doc(currentUserId).snapshots();
    }
    throw Exception("User not logged in");
  }

  Future<bool> addGlucoseReading(GlucoseReading reading) async {
    if (currentUserId == null) return false;
    try {
      await _database
          .child('users/$currentUserId/glucose_readings')
          .push()
          .set(reading.toMap());
      return true; // Return true if the operation was successful
    } catch (e) {
      // Handle the error if needed (e.g., logging)
      print('Error adding glucose reading: $e');
      return false; // Return false if there was an error
    }
  }

//////////////////////

  Future<List<GlucoseReading>> getGlucoseReadings({String? source}) async {
    if (currentUserId == null) {
      return [];
    }

    try {
      // Create the database reference
      firebase_database.Query query =
          _database.child('users/$currentUserId/glucose_readings');

      // Apply the filter if a source is provided
      if (source != null) {
        query = query.orderByChild('source').equalTo(source);
      }

      // Enable syncing for the reference
      query.keepSynced(true);

      // Fetch the data
      final firebase_database.DatabaseEvent event = await query.once();
      final firebase_database.DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final readingsList = snapshot.children.map((childSnapshot) {
          // Convert the dynamic map to Map<String, dynamic>
          final readingData = Map<String, dynamic>.from(
              childSnapshot.value as Map<dynamic, dynamic>);
          // Add the ID (key) to the data
          readingData['id'] = childSnapshot.key;
          return GlucoseReading.fromMap(readingData);
        }).toList();

        return readingsList;
      } else {
        return [];
      }
    } catch (e, stack) {
      print('Error fetching glucose readings: $e   $stack');
      return [];
    }
  }

  Future<bool> deleteGlucoseReading(String readingId) async {
    if (currentUserId == null || readingId.isEmpty) {
      return false;
    }
    try {
      await _database
          .child('users/$currentUserId/glucose_readings/$readingId')
          .remove();
      return true; // Return true if the operation was successful
    } catch (e) {
      // Handle the error if needed (e.g., logging)
      print('Error deleting glucose reading: $e');
      return false; // Return false if there was an error
    }
  }

  Stream<List<GlucoseReading>> getGlucoseReadingsStream({String? source}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    firebase_database.Query query =
        _database.child('users/$currentUserId/glucose_readings');

    if (source != null) {
      query = query.orderByChild('source').equalTo(source);
    }

    return query.onValue.map((event) {
      final readingsList = event.snapshot.children
          .map((snapshot) {
            final data = snapshot.value as Map<dynamic, dynamic>?;

            // Ensure the data is not null and contains required fields
            if (data != null &&
                data.containsKey('reading') &&
                data.containsKey('time') &&
                data.containsKey('title') &&
                data.containsKey('source')) {
              return GlucoseReading.fromMap(data);
            } else {
              print('Invalid glucose reading data: $data');
              return null; // Skip invalid data
            }
          })
          .whereType<GlucoseReading>()
          .toList(); // Filter out null values
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <GlucoseReading>[];
      }

      return readingsList;
    });
  }

  Future<GlucoseReading?> getGlucoseReadingAtTime(DateTime time) async {
    final timestamp = time.toIso8601String();
    final snapshot = await _database
        .child('users/$currentUserId/glucose_readings')
        .orderByChild('time')
        .equalTo(timestamp)
        .limitToFirst(1)
        .get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final key = data.keys.first;
      return GlucoseReading.fromMap(data[key]);
    } else {
      return null;
    }
  }

  Future<void> updateGlucoseReading({
    required String readingId,
    DateTime? newTime,
    double? newReading,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newTime != null) {
      updates['time'] = newTime.toIso8601String();
    }
    if (newReading != null) {
      updates['reading'] = newReading;
    }

    if (updates.isNotEmpty) {
      await _database
          .child('users/$currentUserId/glucose_readings/$readingId')
          .update(updates);
    }
  }

  Future<bool> removeGlucoseReadings({required String source}) async {
    if (currentUserId == null) {
      return false;
    }

    try {
      // Fetch the readings with the given source
      final query = _database
          .child('users/$currentUserId/glucose_readings')
          .orderByChild('source')
          .equalTo(source);

      final firebase_database.DatabaseEvent event = await query.once();
      final firebase_database.DataSnapshot snapshot = event.snapshot;

      // Check if any readings exist with that source
      if (snapshot.exists) {
        // Iterate over the readings and remove them
        final updates = <String, dynamic>{};
        snapshot.children.forEach((childSnapshot) {
          updates['users/$currentUserId/glucose_readings/${childSnapshot.key}'] =
              null;
        });

        // Perform the update to remove the readings
        await _database.update(updates);

        return true; // Return true if the removal was successful
      } else {
        return false; // Return false if no readings with that source are found
      }
    } catch (e) {
      print('Error removing glucose readings: $e');
      return false; // Return false if an error occurs
    }
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> showNotification(String title, String body) async {
    if (currentUserId == null) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'alert2', // Channel ID
      'alert2', // Channel name
      channelDescription:
          'Channel for critical alerts with sound and vibration',
      importance: Importance.max, // Ensures it's high priority
      priority: Priority.high, // Pushes it to the top
      fullScreenIntent: true,
      sound: RawResourceAndroidNotificationSound('alert'), // Custom sound
      enableVibration: true, // Enables vibration
      playSound: true,
      autoCancel: true,
      ticker: 'alert2',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
        0, title, body, notificationDetails);
  }

  Timer? timer;

  Future<void> saveDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert DateTime to ISO8601 string
    await prefs.setString('last_notified', date.toIso8601String());
    if (_auth.currentUser?.uid == null) {
      await prefs.remove('last_notified');
    }
  }

  Future<DateTime?> getSavedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString('last_notified');
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  Future<bool> notifyContacts(int value) async {
    try {
      List<Contact> contacts = await getContacts();
      if (contacts.isEmpty) return true;

      for (Contact contact in contacts) {
        if ((value > contact.maxThreshold || value < contact.minThreshold) &&
            contact.sendNotifications &&
            contact.status == 'ready') {
          DateTime? lastNotified = contact.lastNotified;
          if (lastNotified != null) {
            if (DateTime.now().difference(lastNotified).inMinutes < 30) {
              print(
                  '${contact.name} already notified within the last 30 minutes.');
              continue;
            }
            print('Will send message to ${contact.name}.');
          }

          contact.lastNotified = DateTime.now();

          bool messageSent = await sendWhatsAppMessage(contact, value.toInt());
          if (messageSent) {
            updateContact(contact);
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendWhatsAppMessage(Contact contact, int reading) async {
    String contactPhoneNumber = contact.phoneNumber;
    String conatctName = contact.name;

    // Twilio credentials
    final accountSid = dotenv.env['TWILIO_SID'];
    ;
    final authToken = dotenv.env['TWILIO_AUTH_TOKEN'];
    final fromWhatsApp = 'whatsapp:+14155238886'; // Twilio sandbox number
    final toWhatsApp = 'whatsapp:$contactPhoneNumber';

    var t = DateTime.now();
    var date = DateFormat('yyyy-MM-dd').format(t);

    // Encode your Twilio credentials for basic auth
    final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

    // Twilio API endpoint
    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

    try {
      String firstName = await getUserAttribute('firstName') as String;
      String lastName = await getUserAttribute('lastName') as String;

      String message =
          "Urgent: $firstName $lastName's Glucose Level Alert \n\nHi $conatctName, \n\n$firstName $lastName's glucose level is currently $reading mg/dL. Please contact them immediately to ensure they are safe.\n\nInsulinSync app";
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromWhatsApp,
          'To': toWhatsApp,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Message sent! SID: ${responseData['sid']}');
        return true;
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Future<bool> isPhoneNumberExists(String phoneNumber,
      {String? excludeContactId}) async {
    if (currentUserId == null) return false;

    try {
      // Create a query for contacts with the same phone number
      var query = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .where('phoneNumber', isEqualTo: phoneNumber);

      // If we're excluding a specific contact (for edits), add that condition
      if (excludeContactId != null) {
        query =
            query.where(FieldPath.documentId, isNotEqualTo: excludeContactId);
      }

      // Execute the query
      final querySnapshot = await query.get();

      // Return true if any documents match (meaning the phone number exists)
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone number existence: $e');
      return false; // Assume no duplicate in case of error
    }
  }

  void requestFollow(Contact contact) async {
    String contactPhoneNumber = contact.phoneNumber;
    String ContactName = contact.name;

    // Twilio credentials
    final accountSid = dotenv.env['TWILIO_SID'];
    ;
    final authToken = dotenv.env['TWILIO_AUTH_TOKEN'];
    final fromWhatsApp = 'whatsapp:+14155238886';
    final toWhatsApp = 'whatsapp:$contactPhoneNumber';

    var t = DateTime.now();
    var date = DateFormat('yyyy-MM-dd').format(t);

    String firstName = await getUserAttribute('firstName') as String;
    String lastName = await getUserAttribute('lastName') as String;

    // Encode your Twilio credentials for basic auth
    final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

    // Twilio API endpoint
    final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

    try {
      String message =
          'Request to Become ${firstName} $lastName\'s Emergency Contact\n\nHi $ContactName,\n\n${firstName} $lastName would like to add you as an emergency contact in their InsuslinSync application. This means you\'ll be notified if their glucose levels are abnormal.\n\nIf you\'re comfortable with this, please confirm by clicking "OK". If you do not wish to be an emergency contact, you can decline by replying with "Decline".\n\nInsulinSync app';
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromWhatsApp,
          'To': toWhatsApp,
          'Body': message,
        },
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Message sent! SID: ${responseData['sid']}');

        await _firestore
            .collection('pending_requests')
            .doc(responseData['sid'])
            .set({
          'user': currentUserId,
          'to': toWhatsApp,
          'time': DateTime.now(),
        });
      } else {
        print('Failed to send message. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  updateWidget(
      int glucoseValue, int arrowDirection, Color backgroundColor) async {
    HomeWidgetConfig.update(HomeWidget(
      arrowDirection: arrowDirection,
      glucoseValue: glucoseValue,
      backgroundColor: backgroundColor,
    ));
  }

  Future<Map<String, int>> fetchCurrentGlucose(
      {bool isBackgroundTask = false}) async {
    var currentId = currentUserId = _auth.currentUser?.uid;

    if (currentId == null) {
      return {"value": -1, "arrow": -1};
    }
    try {
      if (currentUserId == null) {
        return {'value': -1, 'arrow': -1};
      }

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        print('No internet connectivity');
        _glucoseStreamController!.addError('-');
        _arrowStreamController!.addError('');
        return {'value': -1, 'arrow': -1};
      }

      // Retrieve token and patientId from Firestore
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      // Check if the token and patientId fields exist
      final token = userDoc.data()?['token'];
      final patientId = userDoc.data()?['patientId'];
      final accountId = userDoc.data()?['libreAccountId'];

      if (token == null || patientId == null) {
        print('Debug background: Token or patientId is null');
        _glucoseStreamController!.addError('-');
        _arrowStreamController!.addError('');
        return {
          'value': -1,
          'arrow': -1
        }; // Return early to avoid making the API request
      }

      try {
        final headers = {
          'accept-encoding': 'gzip',
          'Cache-Control': 'no-cache',
          'connection': 'Keep-Alive',
          'content-type': 'application/json',
          'version': '4.12.0',
          'product': 'llu.android',
          "authorization": 'Bearer ${token}',
          'Account-Id': '$accountId'
        };

        // Making API request to LibreView
        final response = await http.get(
          Uri.parse(
              'https://api-eu.libreview.io/llu/connections/${patientId}/graph'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          // Parse the response body as JSON
          final responseData = jsonDecode(response.body);

          // Check if glucose data is available
          var glucoseData =
              responseData['data']['connection']['glucoseMeasurement'];

          if (glucoseData != null) {
            // print('Debug background: glucoseData available: $glucoseData');

            final dateFormat = DateFormat('MM/dd/yyyy h:mm:ss a');

            final rawTimestamp = "${glucoseData['Timestamp']}";
            print('Debug background: rawTimestamp: $rawTimestamp');

            final parsedDate = dateFormat.parse(rawTimestamp);
            print('Debug background: parsedDate: $parsedDate');

            final now = DateTime.now();
            print('Debug background: current time: $now');

            final differenceInMinutes =
                now.difference(parsedDate).inMinutes.abs();
            print(
                'Debug background: time difference in minutes: $differenceInMinutes');

            if (differenceInMinutes >= 2) {
              print('Debug background: data is too old (≥2 minutes)');
              _glucoseStreamController!.addError('check internet');
              _arrowStreamController!.addError('');
              return {'value': -1, 'arrow': -1};
            }

            final glucoseLevel = glucoseData['Value'];
            final arrow = glucoseData['TrendArrow'];
            print(
                'Debug background: glucoseLevel: $glucoseLevel, arrow: $arrow');

            _arrowStreamController!.add(arrow.toInt());
            _glucoseStreamController!.add(glucoseLevel.toDouble());

            print('Debug background: Updating Firestore with new glucose data');
            // Save the glucose data with the formatted time
            await _firestore.collection('users').doc(currentUserId).update({
              'cgm_data.current': {
                'value': glucoseLevel,
                'time': parsedDate,
                'trendArrow': arrow,
              }
            });

            print('Debug background: Successfully returning glucose data');

            return {"value": glucoseLevel.toInt(), "arrow": arrow.toInt()};
          } else {
            print('No glucose data available in response');
            _glucoseStreamController!.addError('-');
            _arrowStreamController!.addError('');
            return {'value': -1, 'arrow': -1};
          }
        } else {
          print('API request failed with status code ${response.statusCode}');
          _glucoseStreamController!.addError('-');
          _arrowStreamController!.addError('');
          return {'value': -1, 'arrow': -1};
        }
      } catch (e, stack) {
        print('Debug background: Exception in API request: $e');
        print('Debug background: Stack trace: $stack');
        _glucoseStreamController!.addError(e);
        _arrowStreamController!.addError('');
        return {'value': -1, 'arrow': -1};
      }
    } catch (e) {
      print('Debug background: Outer exception: $e');
      _glucoseStreamController!.addError('-');
      _arrowStreamController!.addError('');
      return {'value': -1, 'arrow': -1};
    }
  }

  // Start periodic glucose fetching
  void startPeriodicGlucoseFetch({bool isBackgroundTask = false}) {
    // Return if timer is already running
    if (glucoseTimer != null) return;

    int? minRange;
    int? maxRange;

    // Set up periodic glucose check every 10 seconds
    glucoseTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      // Check user authentication
      var currentId = currentUserId = _auth.currentUser?.uid;
      if (currentId == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('last_notified');

        updateGlucoseReadingBackground!(-1);

        // Clean up timer if not in background mode
        if (!isBackgroundTask) {
          glucoseTimer?.cancel();
          glucoseTimer = null;
        }
        return;
      }

      // Fetch current glucose reading
      var result =
          await fetchCurrentGlucose(isBackgroundTask: isBackgroundTask);
      var value = result['value'];
      var arrow = result['arrow'];

      // Handle invalid readings
      if (value == null || arrow == null || arrow == -1 || value == -1) {
        updateGlucoseReadingBackground!(-1);
        await updateWidget(-1, -1, Color(0xffA6A6A6));
        return;
      }

      // Update background notification with current reading
      updateGlucoseReadingBackground?.call(value);

      // Notify emergency contacts
      await notifyContacts(value);

      // Skip notifications if app is in foreground
      if (isAppInForeground?.call() == true) {
        return;
      }

      maxRange = await getUserAttribute('maxRange') as int?;
      minRange = await getUserAttribute('minRange') as int?;

      if (minRange == null || maxRange == null) {
        return;
      }

      // Determine background color
      late Color backgroundColor;

      if (value <= minRange!) {
        backgroundColor = Color(0xffE50000); // Red
      } else if (value >= maxRange!) {
        backgroundColor = Color(0xffFFB732); // Orange
      } else {
        backgroundColor = Color(0xff99CC99); // Green
      }

      await updateWidget(value!, arrow, backgroundColor);

      // Skip alert logic if not in background mode
      if (!isBackgroundTask) {
        return;
      }

      final lastNotified = await getSavedDate();
      final now = DateTime.now();

      // Send high glucose alert if needed
      if (value > maxRange! &&
          (lastNotified == null ||
              now.difference(lastNotified).inMinutes >= 15)) {
        await showNotification(
          "High Glucose Alert",
          "Your glucose level is $value mg/dL\n"
              "This is above your normal range of $minRange-$maxRange mg/dL.\n",
        );
        await saveDate(now);
      }
      // Send low glucose alert if needed
      else if (value < minRange! &&
          (lastNotified == null ||
              now.difference(lastNotified).inMinutes >= 15)) {
        await showNotification(
          "Low Glucose Alert",
          "Your glucose level is $value mg/dL\n"
              "This is below your normal range of $minRange-$maxRange mg/dL.\n",
        );
        await saveDate(now);
      }
    });
  }

  // Stop periodic glucose fetching when no longer needed
  void stopPeriodicGlucoseFetch() {
    glucoseTimer?.cancel();
  }

  void dispose() {
    _glucoseStreamController?.close();
    _arrowStreamController?.close();
    stopPeriodicGlucoseFetch();
  }

  Future<void> fetchAndStoreReadings() async {
    bool hasInternetConnection = true;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        hasInternetConnection = false;
        return; // Internet is not available
      } else {
        hasInternetConnection = true;
      }
    } catch (e, stack) {}

    late final userDoc;
    if (hasInternetConnection) {
      userDoc = await _firestore.collection('users').doc(currentUserId).get();
    } else {
      userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get(GetOptions(source: Source.cache));
    }
    // Check if the token and patientId fields exist
    final token = userDoc.data()?['token'];
    final patientId = userDoc.data()?['patientId'];
    final accountId = userDoc.data()?['libreAccountId'];

    print('token $token patientid $patientId');

    if (token == null || patientId == null || !hasInternetConnection) {
      print('Missing token or patientId');
      return; // Return early to avoid making the API request
    }

    try {
      // Make the HTTP GET request to fetch CGM data
      final headers = {
        'accept-encoding': 'gzip',
        'Cache-Control': 'no-cache',
        'connection': 'Keep-Alive',
        'content-type': 'application/json',
        'version': '4.12.0',
        'product': 'llu.android',
        "authorization": 'Bearer ${token}',
        'Account-Id': '$accountId'
      };

      final response = await http.get(
        Uri.parse(
            'https://api-eu.libreview.io/llu/connections/${patientId}/graph'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        var graphData = data['data']?['graphData'] ?? [];

        // Retrieve the last stored timestamp from Firestore
        final userDoc =
            await _firestore.collection('users').doc(currentUserId).get();

        final lastStoredTimeRaw =
            userDoc.data()?['cgm_data']?['periodic']?['time'];

        // Check if 'lastStoredTimeRaw' is null before calling '.toDate()'
        var lastStoredTime = lastStoredTimeRaw != null
            ? (lastStoredTimeRaw as Timestamp).toDate()
            : null;

        lastStoredTime = null;

        final dateFormat = DateFormat('MM/dd/yyyy h:mm:ss a');

        // Filter out already-stored readings
        final newReadings = graphData.where((reading) {
          final rawTimestamp = reading['Timestamp'];

          final parsedDate = dateFormat.parse(rawTimestamp);

          return lastStoredTime == null || parsedDate.isAfter(lastStoredTime);
        }).toList();

        if (newReadings.isNotEmpty) {
          // Get the latest reading timestamp as a String
          final latestReadingTimestamp =
              newReadings[newReadings.length - 1]['Timestamp'];

          // Parse the String timestamp into a DateTime object
          final parsedLatestReadingTime =
              dateFormat.parse(latestReadingTimestamp);

          // Update the last stored time in the user's document
          await _firestore.collection('users').doc(currentUserId).update({
            'cgm_data.periodic.time':
                Timestamp.fromDate(parsedLatestReadingTime),
          });

          final glucoseReadingsRef = _database
              .child('users')
              .child(currentUserId!)
              .child('glucose_readings');

          // Add each new reading to Firestore
          for (final reading in newReadings) {
            final readingTime = reading['Timestamp'];
            final parsedReadingTime = dateFormat.parse(readingTime);
            final sanitizedTimestamp = parsedReadingTime
                .toIso8601String()
                .replaceAll(':', '_')
                .replaceAll('.', '_');

            final newReading = {
              'reading': reading['Value'],
              'source': 'libreCGM',
              'time': parsedReadingTime.toIso8601String(),
              'title': 'Glucose Reading',
            };

            await _database
                .child('users')
                .child(currentUserId!) // User ID
                .child('glucose_readings') // The 'glucose_readings' path
                .child(
                    sanitizedTimestamp) // Child node for each reading by timestamp
                .set(newReading); // Set the new reading data
          }
        } else {
          print('No new readings found for user $currentUserId.');
        }
      } else if (response.statusCode == 401) {
        // Handle expired/invalid token case
        await _firestore.collection('users').doc(currentUserId).update({
          'token': null,
        });
      } else {
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error, stackTrace) {
      print('Error fetching readings: ${stackTrace}');
    }
  }

  Future<bool> isCgmConnected() async {
    bool hasInternetConnection = true;

    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        hasInternetConnection = false; // Internet is not available
      } else {
        hasInternetConnection = true;
      }
    } catch (e, stack) {}

    try {
      if (currentUserId == null) return false;

      // Retrieve token and patientId from Firestore

      late final userDoc;

      if (hasInternetConnection) {
        userDoc = await _firestore.collection('users').doc(currentUserId).get();
      } else {
        userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get(GetOptions(source: Source.cache));
      }

      final token = userDoc.data()?['token'];
      final patientId = userDoc.data()?['patientId'];
      final accountId = userDoc.data()?['libreAccountId'];

      if (token == null || patientId == null) {
        _glucoseStreamController?.addError('-');
        _arrowStreamController?.addError('-');
        return false;
      }

      if (!hasInternetConnection) {
        return true;
      }

      try {
        final headers = {
          'accept-encoding': 'gzip',
          'Cache-Control': 'no-cache',
          'connection': 'Keep-Alive',
          'content-type': 'application/json',
          'version': '4.12.0',
          'product': 'llu.android',
          "authorization": 'Bearer $token',
          'Account-Id': '$accountId'
        };

        final response = await http.get(
          Uri.parse(
              'https://api-eu.libreview.io/llu/connections/$patientId/graph'),
          headers: headers,
        );

        if (response.statusCode == 401) {
          await _firestore
              .collection('users')
              .doc(currentUserId)
              .update({'token': null});
          return false;
        } else if (response.statusCode == 200) {
          return true;
        } else {}
      } catch (e) {}
    } catch (e) {}

    return false;
  }

  ///////////////////////

  Future<bool> addNote(Note note) async {
    // Check if the currentUserId is null
    if (currentUserId == null) {
      return false; // Return false if user is not authenticated
    }

    try {
      // Reference to the notes sub-collection for the current user
      final noteRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notes')
          .doc(); // Auto-generate an ID for the note

      // Add the note document to Firestore
      await noteRef.set(note.toMap());
      return true; // Return true if the addition is successful
    } catch (e) {
      // Log the error or handle it as needed
      print('Error adding note: $e');
      return false; // Return false if there was an error
    }
  }

  Future<List<Note>> getNotes() async {
    if (currentUserId == null) {
      return []; // Return an empty list if the user is not authenticated
    }

    // Check internet connectivity
    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = result != ConnectivityResult.none;

    // Set Firestore options to use cache if no internet connection
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      // Fetch notes from the 'notes' sub-collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notes')
          .get(options);

      // Map the fetched documents to a list of Note objects
      return querySnapshot.docs
          .map((doc) => Note.fromMap(doc.data()
            ..['id'] = doc.id)) // Add the document ID to the note if needed
          .toList();
    } catch (e) {
      print('Error getting notes: $e');
      return []; // Return an empty list if there was an error
    }
  }

  Stream<List<Note>> getNotesStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list when there's no user
      return Stream.value(<Note>[]);
    }

    // Stream notes from the 'notes' sub-collection
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notes')
        .snapshots()
        .map((querySnapshot) {
      try {
        // Map each document in the snapshot to a Note object
        return querySnapshot.docs
            .map((doc) => Note.fromMap(
                doc.data()..['id'] = doc.id)) // Include the document ID
            .toList();
      } catch (e) {
        print('Error processing notes stream: $e');
        return <Note>[]; // Return an empty list if there's an error
      }
    });
  }

  Future<bool> deleteNote(String noteId) async {
    if (currentUserId == null) {
      return false;
    }

    try {
      final noteRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notes')
          .doc(noteId);

      await noteRef.delete();
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  Future<void> updateNote({
    required String noteId,
    String? newTitle,
    String? newComment,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newTitle != null) {
      updates['title'] = newTitle;
    }
    if (newComment != null) {
      updates['comment'] = newComment;
    }

    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('notes')
          .doc(noteId)
          .update(updates);
    }
  }

  /////////////////

  Future<bool> addInsulinDosage(InsulinDosage dosage) async {
    if (currentUserId == null) {
      return false; // Return false if currentUserId is null
    }
    try {
      // Add the insulin dosage as a new document in the 'insulin_dosages' sub-collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('insulin_dosages')
          .add(dosage.toMap());
      return true; // Return true if the operation was successful
    } catch (e) {
      print('Error adding insulin dosage: $e');
      return false; // Return false if there was an error
    }
  }

  Future<List<InsulinDosage>> getInsulinDosages() async {
    if (currentUserId == null) {
      return [];
    }

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      // Fetch all documents in the 'insulin_dosages' sub-collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('insulin_dosages')
          .get(options);

      return querySnapshot.docs
          .map((doc) => InsulinDosage.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Error fetching insulin dosages: $e');
      return [];
    }
  }

  Stream<List<InsulinDosage>> getInsulinDosagesStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list when there's no user
      return Stream.value(<InsulinDosage>[]);
    }

    // Stream documents from the 'insulin_dosages' sub-collection
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('insulin_dosages')
        .snapshots()
        .map((querySnapshot) {
      try {
        // Map each document in the snapshot to an InsulinDosage object
        return querySnapshot.docs
            .map((doc) => InsulinDosage.fromMap(doc.data()..['id'] = doc.id))
            .toList();
      } catch (e) {
        print('Error processing insulin dosages stream: $e');
        return <InsulinDosage>[];
      }
    });
  }

  Future<void> updateInsulinDosage({
    required String dosageId,
    String? newType,
    double? newDosage,
    DateTime? newTime,
    GlucoseReading? newGlucoseAtTime,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newType != null) updates['type'] = newType;
    if (newDosage != null) updates['dosage'] = newDosage;
    if (newTime != null) updates['time'] = newTime.toIso8601String();
    if (newGlucoseAtTime != null)
      updates['glucoseAtTime'] = newGlucoseAtTime.toMap();

    if (updates.isNotEmpty) {
      try {
        // Update the specific document in the 'insulin_dosages' sub-collection
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('insulin_dosages')
            .doc(dosageId)
            .update(updates);
      } catch (e) {
        print('Error updating insulin dosage: $e');
      }
    }
  }

  Future<bool> deleteInsulinDosage(String dosageId) async {
    if (currentUserId == null) {
      return false;
    }

    try {
      final dosageRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('insulin_dosages')
          .doc(dosageId);

      await dosageRef.delete();
      return true;
    } catch (e) {
      print('Error deleting insulin dosage: $e');
      return false;
    }
  }

  Future<double> getTotalDosages(String type, DateTime day) async {
    List<InsulinDosage> insulinList = await getInsulinDosages();

    if (insulinList.isEmpty) {
      return 0.0;
    }

    double totalDosages = 0.0;

    DateTime startOfDay = DateTime(day.year, day.month, day.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    for (InsulinDosage dosage in insulinList) {
      if (dosage.time.isAfter(startOfDay) && dosage.time.isBefore(endOfDay)) {
        if (dosage.type.toLowerCase() == type.toLowerCase()) {
          totalDosages += dosage.dosage;
        }
      }
    }

    return totalDosages;
  }

  //////////////////

  Future<bool> addWorkout(Workout workout) async {
    if (currentUserId == null) return false;

    try {
      // Add the workout as a new document in the 'workouts' sub-collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('workouts')
          .add(workout.toMap());
      print("addWorkout 2");
      return true; // Return true if the operation was successful
    } catch (e) {
      print("addWorkout 3");
      print('Error adding workout: $e');
      return false; // Return false if there's an error
    }
  }

  Future<List<Workout>> getWorkouts() async {
    if (currentUserId == null) {
      return [];
    }

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      // Fetch all documents in the 'workouts' sub-collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('workouts')
          .get(options);

      return querySnapshot.docs
          .map((doc) => Workout.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Error fetching workouts: $e');
      return [];
    }
  }

  Stream<List<Workout>> getWorkoutsStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list when there's no user
      return Stream.value(<Workout>[]);
    }

    // Stream documents from the 'workouts' sub-collection
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('workouts')
        .snapshots()
        .map((querySnapshot) {
      try {
        // Map each document in the snapshot to a Workout object
        return querySnapshot.docs
            .map((doc) => Workout.fromMap(doc.data()..['id'] = doc.id))
            .toList();
      } catch (e) {
        print('Error processing workouts stream: $e');
        return <Workout>[];
      }
    });
  }

  Future<bool> deleteWorkout(String workoutId) async {
    // Check if the currentUserId is null
    if (currentUserId == null) {
      return false; // Return false if user is not authenticated
    }

    try {
      // Reference to the workout document to be deleted
      final workoutRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('workouts')
          .doc(workoutId); // Use the provided workout ID

      // Delete the workout document from Firestore
      await workoutRef.delete();
      return true; // Return true if the deletion is successful
    } catch (e) {
      // Log the error or handle it as needed
      print('Error deleting workout: $e');
      return false; // Return false if there was an error
    }
  }

//////////////////

  Future<bool> addCarbohydrate(Carbohydrate carbohydrate) async {
    if (currentUserId == null) return false; // Return false if user ID is null

    try {
      // Add the carbohydrate as a new document in the 'carbohydrates' sub-collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('carbohydrates')
          .add(carbohydrate.toMap());
      return true; // Return true if the operation was successful
    } catch (e) {
      print('Error adding carbohydrate: $e');
      return false; // Return false if there's an error
    }
  }

  Future<List<Carbohydrate>> getCarbohydrates() async {
    if (currentUserId == null)
      return []; // Return empty list if user ID is null

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      // Fetch all documents in the 'carbohydrates' sub-collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('carbohydrates')
          .get(options);

      return querySnapshot.docs
          .map((doc) => Carbohydrate.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Error fetching carbohydrates: $e');
      return [];
    }
  }

  Stream<List<Carbohydrate>> getCarbohydratesStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list when there's no user
      return Stream.value(<Carbohydrate>[]);
    }

    // Stream documents from the 'carbohydrates' sub-collection
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('carbohydrates')
        .snapshots()
        .map((querySnapshot) {
      try {
        // Map each document in the snapshot to a Carbohydrate object
        return querySnapshot.docs
            .map((doc) => Carbohydrate.fromMap(doc.data()..['id'] = doc.id))
            .toList();
      } catch (e) {
        print('Error processing carbohydrates stream: $e');
        return <Carbohydrate>[];
      }
    });
  }

  Future<double> getTotalCarbs({bool onlyToday = true}) async {
    List<Carbohydrate> carbsList = await getCarbohydrates();

    if (carbsList.isEmpty) {
      return 0.0;
    }

    double totalCarbs = 0.0;

    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    for (Carbohydrate carb in carbsList) {
      if (onlyToday) {
        if (carb.time.isAfter(startOfDay) && carb.time.isBefore(endOfDay)) {
          totalCarbs += carb.amount;
        }
      } else {
        totalCarbs += carb.amount;
      }
    }

    return totalCarbs;
  }

//////////////////

  Future<String?> addMeal(meal meal) async {
    if (currentUserId == null) {
      return null; // Return null if currentUserId is null
    }

    try {
      // Add the meal to Firestore and get the reference
      var mealRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .add(meal.toMap());

      // Return the generated meal ID
      return mealRef.id;
    } catch (e) {
      print('Error adding meal: $e');
      return null; // Return null if there was an error
    }
  }

  Future<List<meal>> getMeal() async {
    if (currentUserId == null)
      return []; // Return empty list if currentUserId is null

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      // Fetch all meals from the 'meals' collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .get(options);

      List<meal> mealsList = [];
      for (var doc in querySnapshot.docs) {
        // Add the meal directly (no need to fetch foodItems here)
        mealsList.add(meal.fromMap(doc.data()..['id'] = doc.id));
      }

      return mealsList;
    } catch (e) {
      print('Error fetching meals: $e');
      return [];
    }
  }

  Stream<List<meal>> getMealStream() async* {
    if (currentUserId == null) {
      yield <meal>[]; // Return an empty list when there's no user
      return;
    }

    // Listen to the changes in the 'meals' collection
    await for (var querySnapshot in _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('meals')
        .snapshots()) {
      List<meal> mealsList = [];

      for (var doc in querySnapshot.docs) {
        // Add the meal directly (no need to fetch foodItems here)
        mealsList.add(meal.fromMap(doc.data()..['id'] = doc.id));
      }

      yield mealsList; // Yield the updated list of meals
    }
  }

  Future<bool> deleteMeal(String mealId) async {
    if (currentUserId == null) {
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .doc(mealId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting meal: $e');
      return false;
    }
  }

  Future<Map<String, double>> getTotalMeal({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final meals = await getMeal();

    double carb = 0.0, fat = 0.0, protein = 0.0, calorie = 0.0;
    final filterStart = startDate;
    final filterEnd = endDate ?? (startDate?.add(const Duration(days: 1)));

    for (final meal in meals) {
      // Skip if date filtering is active and meal is outside range
      if (filterStart != null &&
          (meal.time.isBefore(filterStart) ||
              (filterEnd != null && meal.time.isAfter(filterEnd)))) {
        continue;
      }

      // Sum all nutrition values directly
      for (final food in meal.foodItems) {
        carb += food.carb;
        fat += food.fat;
        protein += food.protein;
        calorie += food.calorie;
      }
    }

    return {
      'totalCarb': carb,
      'totalFat': fat,
      'totalProtein': protein,
      'totalCal': calorie,
    };
  }

  Future<void> updateMeal({
    required String mealId,
    String? newTitle,
    DateTime? newTime,
    List<foodItem>? newFoodItems,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newTitle != null) updates['title'] = newTitle;
    if (newTime != null) updates['time'] = Timestamp.fromDate(newTime);
    if (newFoodItems != null) {
      updates['foodItems'] = newFoodItems.map((item) => item.toMap()).toList();
      updates['totalCarb'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.carb);
      updates['totalProtein'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.protein);
      updates['totalFat'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.fat);
      updates['totalCalorie'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.calorie);
    }

    if (updates.isNotEmpty) {
      try {
        // Update the specific document in the 'meals' sub-collection
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('meals')
            .doc(mealId)
            .update(updates);
      } catch (e) {
        print('Error updating meal: $e');
      }
    }
  }

///////////////////

// Add FavoriteMeal as meal
  Future<String?> addToFavorite(meal meal) async {
    if (currentUserId == null) {
      return null; // Return null if currentUserId is null
    }

    try {
      var mealRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_meals')
          .add(meal.toMap());

      return mealRef.id;
    } catch (e) {
      print('Error adding favorite meal: $e');
      return null;
    }
  }

// Get FavoriteMeals as List<meal>
  Future<List<meal>> getFavoriteMeals() async {
    if (currentUserId == null) return [];

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_meals')
          .get(options);

      List<meal> mealsList = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the map
        mealsList.add(meal.fromMap(data));
      }

      return mealsList;
    } catch (e) {
      print('Error fetching favorite meals: $e');
      return [];
    }
  }

  Stream<List<meal>> getFavoriteMealStream() async* {
    if (currentUserId == null) {
      yield <meal>[];
      return;
    }

    await for (var querySnapshot in _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_meals')
        .snapshots()) {
      List<meal> mealsList = [];

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the map
        mealsList.add(meal.fromMap(data));
      }

      yield mealsList;
    }
  }

// Remove FavoriteMeal as meal
  Future<bool> removeFromFavorite(String? mealId) async {
    print('Debug fav: Starting removeFromFavorite()');
    print('Debug fav: currentUserId = $currentUserId');
    print('Debug fav: mealId = $mealId');

    if (currentUserId == null) {
      print('Debug fav: currentUserId is null, returning false');
      return false;
    }

    try {
      final userDocRef = _firestore.collection('users').doc(currentUserId);
      final favMealDocRef = userDocRef.collection('favorite_meals').doc(mealId);

      print(
          'Debug fav: Deleting from path = users/$currentUserId/favorite_meals/$mealId');

      await favMealDocRef.delete();

      print('Debug fav: Successfully deleted meal from favorites');
      return true;
    } catch (e) {
      print('Debug fav: Error removing favorite meal: $e');
      return false;
    }
  }

// Update FavoriteMeal as meal
  Future<void> updateFavoriteMeal({
    required String mealId,
    String? newTitle,
    List<foodItem>? newFoodItems,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newTitle != null) updates['title'] = newTitle;
    if (newFoodItems != null) {
      updates['foodItems'] = newFoodItems.map((item) => item.toMap()).toList();
      updates['totalCarb'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.carb);
      updates['totalProtein'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.protein);
      updates['totalFat'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.fat);
      updates['totalCalorie'] =
          newFoodItems.fold(0.0, (double sum, item) => sum + item.calorie);
    }

    if (updates.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('favorite_meals')
            .doc(mealId)
            .update(updates);
      } catch (e) {
        print('Error updating favorite meal: $e');
      }
    }
  }

//////////////////
  Future<String?> addItemToFavorite(foodItem item) async {
    if (currentUserId == null) {
      return null; // Return null if currentUserId is null
    }

    try {
      var foodItemRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_food_items')
          .add(item.toMap());

      return foodItemRef.id;
    } catch (e) {
      print('Error adding food item to favorites: $e');
      return null;
    }
  }

  Future<List<foodItem>> getFavoriteFoodItems() async {
    if (currentUserId == null) return [];

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_food_items')
          .get(options);

      List<foodItem> foodItemsList = [];
      for (var doc in querySnapshot.docs) {
        var foodItemModel =
            foodItem.fromMap(doc.data() as Map<String, dynamic>);
        foodItemModel.id = doc.id;

        foodItemsList.add(foodItemModel);
      }

      return foodItemsList;
    } catch (e) {
      print('Error fetching favorite food items: $e');
      return [];
    }
  }

  Stream<List<foodItem>> getFavoriteFoodItemStream() async* {
    if (currentUserId == null) {
      yield <foodItem>[];
      return;
    }

    await for (var querySnapshot in _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorite_food_items')
        .snapshots()) {
      List<foodItem> foodItemsList = [];

      for (var doc in querySnapshot.docs) {
        var foodItemModel =
            foodItem.fromMap(doc.data() as Map<String, dynamic>);
        foodItemModel.id = doc.id;

        foodItemsList.add(foodItemModel);
      }

      yield foodItemsList;
    }
  }

  Future<bool> removeItemFromFavorite(String? itemId) async {
    if (currentUserId == null) {
      return false;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorite_food_items')
          .doc(itemId)
          .delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateFavoriteItem({
    required String itemId,
    String? newName,
    double? newPortion,
    double? newProtein,
    double? newFat,
    double? newCarb,
    double? newCalorie,
    String? newSource,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newName != null) updates['name'] = newName;
    if (newPortion != null) updates['portion'] = newPortion;
    if (newProtein != null) updates['protein'] = newProtein;
    if (newFat != null) updates['fat'] = newFat;
    if (newCarb != null) updates['carb'] = newCarb;
    if (newCalorie != null) updates['calorie'] = newCalorie;
    if (newSource != null) updates['source'] = newSource;

    if (updates.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('favorite_food_items')
            .doc(itemId)
            .update(updates);
      } catch (e) {
        print('Error updating favorite food item: $e');
      }
    }
  }

/////////////////

  // Add a contact to the Firestore database
  Future<bool> addContact(Contact contact) async {
    if (currentUserId == null) return false; // Return false if user ID is null

    try {
      // Add the contact as a new document in the 'contacts' sub-collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contact.id)
          .set(contact.toMap());
      return true; // Return true if the operation was successful
    } catch (e) {
      print('Error adding contact: $e');
      return false; // Return false if there's an error
    }
  }

  Future<void> deleteContact(String? id) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(id) // Use actual Firestore document ID
          .delete();
      print("Contact deleted successfully");
    } catch (e) {
      print("Error deleting contact: $e");
    }
  }

// Fetch all contacts from the Firestore database
  Future<List<Contact>> getContacts() async {
    if (currentUserId == null) {
      return []; // Return an empty list if user ID is null (user not authenticated)
    }

    // Check internet connectivity
    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = result != ConnectivityResult.none;

    // Set Firestore options to use cache if no internet connection
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);
    try {
      // Fetch contacts from the 'contacts' sub-collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .get(options);

      // Map the fetched documents to a list of Contact objects
      final contacts = querySnapshot.docs.map((doc) {
        final contact = Contact.fromMap(doc.data()..['id'] = doc.id);
        return contact;
      }).toList();

      return contacts;
    } catch (e) {
      print('Error fetching contacts: $e');
      return []; // Return an empty list if there was an error
    }
  }

// Stream contacts in real-time from Firestore
  Stream<List<Contact>> getContactsStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list if user ID is null
      return Stream.value(<Contact>[]);
    }

    // Stream documents from the 'contacts' sub-collection
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('contacts')
        .snapshots()
        .map((querySnapshot) {
      try {
        // Map each document in the snapshot to a Contact object
        return querySnapshot.docs
            .map((doc) =>
                Contact.fromMap(doc.data()..['id'] = doc.id)) // Pass doc.id
            .toList();
      } catch (e) {
        print('Error processing contacts stream: $e');
        return <Contact>[];
      }
    });
  }

  Future<bool> updateContact(Contact updatedContact) async {
    if (currentUserId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(updatedContact.id) // Use contact ID
          .update(updatedContact.toMap()); // Update fields

      print('Contact updated successfully');
      return true;
    } catch (e) {
      print('Error updating contact: $e');
      return false;
    }
  }

  // Method to check if a meal is already in favorite meals
  Future<bool> isMealAlreadyFavorite(meal currentMeal) async {
    try {
      // Fetch all favorite meals for the current user
      var querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favoriteMeals')
          .get();

      for (var doc in querySnapshot.docs) {
        // Convert the document to a FavoriteMeal object
        meal favoriteMeal = meal.fromMap(doc.data());

        // Check if the title matches
        if (favoriteMeal.title == currentMeal.title) {
          // Check if all foodItems are present
          if (areFoodItemsEqual(
              favoriteMeal.foodItems, currentMeal.foodItems)) {
            return true; // The meal is already in favorites
          }
        }
      }

      return false; // Meal is not in favorites
    } catch (e) {
      print("Error checking favorite meals: $e");
      return false;
    }
  }

  // Helper method to compare foodItems in two meals
  bool areFoodItemsEqual(List<foodItem> foodItems1, List<foodItem> foodItems2) {
    // Check if both lists have the same length
    if (foodItems1.length != foodItems2.length) {
      return false;
    }

    // Check if each food item in foodItems1 is present in foodItems2
    for (var item1 in foodItems1) {
      bool found = false;
      for (var item2 in foodItems2) {
        if (item1 == item2) {
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }
    return true;
  }

//////////////////

  Future<dynamic> getUserAttribute(String attribute) async {
    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    if (currentUserId == null) throw Exception("User not authenticated");

    final snapshot =
        await _firestore.collection('users').doc(currentUserId).get(options);

    if (!snapshot.exists) return null;

    final data = snapshot.data();

    if (data == null) return null;

    // Handle nested attributes (e.g., 'cgm_data/periodic/time')
    final attributeParts = attribute.split('/');
    dynamic current = data;

    for (var part in attributeParts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }

  Stream<dynamic> getUserAttributeStream(String attribute) {
    if (currentUserId == null) throw Exception("User not authenticated");

    return _firestore.collection('users').doc(currentUserId).snapshots().map(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          return data?[attribute];
        } else {
          throw Exception("User data not found");
        }
      },
    );
  }

  Future<bool> updateUserAttributes({
    String? firstName,
    String? lastName,
    String? email,
    double? weight,
    double? height,
    bool? gender,
    DateTime? dateOfBirth,
    double? dailyBolus,
    double? dailyBasal,
    double? carbRatio,
    double? correctionRatio,
    String? libreEmail,
    String? libreName,
    String? libreAccountId,
    String? patientId,
    String? token,
    int? minRange,
    int? maxRange,
    bool? recieveNotifications,
  }) async {
    if (currentUserId == null)
      return false; // Return false if the user ID is null

    final Map<String, dynamic> updates = {};

    // Add fields to the update map if not null
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (email != null) updates['email'] = email;
    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (gender != null) updates['gender'] = gender;
    if (dateOfBirth != null)
      updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
    if (dailyBolus != null) updates['dailyBolus'] = dailyBolus;
    if (dailyBasal != null) updates['dailyBasal'] = dailyBasal;
    if (carbRatio != null) updates['carbRatio'] = carbRatio;
    if (correctionRatio != null) updates['correctionRatio'] = correctionRatio;
    if (libreEmail != null) updates['libreEmail'] = libreEmail;
    if (libreName != null) updates['libreName'] = libreName;
    if (patientId != null) updates['patientId'] = patientId;
    if (libreAccountId != null) updates['libreAccountId'] = libreAccountId;
    if (token != null) updates['token'] = token;
    if (minRange != null) updates['minRange'] = minRange;
    if (maxRange != null) updates['maxRange'] = maxRange;
    if (recieveNotifications != null)
      updates['recieveNotifications'] = recieveNotifications;

    if (updates.isNotEmpty) {
      try {
        // Set a timeout for the operation
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .update(updates)
            .timeout(
          Duration(seconds: 10), // Set a timeout of 10 seconds
          onTimeout: () {
            // Handle the timeout situation
            print('Update operation timed out.');
            throw TimeoutException('The operation timed out');
          },
        );
        return true; // Return true if the update is successful
      } catch (e) {
        return false; // Return false if there is an error
      }
    }

    return false; // Return false if there are no updates
  }

  Future<bool> removeUserAttributes(
      {bool? removeWeight,
      bool? removeHeight,
      bool? removeGender,
      bool? removeDailyBolus,
      bool? removeDailyBasal,
      bool? removeCarbRatio,
      bool? removeCorrectionRatio,
      bool? removeLibreEmail,
      bool? removeLibreAccountId,
      bool? removeLibreName,
      bool? removePatientId,
      bool? removeToken,
      bool? removeMinRange,
      bool? removeMaxRange,
      bool? removerecieveNotifications,
      bool? removeCgmData}) async {
    if (currentUserId == null)
      return false; // Return false if the user ID is null

    final Map<String, dynamic> updates = {};

    // Add fields to the update map for removal if `true`
    if (removeWeight == true) updates['weight'] = FieldValue.delete();
    if (removeHeight == true) updates['height'] = FieldValue.delete();
    if (removeGender == true) updates['gender'] = FieldValue.delete();
    if (removeDailyBolus == true) updates['dailyBolus'] = FieldValue.delete();
    if (removeDailyBasal == true) updates['dailyBasal'] = FieldValue.delete();
    if (removeCarbRatio == true) updates['carbRatio'] = FieldValue.delete();
    if (removeCorrectionRatio == true)
      updates['correctionRatio'] = FieldValue.delete();
    if (removeLibreEmail == true) updates['libreEmail'] = FieldValue.delete();
    if (removeLibreName == true) updates['libreName'] = FieldValue.delete();
    if (removePatientId == true) updates['patientId'] = FieldValue.delete();
    if (removeLibreAccountId == true)
      updates['libreAccountId'] = FieldValue.delete();
    if (removeToken == true) updates['token'] = FieldValue.delete();
    if (removeMinRange == true) updates['minRange'] = FieldValue.delete();
    if (removeMaxRange == true) updates['maxRange'] = FieldValue.delete();
    if (removerecieveNotifications == true)
      updates['recieveNotifications'] = FieldValue.delete();
    if (removeCgmData == true) updates['cgm_data'] = FieldValue.delete();

    if (updates.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .update(updates)
            .timeout(
          Duration(seconds: 10),
          onTimeout: () {
            print('Remove operation timed out.');
            throw TimeoutException('The operation timed out');
          },
        );
        return true; // Return true if the update is successful
      } catch (e) {
        print("Error: $e");
        return false; // Return false if there is an error
      }
    }

    return false; // Return false if there are no attributes to remove
  }

  Timer? glucoseWarningTimer;

  void startGlucoseMonitoring() {
    glucoseWarningTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await checkGlucoseAndShowWarning();
    });
  }

  Future<void> checkGlucoseAndShowWarning() async {
    try {
      int glucoseReading = (await fetchCurrentGlucose())['value'] as int;
      int maxGlucoseLevel = await getUserAttribute('maxRange') as int;

      if (glucoseReading > maxGlucoseLevel) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? lastWarning = prefs.getString('LastWarning');
        DateTime now = DateTime.now();

        if (lastWarning != null) {
          DateTime lastWarningTime = DateTime.parse(lastWarning);

          if (now.difference(lastWarningTime).inMinutes > 15) {
            prefs.setBool('showCorrectionBox', true);
            prefs.setString('LastWarning', now.toIso8601String());

            // Notify the background service
            FlutterBackgroundService().invoke('setLastWarning', {
              'LastWarning': now.toIso8601String(),
            });
          }
        } else {
          prefs.setBool('showCorrectionBox', true);
          prefs.setString('LastWarning', now.toIso8601String());

          // Notify the background service
          FlutterBackgroundService().invoke('setLastWarning', {
            'LastWarning': now.toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('Error checking glucose levels: $e');
    }
  }

  void stopGlucoseMonitoring() {
    glucoseWarningTimer?.cancel();
  }
}
