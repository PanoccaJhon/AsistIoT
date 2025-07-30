import 'dart:async';
import 'dart:convert';
import 'package:asistiot_project/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// MODIFICADO: Añadimos nuevos estados para el flujo.
enum AddDeviceStatus {
  idle,
  scanning,
  noResults,
  resultsFound,
  connecting,
  connected,
  sendingCredentials,
  credentialsSent,
  restarting,
  error
}

class AddDeviceViewModel extends ChangeNotifier {
  // --- Dependencias ---
  // AÑADIDO: Se inyecta el ApiService para no depender del context.
  final ApiService _apiService;

  // --- UUIDs ---
  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  // --- Estado ---
  AddDeviceStatus _status = AddDeviceStatus.idle;
  AddDeviceStatus get status => _status;

  String _errorMessage = "";
  String get errorMessage => _errorMessage;

  BluetoothDevice? _selectedDevice;
  BluetoothDevice? get selectedDevice => _selectedDevice;

  Stream<List<ScanResult>> get scanResultsStream => FlutterBluePlus.scanResults;

  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // MODIFICADO: El constructor ahora recibe sus dependencias.
  AddDeviceViewModel({required ApiService apiService}) : _apiService = apiService {
    FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        _updateStatus(AddDeviceStatus.error, error: "Por favor, enciende el Bluetooth.");
      } else {
        if (_status == AddDeviceStatus.error) _updateStatus(AddDeviceStatus.idle);
      }
    });
  }

  Future<void> startScan() async {
    // No escanear si ya lo está haciendo
    if (_status == AddDeviceStatus.scanning) return;

    _status = AddDeviceStatus.scanning;
    notifyListeners();

    try {
      // Escanear por 5 segundos. La lista se actualizará gracias al Stream.
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      
      // Esperar a que el escaneo termine
      await FlutterBluePlus.isScanning.where((val) => val == false).first;

      // Comprobar si hay resultados después de escanear
      final results = await FlutterBluePlus.scanResults.first;
      if (results.where((r) => r.device.platformName.isNotEmpty).isEmpty) {
        _status = AddDeviceStatus.noResults;
      } else {
        _status = AddDeviceStatus.resultsFound;
      }
    } catch(e) {
      _status = AddDeviceStatus.error;
      _errorMessage = "Error al escanear: $e";
    } finally {
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _status = AddDeviceStatus.connecting;
    _selectedDevice = device;
    notifyListeners();
    
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _status = AddDeviceStatus.connected;
    } catch(e) {
      print("ERROR AL CONECTAR: $e");
      _status = AddDeviceStatus.error;
      _errorMessage = "No se pudo conectar al dispositivo. Inténtalo de nuevo.";
      _selectedDevice = null;
    } finally {
      notifyListeners();
    }
  }


  /// MODIFICADO: Ahora solo envía las credenciales y cambia de estado.
  Future<void> sendWifiCredentials() async {
    if (_selectedDevice == null) return;

    _updateStatus(AddDeviceStatus.sendingCredentials);

    try {
      List<BluetoothService> services = await _selectedDevice!.discoverServices();
      final characteristic = _findCharacteristic(services);
      
      final credentials = {"ssid": ssidController.text, "pass": passwordController.text};
      final dataToSend = utf8.encode(jsonEncode(credentials));

      await characteristic.write(dataToSend);
      _updateStatus(AddDeviceStatus.credentialsSent);

    } catch (e) {
      _updateStatus(AddDeviceStatus.error, error: "Fallo al enviar credenciales.");
      print("ERROR AL ENVIAR CREDENCIALES: $e");
    }
  }

  /// NUEVO: Envía el comando de reinicio, desconecta y asocia el dispositivo.
  Future<bool> sendRestartCommand() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_selectedDevice == null) return false;

    _updateStatus(AddDeviceStatus.restarting);

    try {
      List<BluetoothService> services = await _selectedDevice!.discoverServices();
      final characteristic = _findCharacteristic(services);
      
      final command = {"action": "restart"};
      final dataToSend = utf8.encode(jsonEncode(command));
      print("Enviando comando de reinicio 1: $dataToSend");
      await characteristic.write(dataToSend);
      print("Comando de reinicio enviado 2: $dataToSend");
      // La asociación ocurre después de enviar el comando de reinicio
      final thingName = _selectedDevice!.platformName;
      if (thingName.isEmpty) {
        _updateStatus(AddDeviceStatus.error, error: "El nombre del dispositivo no está disponible.");
        return false;
      }
      final success = await _apiService.associateDevice(thingName);
      print("Asociación del dispositivo: $success");
      // Desconectamos el dispositivo del teléfono al final del proceso
      await _selectedDevice!.disconnect();
      _selectedDevice = null;
      print("Dispositivo desconectado correctamente.");
      return success;

    } catch (e) {
      _updateStatus(AddDeviceStatus.error, error: "Fallo al reiniciar el dispositivo.\n $e");
      print("ERROR AL REINICIAR: $e");
      return false;
    }
  }

  // --- Métodos de ayuda ---
  
  BluetoothCharacteristic _findCharacteristic(List<BluetoothService> services) {
    final targetService = services.firstWhere((s) => s.uuid == _serviceUuid);
    return targetService.characteristics.firstWhere((c) => c.uuid == _characteristicUuid);
  }
  
  void _updateStatus(AddDeviceStatus newStatus, {String error = ""}) {
    _status = newStatus;
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    _selectedDevice?.disconnect(); // Asegura la desconexión
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}