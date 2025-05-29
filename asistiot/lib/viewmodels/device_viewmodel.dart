import 'package:flutter/foundation.dart';

import '../models/device_model.dart';

class DeviceViewModel extends ChangeNotifier {
  List<Device> _devices = [];
  bool _isLoading = false;
  bool _hasError = false;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> loadDevices() async {
    _isLoading = true;
    _hasError = false;
    _devices = [];
    notifyListeners();

    try {
      // Aquí iría la lógica real para buscar dispositivos IoT por WiFi.
      // Por simplicidad, simulamos con un delay y datos de prueba.
      await Future.delayed(Duration(seconds: 2));

      // Simulamos dispositivos encontrados
      _devices = [
        Device(name: "Lámpara Sala", ip: "192.168.1.10"),
        Device(name: "Puerta Principal", ip: "192.168.1.12"),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      notifyListeners();
    }
  }
}
