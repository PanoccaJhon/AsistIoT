import 'package:asistiot_project/core/services/api_service.dart';
import '../../features/home/models/light_device.dart'; // Mantendremos este por ahora
import '../../data/models/device.dart'; // El nuevo modelo

abstract class IotRepository {
  Future<List<LightDevice>> getDevices(); // Cambiaremos esto en el futuro
  Future<void> updateLightState(String thingName, bool isOn);
}

class ApiIotRepository implements IotRepository {
  final ApiService _apiService;

  ApiIotRepository({required ApiService apiService}) : _apiService = apiService;

  @override
  Future<List<LightDevice>> getDevices() async {
    final devices = await _apiService.listDevices();
    // Convertimos nuestro modelo de red a nuestro modelo de UI
    // Esto es temporal, en el futuro tu modelo de UI sería más rico
    return devices.map((d) => LightDevice(id: d.thingName, name: d.displayName)).toList();
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