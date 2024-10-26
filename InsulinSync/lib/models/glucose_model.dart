class GlucoseReading {
  DateTime time;
  double reading;
  String title;
  String source;

  GlucoseReading({
    required this.source,
    required this.time,
    required this.reading,
    required this.title,
  });

  factory GlucoseReading.fromMap(Map<dynamic, dynamic> map) {
    return GlucoseReading(
      title: map['title'] as String,
      reading: (map['reading'] as num).toDouble(),
      time: DateTime.parse(map['time'] as String),
      source: map['source'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'reading': reading,
      'time': time.toIso8601String(),
      'source': source,
    };
  }
}
