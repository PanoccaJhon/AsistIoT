// M: Representa la estructura de datos de un dispositivo de luz.
class LightDevice {
  final String id;
  String name;
  bool isOn;
  bool isAutoMode;
  bool? motionDetected; // Puede ser nulo si no hay datos recientes
  int? lightLevel;      // Nivel de lux

  LightDevice({
    required this.id,
    required this.name,
    this.isOn = false,
    this.isAutoMode = true,
    this.motionDetected,
    this.lightLevel,
  });

  // Aquí podrías añadir métodos fromJson/toJson para la comunicación con la API.
}