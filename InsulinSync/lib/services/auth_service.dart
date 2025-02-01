import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<bool> isEmailRegistered(String email) async {
    String normalizedEmail = email.trim().toLowerCase();
    try {
      print('Checking if email is registered: $normalizedEmail');
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(normalizedEmail);
      print('Sign-in methods for $normalizedEmail: $signInMethods');
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email: ${e.toString()}');
      return false;
    }
  }

  // // Sign up and store user in Firestore
  // Future<User?> signUpWithEmail({
  //   required String email,
  //   required String password,
  //   required String firstName,
  //   required String lastName,
  //   required double weight,
  //   required double height,
  //   required DateTime dateOfBirth,
  //   required double dailyBasal,
  //   required double dailyBolus,
  //   required bool gender, 
  //   double? carbRatio,
  //   double? correctionRatio,
  // }) async {
  //   try {
      
  //     UserCredential result = await _auth.createUserWithEmailAndPassword(
  //       email: email.trim().toLowerCase(),
  //       password: password,
  //     );
  //     User? user = result.user;

  //     await _firestore.collection('users').doc(user?.uid).set({
  //       'firstName': firstName,
  //       'lastName': lastName,
  //       'email': email.trim().toLowerCase(),
  //       'weight': weight,
  //       'height': height,
  //       'dateOfBirth': dateOfBirth.toIso8601String(),
  //       'gender':
  //           gender ? 'Male' : 'Female', 
  //       'dailyBasal': dailyBasal,
  //       'dailyBolus': dailyBolus,
  //       'carbRatio': carbRatio,
  //       'correctionRatio': correctionRatio,
  //       'createdAt': Timestamp.now(),
  //     });

  //     return user;
  //   } catch (e) {
  //     print('Error during sign up: $e');
  //     throw e;
  //   }
  // }

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
      return await _auth.signOut();
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

}
