import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/carbohydrate_model.dart';
import '../models/user_model.dart';
import '../models/glucose_model.dart';
import '../models/insulin_model.dart';
import '../models/note_model.dart';
import '../models/workout_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String? currentUserId;

  UserService() {
    currentUserId = _auth.currentUser?.uid;
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

  Future<List<GlucoseReading>> getGlucoseReadings() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      final DatabaseEvent event =
          await _database.child('users/$currentUserId/glucose_readings').once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final readingsList = snapshot.children
            .map((childSnapshot) => GlucoseReading.fromMap(
                childSnapshot.value as Map<dynamic, dynamic>))
            .toList();
        return readingsList;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching glucose readings: $e');
      return [];
    }
  }

  Stream<List<GlucoseReading>> getGlucoseReadingsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _database
        .child('users/$currentUserId/glucose_readings')
        .onValue
        .map((event) {
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

  ///////////////////////

  Future<bool> addNote(Note note) async {
    // Check if the currentUserId is null
    if (currentUserId == null) {
      return false; // Return false if user is not authenticated
    }

    try {
      // Attempt to update the user's notes in Firestore
      await _firestore.collection('users').doc(currentUserId).update({
        'notes': FieldValue.arrayUnion([note.toMap()]),
      });
      return true; // Return true if the addition is successful
    } catch (e) {
      // Log the error or handle it as needed
      print('Error adding note: $e');
      return false; // Return false if there was an error
    }
  }

  Future<List<Note>> getNotes() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('notes')) {
        List<dynamic> notes = snapshot['notes'] ?? [];
        return notes.map((map) => Note.fromMap(map)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  Stream<List<Note>> getNotesStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list when there's no user
      return Stream.value(<Note>[]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      try {
        // Attempt to get data from the snapshot
        final data = snapshot.data();

        // If 'notes' field is missing or not a List, return an empty list
        if (data == null || data['notes'] == null || data['notes'] is! List) {
          return <Note>[];
        }

        // Safely map the 'notes' field to a list of Note objects
        List<dynamic> notes = data['notes'];
        return notes
            .map((map) => Note.fromMap(map as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If any error occurs, return an empty list
        return <Note>[];
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
    if (currentUserId == null)
      return false; // Return false if currentUserId is null
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'insulin_dosages': FieldValue.arrayUnion([dosage.toMap()]),
      });
      return true; // Return true if the operation was successful
    } catch (e) {
      // Handle the error if needed (e.g., logging)
      print('Error adding insulin dosage: $e');
      return false; // Return false if there was an error
    }
  }

  Future<List<InsulinDosage>> getInsulinDosages() async {
    if (currentUserId == null) {
      return [];
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!snapshot.exists ||
          snapshot.data() == null ||
          !snapshot.data()!.containsKey('insulin_dosages')) {
        return [];
      }

      List<dynamic> insulinDosages = snapshot['insulin_dosages'] ?? [];
      return insulinDosages.map((map) => InsulinDosage.fromMap(map)).toList();
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

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      try {
        // Attempt to get data from the snapshot
        final data = snapshot.data();

        // If 'notes' field is missing or not a List, return an empty list
        if (data == null ||
            data['insulin_dosages'] == null ||
            data['insulin_dosages'] is! List) {
          return <InsulinDosage>[];
        }

        // Safely map the 'notes' field to a list of Note objects
        List<dynamic> dosages = data['insulin_dosages'];
        return dosages
            .map((map) => InsulinDosage.fromMap(map as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If any error occurs, return an empty list
        return <InsulinDosage>[];
      }
    });
  }

  Future<void> updateInsulinDosage({
    required String dosageId,
    String? newType,
    double? newDosage,
    DateTime? newTime,

    // TODO how to actually deal with this? can it be changed? note that it must be reflected in the glucose array to solve any potential conflict
    GlucoseReading? newGlucoseAtTime,
  }) async {
    if (currentUserId == null) return;

    final Map<String, dynamic> updates = {};

    if (newType != null) {
      updates['type'] = newType;
    }
    if (newDosage != null) {
      updates['dosage'] = newDosage;
    }
    if (newTime != null) {
      updates['time'] = newTime.toIso8601String();
    }
    if (newGlucoseAtTime != null) {
      updates['glucoseAtTime'] = newGlucoseAtTime.toMap();
    }

    if (updates.isNotEmpty) {
      await _database
          .child('users/$currentUserId/insulin_dosages/$dosageId')
          .update(updates);
    }
  }

  Future<double> getTotalDosages(String type) async {
    List<InsulinDosage> insulinList = await getInsulinDosages();

    if (insulinList.isEmpty) {
      return 0.0;
    }

    double dosages = 0.0;

    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    for (InsulinDosage dosage in insulinList) {
      if (dosage.time.isAfter(startOfDay) && dosage.time.isBefore(endOfDay)) {
        if (dosage.type.toLowerCase() == type.toLowerCase())
          dosages += dosage.dosage;
      }
    }

    return dosages;
  }

  //////////////////

  Future<bool> addWorkout(Workout workout) async {
    if (currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'workouts': FieldValue.arrayUnion([workout.toMap()]),
      });
      return true; // Return true if the update is successful
    } catch (e) {
      print('Error adding workout: $e');
      return false; // Return false if there's an error
    }
  }

  Future<List<Workout>> getWorkouts() async {
    if (currentUserId == null) {
      // Return an empty list if currentUserId is null
      return [];
    }

    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      List<dynamic> workouts = snapshot.data()?['workouts'] ?? [];

      return workouts.map((map) => Workout.fromMap(map)).toList();
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

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      try {
        // Attempt to get data from the snapshot
        final data = snapshot.data();

        // If 'notes' field is missing or not a List, return an empty list
        if (data == null ||
            data['workouts'] == null ||
            data['workouts'] is! List) {
          // TODO remove
          print('in line 378 getworkoutstream');
          return <Workout>[];
        }

        // Safely map the 'notes' field to a list of Note objects
        List<dynamic> workouts = data['workouts'];
        return workouts
            .map((map) => Workout.fromMap(map as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If any error occurs, return an empty list
        return <Workout>[];
      }
    });
  }

//////////////////

  Future<bool> addCarbohydrate(Carbohydrate carbohydrate) async {
    if (currentUserId == null) return false; // Return false if user ID is null

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'carbohydrates': FieldValue.arrayUnion([carbohydrate.toMap()]),
      });
      return true; // Return true if the update is successful
    } catch (e) {
      print('Error adding carbohydrate: $e');
      return false; // Return false if there's an error
    }
  }

  Future<List<Carbohydrate>> getCarbohydrates() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('users').doc(currentUserId).get();

    if (!snapshot.exists || !snapshot.data()!.containsKey('carbohydrates')) {
      return [];
    }

    List<dynamic> carbohydrates = snapshot['carbohydrates'] ?? [];
    return carbohydrates.map((map) => Carbohydrate.fromMap(map)).toList();
  }

  Stream<List<Carbohydrate>> getCarbohydratesStream() {
    if (currentUserId == null) {
      // Return a stream that emits an empty list when there's no user
      return Stream.value(<Carbohydrate>[]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      try {
        // Attempt to get data from the snapshot
        final data = snapshot.data();

        // If 'notes' field is missing or not a List, return an empty list
        if (data == null ||
            data['carbohydrates'] == null ||
            data['carbohydrates'] is! List) {
          return <Carbohydrate>[];
        }

        // Safely map the 'notes' field to a list of Note objects
        List<dynamic> carbs = data['carbohydrates'];
        return carbs
            .map((map) => Carbohydrate.fromMap(map as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // If any error occurs, return an empty list
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

  Future<dynamic> getUserAttribute(String attribute) async {
    if (currentUserId == null) throw Exception("User not authenticated");
    final snapshot =
        await _firestore.collection('users').doc(currentUserId).get();

    print('getUserAttribute line 490');

    if (snapshot.exists) {
      final data = snapshot.data();
      print('getUserAttribute ${data?[attribute]}');
      return data?[attribute];
    } else {
      print('getUserAttribute line 492');
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

  Future<void> updateUserAttributes({
    double? weight,
    double? height,
    bool? gender,
    double? dailyBolus,
    double? dailyBasal,
    double? carbRatio,
    double? correctionRatio,
  }) async {
    if (currentUserId == null) return;
    final Map<String, dynamic> updates = {};

    if (weight != null) updates['weight'] = weight;
    if (height != null) updates['height'] = height;
    if (gender != null) updates['gender'] = gender;
    if (dailyBolus != null) updates['dailyBolus'] = dailyBolus;
    if (dailyBasal != null) updates['dailyBasal'] = dailyBasal;
    if (carbRatio != null) updates['carbRatio'] = carbRatio;
    if (correctionRatio != null) updates['correctionRatio'] = correctionRatio;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(currentUserId).update(updates);
    }
  }
}

//////////////////
