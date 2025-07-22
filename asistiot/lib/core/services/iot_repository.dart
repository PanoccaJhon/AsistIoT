import 'dart:convert';
import 'package:asistiot_project/core/services/api_service.dart';
import '../../data/models/light_device.dart'; // El nuevo modelo

/// La abstracción del repositorio. Define el contrato de lo que la app
/// puede hacer con los datos de IoT, sin saber cómo se hace.
abstract class IotRepository {
  /// Obtiene la lista de todos los dispositivos asociados al usuario.
  Future<List<LightDevice>> getDevices();

  /// Obtiene el estado más reciente (sombra) de un único dispositivo.
  Future<Map<String, dynamic>> getDeviceState(String deviceId);

  /// Envía un comando genérico en formato JSON a un dispositivo.
  Future<void> sendCommand(String deviceId, String commandPayload);

  /// Desvincula un dispositivo de la cuenta del usuario.
  Future<void> unlinkDevice(String deviceId);
}

class ApiIotRepository implements IotRepository {
  final ApiService _apiService;

  ApiIotRepository({required ApiService apiService}) : _apiService = apiService;

  @override
  Future<List<LightDevice>> getDevices() async {
    final devices = await _apiService.listDevices();
    // Convertimos nuestro modelo de red a nuestro modelo de UI
    // Esto es temporal, en el futuro tu modelo de UI sería más rico
    return devices
        .map((d) => LightDevice(id: d.thingName, name: d.displayName))
        .toList();
  }

  @override
  Future<void> updateLightState(String thingName, bool isOn) async {
    await _apiService.sendCommand(
      thingName,
      component: 'luz1',
      value: isOn ? 'ON' : 'OFF',
    );
  }
}
