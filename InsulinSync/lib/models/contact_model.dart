class Contact {
  final String name;
  final String phoneNumber;
  final bool sendNotifications;

  Contact({
    required this.name,
    required this.phoneNumber,
    required this.sendNotifications,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      sendNotifications: map['sendNotifications'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'sendNotifications': sendNotifications,
    };
  }
}
