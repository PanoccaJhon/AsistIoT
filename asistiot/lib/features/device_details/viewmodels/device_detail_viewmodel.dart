import 'package:flutter/material.dart';
import '../../../core/services/iot_repository.dart';
import '../../home/models/light_device.dart'; // Reutilizamos el mismo modelo

class DeviceDetailViewModel extends ChangeNotifier {
  final IotRepository _repository;
  final String deviceId;

  DeviceDetailViewModel({required this.deviceId, required IotRepository repository})
      : _repository = repository {
    _loadDeviceDetails();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  LightDevice? _device;
  LightDevice? get device => _device;

  Future<void> _loadDeviceDetails() async {
    _isLoading = true;
    notifyListeners();

    // En una app real, aquí harías una llamada para obtener solo este dispositivo.
    // En nuestro mock, lo buscaremos en la lista completa.
    final allDevices = await _repository.getDevices();
    _device = allDevices.firstWhere((d) => d.id == deviceId);

    _isLoading = false;
    notifyListeners();
  }

  // Ejemplo de otra acción para esta pantalla
  Future<void> toggleAutoMode(bool isEnabled) async {
    if (_device == null) return;
    
    _device!.isAutoMode = isEnabled;
    notifyListeners();

    // Aquí llamarías al repositorio para persistir el cambio
    // await _repository.updateAutoMode(deviceId, isEnabled);
  }
}