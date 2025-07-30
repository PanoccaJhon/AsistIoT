import 'package:asistiot_project/core/services/api_service.dart';
import '../../data/models/light_device.dart';
import '../../data/models/motion_event.dart';

/// La abstracción del repositorio. Define el contrato de lo que la app
/// puede hacer con los datos de IoT, sin saber cómo se hace.
abstract class IotRepository {
  /// Obtiene la lista de todos los dispositivos asociados al usuario.
  Future<List<LightDevice>> getDevices();

  Future<LightDevice> getDeviceById(String deviceId);

  /// Obtiene el estado más reciente (sombra) de un único dispositivo.
  Future<Map<String, dynamic>> getDeviceState(String deviceId);
  
  /// Envía un comando genérico en formato JSON a un dispositivo.
  Future<void> sendCommand(String deviceId, String commandPayload);

  /// Desvincula un dispositivo de la cuenta del usuario.
  Future<void> unlinkDevice(String deviceId);

  /// Obtiene el historial de eventos de movimiento para un dispositivo específico.
  Future<List<MotionEvent>> getMotionHistory(String thingName);
}


/// La implementación concreta del repositorio que usa una API (ApiService).
class ApiIotRepository implements IotRepository {
  final ApiService _apiService;

  ApiIotRepository({required ApiService apiService}) : _apiService = apiService;

  @override
  Future<LightDevice> getDeviceById(String deviceId) async {
    final deviceData = await _apiService.getDeviceById(deviceId);
    
    final device = LightDevice(
      id: deviceData['thingName'],
      name: deviceData['thingName'],
      luz1: deviceData['luz1_estado'] == 'ON',
      luz2: deviceData['luz2_estado'] == 'ON',
      isAutoMode: deviceData['modo_auto'] ?? true,
      lightLevel: deviceData['lux'],
      lastSeenTimestamp: deviceData['timestamp'] as int? ?? 0,
    );
    return device;
  }

  @override
  Future<List<LightDevice>> getDevices() async {
    final devicesData = await _apiService.listDevices();
    // Aquí se podrían combinar los datos de la lista con su estado si fuera necesario
    return devicesData
        .map((d) => LightDevice(
          id: d['thingName'], 
          name: d['thingName'], 
          online: d['online'],
          luz1: d['luz1'] == 'ON',
          luz2: d['luz2'] == 'ON',
          ))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getDeviceState(String deviceId) {
    // Llama a la API para obtener el estado (sombra) de un dispositivo.
    return _apiService.getDeviceState(deviceId);
  }
  
  @override
  Future<void> sendCommand(String deviceId, String commandPayload) {
    // Llama a la API para enviar un comando POST al dispositivo.
    return _apiService.sendCommand(deviceId, commandPayload);
  }

  @override
  Future<void> unlinkDevice(String deviceId) {
    // Llama a la API para desvincular el dispositivo (DELETE).
    return _apiService.unlinkDevice(deviceId);
  }

  @override
  Future<List<MotionEvent>> getMotionHistory(String thingName) async {
    // Llama a la API para obtener el historial de eventos de movimiento.
    final eventsData = await _apiService.getMotionHistory(thingName);

    return eventsData;
  }
}