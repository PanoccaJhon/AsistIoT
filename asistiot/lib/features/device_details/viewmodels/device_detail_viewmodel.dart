import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../data/models/light_device.dart'; // Asegúrate de que la ruta sea correcta
import '../../../core/services/iot_repository.dart';

class DeviceDetailViewModel extends ChangeNotifier {
  final String deviceId;
  final IotRepository _repository;

  LightDevice? _device;
  LightDevice? get device => _device;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DeviceDetailViewModel({
    required this.deviceId,
    required IotRepository repository,
  }) : _repository = repository {
    // Al crear el ViewModel, inmediatamente busca los detalles del dispositivo.
    _fetchDeviceDetails();
  }

  /// Obtiene el estado más reciente del dispositivo desde el repositorio.
  Future<void> _fetchDeviceDetails() async {
    _isLoading = true;
    notifyListeners();

    try {
      final device = await _repository.getDeviceById(deviceId);
      final state = await _repository.getDeviceState(deviceId);
      // Actualiza el dispositivo con los datos obtenidos
      _device = device.copyWith(
        online: state['online'] ?? false,
        lastSeenTimestamp: state['last_updated'] as int? ?? 0,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cargar los datos del dispositivo: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }