import 'dart:async';
import 'dart:convert';
import 'package:asistiot_project/core/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

// Enum para manejar los estados de la UI de forma clara
enum AddDeviceStatus { idle, scanning, noResults, resultsFound, connecting, connected, error }

class AddDeviceViewModel extends ChangeNotifier {
  // --- UUIDs (deben coincidir con el ESP32) ---
  final Guid _serviceUuid = Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
  final Guid _characteristicUuid = Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8");

  // --- Estado de la UI ---
  AddDeviceStatus _status = AddDeviceStatus.idle;
  AddDeviceStatus get status => _status;

  String _errorMessage = "";
  String get errorMessage => _errorMessage;

  // --- Estado de BLE ---
  Stream<List<ScanResult>> get scanResultsStream => FlutterBluePlus.scanResults;
  BluetoothDevice? _selectedDevice;
  BluetoothDevice? get selectedDevice => _selectedDevice;

  // --- Controladores de Texto ---
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  AddDeviceViewModel() {
    // Escuchar si el usuario apaga o enciende el Bluetooth del teléfono
    FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        _status = AddDeviceStatus.error;
        _errorMessage = "Por favor, enciende el Bluetooth para continuar.";
        notifyListeners();
      } else {
        if (_status == AddDeviceStatus.error) {
          _status = AddDeviceStatus.idle;
          notifyListeners();
        }
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

  Future<bool> sendWifiCredentials(BuildContext context) async {
    if (_selectedDevice == null || _status != AddDeviceStatus.connected) return false;

    _status = AddDeviceStatus.connecting; // Reusamos el estado "connecting" para mostrar un loader
    notifyListeners();

    try {
      List<BluetoothService> services = await _selectedDevice!.discoverServices();
      final targetService = services.firstWhere((s) => s.uuid == _serviceUuid);
      final targetCharacteristic = targetService.characteristics.firstWhere((c) => c.uuid == _characteristicUuid);
      
      final credentials = {"ssid": ssidController.text, "pass": passwordController.text};
      final dataToSend = utf8.encode(jsonEncode(credentials));

      await targetCharacteristic.write(dataToSend);
      final thingName = _selectedDevice!.platformName;
      await _selectedDevice!.disconnect();
      _selectedDevice = null;

      final apiService = context.read()<ApiService>();
      final success = await apiService.associateDevice(thingName);

      //_isConnecting = false;
      notifyListeners();
      return success;
    } catch (e) {
      print("ERROR AL ENVIAR CREDENCIALES: $e");
      _errorMessage = "Fallo al enviar datos. El dispositivo puede haberse desconectado.";
      _status = AddDeviceStatus.error;
      return false;
    } finally {
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}