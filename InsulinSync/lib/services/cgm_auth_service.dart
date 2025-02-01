import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:insulin_sync/services/user_service.dart';

class CGMAuthService {
  String? token;
  String? email;
  String? patientId;
  String? name;
  String? accountId;
  Digest? accountIdSha256Hash;
  List<dynamic> patients = [];
  String? errorMessage;
  int? minRange, maxRange;

  UserService userService = UserService();

  Future<bool> signIn(String email, String password) async {
    final headers = {
      'accept-encoding': 'gzip',
      'Cache-Control': 'no-cache',
      'connection': 'Keep-Alive',
      'content-type': 'application/json',
      'version': '4.12.0',
      'product': 'llu.android',
    };

    final body = jsonEncode({"email": email, "password": password});

    try {
      final response = await http.post(
        Uri.parse('https://api-eu.libreview.io/llu/auth/login'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("cgmAuthService.errorMessag ${responseData['status']}");
        if (responseData['status'] == 429) {
          errorMessage =
              'Your account is locked due to too many failed attempts. Try again in 5 minutes.';
          return false;
        } else if (responseData['status'] == 0) {
          token = responseData['data']['authTicket']['token'];
          this.email = email;
          accountId = responseData['data']['user']['id'];
          // Convert the input to a list of bytes
          List<int> bytes = utf8.encode(accountId!);

          // Compute the SHA-256 hash
          accountIdSha256Hash = sha256.convert(bytes);

          errorMessage = null; // Clear error message
          return true; // Sign-in successful
        } else {
          errorMessage = 'Incorrect email or password.';
          return false; // Sign-in failed
        }
      } else {
        errorMessage = 'Something went wrong. Please try again.';
        return false; // Sign-in failed due to server error
      }
    } catch (e) {
      errorMessage = 'Failed to connect. Check your internet connection.';
      return false; // Sign-in failed due to connection issue
    }
  }

  Future<bool> logout() async {
    try {
      await userService.removeUserAttributes(
          removeToken: true,
          removePatientId: true,
          removeLibreEmail: true,
          removeLibreName: true,
          removeLibreAccountId: true,
          removeCgmData: true);
      await userService.removeGlucoseReadings(source: 'libreCGM');
      return true;
    } catch (e) {
      errorMessage = 'Failed to connect. Check your internet connection.';
      return false; // logout failed due to connection issue
    }
  }

  Future<List<dynamic>> fetchPatients() async {
    if (token == null) {
      errorMessage = 'Please sign in first.';
      return []; // Return an empty list if token is null
    }

    final headers = {
      'accept-encoding': 'gzip',
      'Cache-Control': 'no-cache',
      'connection': 'Keep-Alive',
      'content-type': 'application/json',
      'version': '4.12.0',
      'product': 'llu.android',
      'authorization': 'Bearer $token',
      'Account-Id': '$accountIdSha256Hash'
    };

    try {
      final response = await http.get(
        Uri.parse('https://api-eu.libreview.io/llu/connections'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 0) {
          return responseData['data']; // Return the list of patients
        } else {
          errorMessage = 'Failed to fetch patient data.';
          return []; // Return an empty list if the status is not 0
        }
      } else {
        errorMessage = 'Error: ${response.statusCode}';
        return []; // Return an empty list if there is an error with the request
      }
    } catch (e) {
      errorMessage =
          'Failed to fetch patients. Please check your internet connection.';
      return []; // Return an empty list in case of an exception
    }
  }

  void setPatientId(String patientId) {
    this.patientId = patientId;
  }

  void setName(String fullName) {
    this.name = fullName;
  }

  void setMinRange(int minRange) {
    this.minRange = minRange;
  }

  void setMaxRange(int maxRange) {
    this.maxRange = maxRange;
  }

  Future<bool> setAttributes(Map<String, dynamic> data) async {
    try {
      // Set patientId
      if (data.containsKey('patientId')) {
        setPatientId(data['patientId'] as String);
      }

      // set name
      if (data.containsKey('firstName') && data.containsKey('lastName')) {
        final String fullName = '${data['firstName']} ${data['lastName']}';
        setName(fullName);
      }

      // Set minRange
      if (data.containsKey('targetLow')) {
        setMinRange(data['targetLow'] as int);
      }

      // Set maxRange
      if (data.containsKey('targetHigh')) {
        setMaxRange(data['targetHigh'] as int);
      }

      bool success = await userService.updateUserAttributes(
          libreEmail: email,
          libreName: name,
          token: token,
          patientId: patientId,
          libreAccountId: '$accountIdSha256Hash',
          minRange: minRange,
          maxRange: maxRange);

      return success;
    } catch (e) {
      return false;
    }
  }
}
