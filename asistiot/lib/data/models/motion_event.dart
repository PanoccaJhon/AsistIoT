// lib/data/models/motion_event.dart

class MotionEvent {
  final String thingName;
  final int timestamp; // Almacenado como milisegundos desde la época
  final String message;

  MotionEvent({
    required this.thingName,
    required this.timestamp,
    required this.message,
  });

  factory MotionEvent.fromJson(Map<String, dynamic> json) {
    return MotionEvent(
      thingName: json['thingName'] as String,
      timestamp: (json['timestamp'] as int), 
      message: json['mensaje'] as String,
    );
  }
}