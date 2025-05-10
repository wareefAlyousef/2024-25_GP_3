// class GlucoseReading {
//   DateTime time;
//   double reading;
//   String title;
//   String source;

//   GlucoseReading({
//     required this.source,
//     required this.time,
//     required this.reading,
//     required this.title,
//   });

//   factory GlucoseReading.fromMap(Map<dynamic, dynamic> map) {
//     // Handle date parsing more robustly
//     DateTime parseDateTime(String dateStr) {
//       try {
//         // First try direct ISO parsing
//         return DateTime.parse(dateStr);
//       } catch (e) {
//         try {
//           // If that fails, try to format the string properly first
//           // Split the string into date and time parts
//           final parts = dateStr.split('T');
//           if (parts.length != 2) throw FormatException('Invalid date format');
          
//           // Format the date part to ensure proper padding
//           final dateParts = parts[0].split('-');
//           if (dateParts.length != 3) throw FormatException('Invalid date format');
          
//           final year = dateParts[0].padLeft(4, '0');
//           final month = dateParts[1].padLeft(2, '0');
//           final day = dateParts[2].padLeft(2, '0');
          
//           // Reconstruct the properly formatted ISO string
//           final formattedDate = '$year-$month-$day';
//           return DateTime.parse('${formattedDate}T${parts[1]}');
//         } catch (e) {
//           print('Error parsing date: $dateStr');
//           // If all parsing fails, return current time as fallback
//           return DateTime.now();
//         }
//       }
//     }

//     return GlucoseReading(
//       title: map['title'] as String,
//       reading: (map['reading'] as num).toDouble(),
//       time: parseDateTime(map['time'] as String),
//       source: map['source'] as String,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'reading': reading,
//       'time': time.toIso8601String(), // This will ensure proper ISO format when saving
//       'source': source,
//     };
//   }
// }

// class GlucoseReading {
//   String? id;
//   DateTime time;
//   double reading;
//   String title;
//   String source;

//   GlucoseReading({
//     this.id,
//     required this.source,
//     required this.time,
//     required this.reading,
//     required this.title,
//   });

//   factory GlucoseReading.fromMap(Map<dynamic, dynamic> map) {
//     return GlucoseReading(
//       id: map['id'] as String,
//       title: map['title'] as String,
//       reading: (map['reading'] as num).toDouble(),
//       time: DateTime.parse(map['time'] as String),
//       source: map['source'] as String,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'reading': reading,
//       'time': time.toIso8601String(),
//       'source': source,
//     };
//   }
// }

class GlucoseReading {
  String? id;
  DateTime time;
  double reading;
  String title;
  String source;

  GlucoseReading({
    this.id,
    required this.source,
    required this.time,
    required this.reading,
    required this.title,
  });

  factory GlucoseReading.fromMap(Map<dynamic, dynamic> map) {
    return GlucoseReading(
      id: map['id'] as String?, // Allow `id` to be null
      title: map['title'] as String? ?? 'Unknown', // Default to 'Unknown' if null
      reading: (map['reading'] as num?)?.toDouble() ?? 0.0, // Default to 0.0 if null
      time: DateTime.tryParse(map['time'] as String? ?? '') ?? DateTime.now(), // Default to current time if parsing fails
      source: map['source'] as String? ?? 'Unknown', // Default to 'Unknown' if null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'reading': reading,
      'time': time.toIso8601String(),
      'source': source,
    };
  }
}