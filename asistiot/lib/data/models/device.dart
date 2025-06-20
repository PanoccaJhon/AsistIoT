class Device {
  final String thingName;
  final String displayName;
  // Puedes añadir más atributos aquí si los necesitas

  Device({required this.thingName, required this.displayName});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      thingName: json['thingName'] as String,
      displayName: json['attributes']['displayName'] ?? json['thingName'], // Usa un nombre amigable si existe
    );
  }
}