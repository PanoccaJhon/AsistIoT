import '../../features/home/models/light_device.dart';

// Esta es una clase abstracta (un contrato).
// Define QUÉ se puede hacer, pero no CÓMO.
abstract class IotRepository {
  Future<List<LightDevice>> getDevices();
  Future<void> updateLightState(String deviceId, bool isOn);
  // Aquí irían otros métodos: updateAutoMode, etc.
}


// Esta es una implementación FALSA para el desarrollo y pruebas.
// Más tarde, la reemplazarás con una que hable con AWS IoT Core.
class MockIotRepository implements IotRepository {
  // Simula una base de datos en memoria
  final List<LightDevice> _devices = [
    LightDevice(id: 'esp32-01', name: 'Luz del Dormitorio', isOn: false, lightLevel: 50, motionDetected: true),
    LightDevice(id: 'esp32-02', name: 'Luz de la Sala', isOn: true, isAutoMode: false, lightLevel: 400),
    LightDevice(id: 'esp32-03', name: 'Luz del Estudio', isOn: false, lightLevel: 650, motionDetected: false),
  ];

  @override
  Future<List<LightDevice>> getDevices() async {
    // Simula una demora de red
    await Future.delayed(const Duration(seconds: 1));
    return _devices;
  }

  @override
  Future<void> updateLightState(String deviceId, bool isOn) async {
    // Simula una llamada a la API y la actualización del estado
    await Future.delayed(const Duration(milliseconds: 300));
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex != -1) {
      _devices[deviceIndex].isOn = isOn;
      print('Dispositivo $deviceId actualizado a: ${isOn ? "Encendido" : "Apagado"}');
    }
  }
}