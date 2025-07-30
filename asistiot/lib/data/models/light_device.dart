// M: Representa la estructura de datos y el estado de un dispositivo.
class LightDevice {
  final String id;
  final String name;
  final bool online;
  final bool luz1;
  final bool luz2;
  final bool isAutoMode;
  final int? lightLevel;
  final int lastSeenTimestamp;

  LightDevice({
    required this.id,
    required this.name,
    this.luz1 = false,
    this.luz2 = false,
    this.isAutoMode = true,
    this.lightLevel,
    this.online = false,
    this.lastSeenTimestamp = 0,
  });

  /// Constructor de fábrica para crear una instancia de LightDevice desde un JSON.
  /// Se espera que el JSON sea el objeto 'reported' de la sombra del dispositivo.
  factory LightDevice.fromJson(String id, String name, Map<String, dynamic> json) {
    // Extraemos los sub-objetos de forma segura, proveyendo un mapa vacío si no existen.
    final lights = json['estado_luces'] as Map<String, dynamic>? ?? {};
    final sensors = json['sensores'] as Map<String, dynamic>? ?? {};
    final config = json['config'] as Map<String, dynamic>? ?? {};
    
    // El estado 'online' y el 'timestamp' usualmente vienen de la metadata de la sombra,
    // que tu Lambda tendría que añadir a la respuesta. Aquí usamos valores por defecto.
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    final reportedMeta = metadata['reported'] as Map<String, dynamic>? ?? {};

    return LightDevice(
      id: id,
      name: name,
      isAutoMode: config['modo_auto'] ?? true,
      lightLevel: sensors['lux'],
      // Idealmente, tu Lambda también devolvería el estado de conexión.
      online: json['online'] ?? false, 
      lastSeenTimestamp: reportedMeta['timestamp'] as int? ?? 0,
    );
  }

  /// Crea una copia de la instancia actual con los valores actualizados.
  /// Muy útil para la gestión de estado en el ViewModel.
  LightDevice copyWith({
    String? id,
    String? name,
    bool? isOn,
    bool? luz1,
    bool? luz2,
    bool? isAutoMode,
    bool? motionDetected,
    int? lightLevel,
    bool? online,
    int? lastSeenTimestamp,
  }) {
    return LightDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      luz1: luz1 ?? this.luz1,
      luz2: luz2 ?? this.luz2,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      lightLevel: lightLevel ?? this.lightLevel,
      online: online ?? this.online,
      lastSeenTimestamp: lastSeenTimestamp ?? this.lastSeenTimestamp,
    );
  }

  @override
  String toString() {
    return 'LightDevice(id: $id, name: $name, online: $online)';
  }
}