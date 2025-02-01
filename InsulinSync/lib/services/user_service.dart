import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart' as firebase_database;
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
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

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String? currentUserId;

  StreamController<double>? _glucoseStreamController;
  StreamController<int>? _arrowStreamController;
  Timer? _glucoseTimer;

  Stream<double> get glucoseStream =>
      _glucoseStreamController!.stream.asBroadcastStream();
  Stream<int> get arrowStream =>
      _arrowStreamController!.stream.asBroadcastStream();

  UserService() {
    currentUserId = _auth.currentUser?.uid;
    _glucoseStreamController = StreamController<double>();
    _arrowStreamController = StreamController<int>();
  }

  Future<void> createUser(UserModel user) async {
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).set(user.toMap());
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
        final readingsList = snapshot.children
            .map((childSnapshot) => GlucoseReading.fromMap(
                childSnapshot.value as Map<dynamic, dynamic>))
            .toList();

        return readingsList;
      } else {
        return [];
      }
    } catch (e, stack) {
      print('Error fetching glucose readings: $e   $stack');
      return [];
    }
  }

  Stream<List<GlucoseReading>> getGlucoseReadingsStream({String? source}) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    firebase_database.Query query =
        _database.child('users/$currentUserId/glucose_readings');

    // Apply the filter if a source is provided
    if (source != null) {
      query = query.orderByChild('source').equalTo(source);
    }

    return query.onValue.map((event) {
      final readingsList = event.snapshot.children
          .map((snapshot) => GlucoseReading.fromMap(
              snapshot.value as Map<dynamic, dynamic>)) // Cast here
          .toList();
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

  Future<void> fetchCurrentGlucose() async {
    try {
      if (currentUserId == null) return;

      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        _glucoseStreamController!.addError('-');
        _arrowStreamController!.addError('');
        return;
      }

      // Retrieve token and patientId from Firestore
      final userDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      // Check if the token and patientId fields exist
      final token = userDoc.data()?['token'];
      final patientId = userDoc.data()?['patientId'];
      final accountId = userDoc.data()?['libreAccountId'];

      if (token == null || patientId == null) {
        _glucoseStreamController!.addError('-');
        _arrowStreamController!.addError('');
        return; // Return early to avoid making the API request
      }

      print(' token $token      patientid $patientId');

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

        final response = await http.get(
          Uri.parse(
              'https://api-eu.libreview.io/llu/connections/${patientId}/graph'),
          headers: headers,
        );

        print(' respose ${response.body}');

        if (response.statusCode == 200) {
          // Parse the response body as JSON
          final responseData = jsonDecode(response.body);

          // Check if glucose data is available
          var glucoseData =
              responseData['data']['connection']['glucoseMeasurement'];

          if (glucoseData != null) {
            print(' glucoseData $glucoseData');

            final dateFormat = DateFormat('MM/dd/yyyy h:mm:ss a');

            final rawTimestamp = "${glucoseData['Timestamp']}";

            final parsedDate = dateFormat.parse(rawTimestamp);

            final now = DateTime.now();

            // Check if the time difference is within 2 minutes
            if (now.difference(parsedDate).inMinutes.abs() >= 2) {
              // Todo modify
              _glucoseStreamController!.addError('check internet');
              _arrowStreamController!.addError('');
              return;
            }

            final glucoseLevel = glucoseData['Value'];
            final arrow = glucoseData['TrendArrow'];
            _arrowStreamController!.add(arrow.toInt());
            _glucoseStreamController!.add(glucoseLevel.toDouble());

            // Save the glucose data with the formatted time
            await _firestore.collection('users').doc(currentUserId).update({
              'cgm_data.current': {
                'value': glucoseLevel,
                'time': parsedDate,
                'trendArrow': arrow,
              }
            });
          } else {
            _glucoseStreamController!.addError('-');
            _arrowStreamController!.addError('');
          }
        } else {
          _glucoseStreamController!.addError('-');
          _arrowStreamController!.addError('');
        }
      } catch (e, stack) {
        _glucoseStreamController!.addError(e);
        _arrowStreamController!.addError('');
      }
    } catch (e) {
      _glucoseStreamController!.addError('-');
      _arrowStreamController!.addError('');
    }
  }

  // Start periodic glucose fetching
  void startPeriodicGlucoseFetch() {
    if (_glucoseTimer != null) {
      return; // Timer is already running
    }
// TODO change to 10 seconds
    _glucoseTimer = Timer.periodic(Duration(seconds: 10), (_) {
      fetchCurrentGlucose(); // Fetch glucose every 30 seconds
    });
  }

  // Stop periodic glucose fetching when no longer needed
  void stopPeriodicGlucoseFetch() {
    _glucoseTimer?.cancel();
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

  // Future<bool> addNote(Note note) async {
  //   // Check if the currentUserId is null
  //   if (currentUserId == null) {
  //     return false; // Return false if user is not authenticated
  //   }

  //   try {
  //     // Attempt to update the user's notes in Firestore
  //     await _firestore.collection('users').doc(currentUserId).update({
  //       'notes': FieldValue.arrayUnion([note.toMap()]),
  //     });
  //     return true; // Return true if the addition is successful
  //   } catch (e) {
  //     // Log the error or handle it as needed
  //     print('Error adding note: $e');
  //     return false; // Return false if there was an error
  //   }
  // }

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

      // Assign the auto-generated ID to the note object (optional)

      // Add the note document to Firestore
      await noteRef.set(note.toMap());
      return true; // Return true if the addition is successful
    } catch (e) {
      // Log the error or handle it as needed
      print('Error adding note: $e');
      return false; // Return false if there was an error
    }
  }

// Future<List<Note>> getNotes() async {
//     if (currentUserId == null) {
//       return [];
//     }

//     var result = await Connectivity().checkConnectivity();
//     bool hasInternetConnection = !result.contains(ConnectivityResult.none);
//     var options = null;
//     if (!hasInternetConnection) {
//       options = GetOptions(source: Source.cache);
//     }

//     try {
//       DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
//           .instance
//           .collection('users')
//           .doc(currentUserId)
//           .get(options);

//       if (snapshot.exists &&
//           snapshot.data() != null &&
//           snapshot.data()!.containsKey('notes')) {
//         List<dynamic> notes = snapshot['notes'] ?? [];
//         return notes.map((map) => Note.fromMap(map)).toList();
//       } else {
//         return [];
//       }
//     } catch (e) {
//       print('Error getting notes: $e');
//       return [];
//     }
//   }

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

// Stream<List<Note>> getNotesStream() {
//     if (currentUserId == null) {
//       // Return a stream that emits an empty list when there's no user
//       return Stream.value(<Note>[]);
//     }

//     return _firestore
//         .collection('users')
//         .doc(currentUserId)
//         .snapshots()
//         .map((snapshot) {
//       try {
//         // Attempt to get data from the snapshot
//         final data = snapshot.data();

//         // If 'notes' field is missing or not a List, return an empty list
//         if (data == null || data['notes'] == null || data['notes'] is! List) {
//           return <Note>[];
//         }

//         // Safely map the 'notes' field to a list of Note objects
//         List<dynamic> notes = data['notes'];
//         return notes
//             .map((map) => Note.fromMap(map as Map<String, dynamic>))
//             .toList();
//       } catch (e) {
//         // If any error occurs, return an empty list
//         return <Note>[];
//       }
//     });
//   }

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

  Future<double> getTotalDosages(String type) async {
    List<InsulinDosage> insulinList = await getInsulinDosages();

    if (insulinList.isEmpty) {
      return 0.0;
    }

    double totalDosages = 0.0;

    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
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
      // TODO remove
      print("addWorkout 1");
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
  Future<bool> addMeal(meal meal) async {
    if (currentUserId == null) {
      return false; // Return false if currentUserId is null
    }

    try {
      // Add the meal with an array of references to 'foodItems' sub-collection documents
      var mealRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .add(meal.toMap());

      // If foodItems are provided, add them to the 'foodItems' sub-collection
      for (var foodItem in meal.foodItems) {
        await mealRef.collection('foodItems').add(foodItem.toMap());
      }

      return true; // Return true if the operation was successful
    } catch (e) {
      print('Error adding meal: $e');
      return false; // Return false if there was an error
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
      // Fetch all meals from the 'meals' sub-collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meals')
          .get(options);

      List<meal> mealsList = [];
      for (var doc in querySnapshot.docs) {
        // Fetch foodItems for each meal document from its own 'foodItems' sub-collection
        final foodItemsSnapshot =
            await doc.reference.collection('foodItems').get();
        List<foodItem> foodItems = foodItemsSnapshot.docs
            .map((foodDoc) =>
                foodItem.fromMap(foodDoc.data() as Map<String, dynamic>))
            .toList();

        // Add the meal with its food items to the list
        mealsList.add(meal.fromMap(doc.data() as Map<String, dynamic>));
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
        // Fetch foodItems for each meal document from its own 'foodItems' sub-collection
        final foodItemsSnapshot =
            await doc.reference.collection('foodItems').get();
        List<foodItem> foodItems = foodItemsSnapshot.docs
            .map((foodDoc) =>
                foodItem.fromMap(foodDoc.data() as Map<String, dynamic>))
            .toList();

        // Add the meal with its food items to the list
        mealsList.add(meal.fromMap(doc.data() as Map<String, dynamic>));
      }

      yield mealsList; // Yield the updated list of meals
    }
  }

  Future<Map<String, double>> getTotalMeal({bool onlyToday = true}) async {
    List<meal> mealsList = await getMeal();

    if (mealsList.isEmpty) {
      return {
        "totalCarb": 0.0,
        "totalFat": 0.0,
        "totalProtein": 0.0,
        "totalCal": 0.0,
      };
    }

    double totalCarb = 0.0;
    double totalFat = 0.0;
    double totalProtein = 0.0;
    double totalCal = 0.0;

    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    for (meal currentMeal in mealsList) {
      if (onlyToday) {
        if (currentMeal.time.isAfter(startOfDay) &&
            currentMeal.time.isBefore(endOfDay)) {
          for (var foodItem in currentMeal.foodItems) {
            totalCarb += foodItem.carb;
            totalFat += foodItem.fat;
            totalProtein += foodItem.protein;
            totalCal += foodItem.calorie;
          }
        }
      } else {
        for (var foodItem in currentMeal.foodItems) {
          totalCarb += foodItem.carb;
          totalFat += foodItem.fat;
          totalProtein += foodItem.protein;
          totalCal += foodItem.calorie;
        }
      }
    }

    return {
      "totalCarb": totalCarb,
      "totalFat": totalFat,
      "totalProtein": totalProtein,
      "totalCal": totalCal,
    };
  }

//////////////////
// Add a contact to the Firestore database
  Future<bool> addContact(Contact contact) async {
    if (currentUserId == null) return false; // Return false if user ID is null

    try {
      // Add the contact as a new document in the 'contacts' sub-collection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .add(contact.toMap());
      return true; // Return true if the operation was successful
    } catch (e) {
      print('Error adding contact: $e');
      return false; // Return false if there's an error
    }
  }

// Fetch all contacts from the Firestore database
  Future<List<Contact>> getContacts() async {
    if (currentUserId == null)
      return []; // Return an empty list if user ID is null

    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options =
        hasInternetConnection ? null : GetOptions(source: Source.cache);

    try {
      // Fetch all documents in the 'contacts' sub-collection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .get(options);

      return querySnapshot.docs
          .map((doc) => Contact.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
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
            .map((doc) => Contact.fromMap(doc.data()..['id'] = doc.id))
            .toList();
      } catch (e) {
        print('Error processing contacts stream: $e');
        return <Contact>[];
      }
    });
  }

//////////////////

  Future<dynamic> getUserAttribute(String attribute) async {
    var result = await Connectivity().checkConnectivity();
    bool hasInternetConnection = !result.contains(ConnectivityResult.none);
    var options = null;
    if (!hasInternetConnection) {
      options = GetOptions(source: Source.cache);
    }

    if (currentUserId == null) throw Exception("User not authenticated");

    final snapshot =
        await _firestore.collection('users').doc(currentUserId).get(options);

    if (snapshot.exists) {
      final data = snapshot.data();

      // If the attribute contains a path (e.g., 'cgm_data/periodic/time')
      final attributeParts = attribute.split('/'); // Split the attribute by '/'

      dynamic result = data;

      // Iterate through the path to reach the correct nested field
      for (var part in attributeParts) {
        if (result is Map<String, dynamic> && result.containsKey(part)) {
          result = result[part];
        } else {
          throw Exception("Attribute '$attribute' not found");
        }
      }

      return result;
    } else {
      throw Exception("User data not found");
    }
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
}
