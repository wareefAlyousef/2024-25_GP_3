import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String? id;
  final String name;
  final String phoneNumber;
  // final String countryCode;
  final bool sendNotifications;
  final int minThreshold;
  final int maxThreshold;
  DateTime? lastNotified;
  String status;

  Contact({
    this.id, // Make id optional
    required this.name,
    required this.phoneNumber,
    // required this.countryCode,
    required this.sendNotifications,
    required this.minThreshold,
    required this.maxThreshold,
    this.status = 'pending',
    this.lastNotified,
  });

  // /// Convert Firestore document to Contact object
  // factory Contact.fromMap(Map<String, dynamic> map, {String? id}) {
  //   return Contact(
  //     id: map['id'], // Assign Firestore doc ID
  //     name: map['name'] as String,
  //     phoneNumber: map['phoneNumber'] as String,
  //     sendNotifications: map['sendNotifications'] as bool,
  //     minThreshold: map['minThreshold'] as int,
  //     maxThreshold: map['maxThreshold'] as int,
  //     status: map['status'] as String,
  //     lastNotified: map['lastNotified'] != null
  //         ? (map['lastNotified'] as Timestamp).toDate()
  //         : null,
  //   );
  // }

  factory Contact.fromMap(Map<String, dynamic> map, {String? id}) {
    try {
      return Contact(
        id: id ?? map['id'] as String?, // Prefer the explicitly passed ID
        name: map['name']?.toString() ?? '', // Provide default value
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        // countryCode: map['countryCode']?.toString() ?? '',
        sendNotifications: map['sendNotifications'] as bool? ?? false,
        minThreshold: (map['minThreshold'] as num?)?.toInt() ?? 0,
        maxThreshold: (map['maxThreshold'] as num?)?.toInt() ?? 100,
        status: map['status']?.toString() ?? 'pending',
        lastNotified: map['lastNotified'] != null
            ? (map['lastNotified'] as Timestamp).toDate()
            : null,
      );
    } catch (e, stack) {
      print('Error parsing Contact from map: $e');
      print('Map data: $map');
      print('Stack trace: $stack');
      rethrow; // Or return a default contact if preferred
    }
  }

  /// Convert Contact object to a Map
  Map<String, dynamic> toMap() {
    return {
      'name': name, // Don't include 'id' because Firestore manages it
      'phoneNumber': phoneNumber,
      // 'countryCode': countryCode,
      'sendNotifications': sendNotifications,
      'minThreshold': minThreshold,
      'maxThreshold': maxThreshold,
      'status': status,
      'lastNotified':
          lastNotified != null ? Timestamp.fromDate(lastNotified!) : null,
    };
  }
}
