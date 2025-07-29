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
  
  /// Permite refrescar los datos desde la UI (ej. con un pull-to-refresh).
  Future<void> refresh() async {
    await _fetchDeviceDetails();
  }

  /// Envía el comando para encender/apagar una luz.
  Future<void> toggleLight(bool isOn , int luzIndex) async {
    if (_device == null) return;

    final originalState = _device!;
    // Actualización optimista: Cambia el estado en la UI inmediatamente.
    if (luzIndex == 1) {
      _device = _device!.copyWith(luz1: isOn);
    } else if (luzIndex == 2) {
      _device = _device!.copyWith(luz2: isOn);
    }
    notifyListeners();

    try {
      final command = { 'luz1': _device!.luz1 ? 'ON' : 'OFF', 'luz2': _device!.luz2 ? 'ON' : 'OFF'};
      await _repository.sendCommand(deviceId, jsonEncode(command));
    } catch (e) {
      // Si falla, revierte al estado original y muestra el error.
      _device = originalState;
      _errorMessage = 'Fallo al enviar comando de luz.';
      print('Error en toggleLight: $e');
      notifyListeners();
    }
  }
  