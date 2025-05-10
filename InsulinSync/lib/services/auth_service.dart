import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _realtimeDatabase = FirebaseDatabase.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isEmailRegistered(String email) async {
    String normalizedEmail = email.trim().toLowerCase();
    try {
      print('Checking if email is registered: $normalizedEmail');
      List<String> signInMethods =
          await _auth.fetchSignInMethodsForEmail(normalizedEmail);
      print('Sign-in methods for $normalizedEmail: $signInMethods');
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email: ${e.toString()}');
      return false;
    }
  }

  // Sign up and store user in Firestore
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required double weight,
    required double height,
    required DateTime dateOfBirth,
    required double dailyBasal,
    required double dailyBolus,
    required bool gender,
    double? carbRatio,
    double? correctionRatio,
  }) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Send email verification
        await user.sendEmailVerification();

        // Store user data in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'email': email.trim().toLowerCase(),
          'weight': weight,
          'height': height,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'gender': gender ? 'Male' : 'Female',
          'dailyBasal': dailyBasal,
          'dailyBolus': dailyBolus,
          'carbRatio': carbRatio,
          'correctionRatio': correctionRatio,
          'maxRange': 180,
          'minRange': 70,
          'recieveNotifications': true,
          'createdAt': Timestamp.now(),
          'isEmailVerified': false, // Track email verification status
        });
      }

      return user;
    } catch (e) {
      print('Error during sign up: $e');
      throw e;
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      return result.user;
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear SharedPreferences before signing out
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('SharedPreferences cleared');
      final dateString = prefs.getString('last_notified');
      print(
          'debug the user notifications:  last_notified after clearing in auth $dateString');

      // Sign out from Firebase
      await _auth.signOut();
      print('Firebase user signed out');
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      print('Password reset email sent');
    } catch (e) {
      print('Error sending password reset email: ${e.toString()}');
      throw e;
    }
  }

  //Verify Current Password
  Future<bool> verifyCurrentPassword(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not logged in");
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        print("Incorrect current password");
        return false;
      } else {
        print("Error verifying password: ${e.toString()}");
        throw Exception("Failed to verify password: ${e.toString()}");
      }
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception("User not logged in");
      }

      // Re-authenticate the user before changing password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      print("Password changed successfully");
    } catch (e) {
      print("Error changing password: ${e.toString()}");
      throw Exception("Failed to change password: ${e.toString()}");
    }
  }

  Future<bool> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      User? user = _auth.currentUser;

      if (user == null) {
        print("No user is currently signed in.");
        return false;
      }

      if (email.trim().toLowerCase() != user.email?.toLowerCase()) {
        print("Email does not match current user.");
        return false;
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim().toLowerCase(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      print("Re-authentication successful.");
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        print("Wrong password.");
        return false;
      } else {
        print("FirebaseAuthException: ${e.code} - ${e.message}");
        throw Exception("Re-authentication failed: ${e.message}");
      }
    } catch (e) {
      print("Unexpected error: ${e.toString()}");
      throw Exception("Unexpected error: ${e.toString()}");
    }
  }

  Future<bool> deleteAccountWithEmailPassword({
    required String email,
    required String password,
  }) async {
    User? user = _auth.currentUser;

    if (user == null) {
      print("No user signed in.");
      return false;
    }

    // Reauthenticate first
    final reauthenticated =
        await reauthenticateUser(email: email, password: password);
    if (!reauthenticated) {
      print("Re-authentication failed.");
      return false;
    }

    try {
      // Delete Firestore data
      await _firestore.collection('users').doc(user.uid).delete();
      print("User Firestore data deleted");

      // Delete Realtime Database data
      await _realtimeDatabase.ref('users/${user.uid}').remove();
      print("User Realtime Database data deleted");

      // Delete Auth account
      await user.delete();
      print("Firebase Auth account deleted");

      // Clear all shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      return true;
    } catch (e) {
      print("Error deleting account: $e");
      throw Exception("Error deleting account: $e");
    }
  }
}
