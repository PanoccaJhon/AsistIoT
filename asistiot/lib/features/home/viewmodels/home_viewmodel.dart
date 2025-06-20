import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart'; // <-- NUEVO: Para el tipo de dato AuthUser

import '../../../core/services/iot_repository.dart';
import '../../../core/services/auth_service.dart'; // <-- NUEVO: Importar el servicio de Auth
import '../models/light_device.dart';

class HomeViewModel extends ChangeNotifier {
  final IotRepository _repository;
  final AuthService _authService; // <-- NUEVO: Dependencia del servicio de Auth

  HomeViewModel({
    required IotRepository repository,
    required AuthService authService, // <-- MODIFICADO: Recibir AuthService en el constructor
  })  : _repository = repository,
        _authService = authService;

  // --- ESTADO ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<LightDevice> _devices = [];
  List<LightDevice> get devices => List.unmodifiable(_devices);

  // --- NUEVO: Estado para la información del usuario ---
  String? _userDisplayName;
  String? get userDisplayName => _userDisplayName;
  // ---------------------------------------------------

  // --- LÓGICA / ACCIONES ---

  // NUEVO: Orquesta la carga de datos inicial cuando la pantalla aparece
  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    // Cargamos el usuario y los dispositivos en paralelo para más eficiencia
    await Future.wait([
      _loadCurrentUser(),
      fetchDevices(),
    ]);
    
    _isLoading = false;
    notifyListeners();
  }
  
  // NUEVO: Método privado para obtener los datos del usuario logueado
  Future<void> _loadCurrentUser() async {
  try {
    // 1. Usamos fetchUserAttributes() que nos devuelve una lista de todos los atributos.
    final attributes = await Amplify.Auth.fetchUserAttributes();

    // 2. Buscamos en la lista el atributo que corresponde al 'name'.
    final nameAttribute = attributes.firstWhere(
      (element) => element.userAttributeKey == AuthUserAttributeKey.name,
      // 3. Si por alguna razón no encontramos el 'name', buscamos el 'email' como alternativa.
      orElse: () => attributes.firstWhere(
        (element) => element.userAttributeKey == AuthUserAttributeKey.email,
        // 4. Si tampoco hay email, usamos un valor por defecto.
        orElse: () => const AuthUserAttribute(
          userAttributeKey: AuthUserAttributeKey.name,
          value: 'Usuario Desconocido',
        ),
      ),
    );
    
    // 5. Asignamos el valor encontrado a nuestra variable de estado.
    _userDisplayName = nameAttribute.value;

  } on Exception catch (e) {
    print("Error cargando atributos del usuario: $e");
    _userDisplayName = "Usuario"; // Un valor por defecto en caso de cualquier error
  }
  
  // No necesitamos llamar a notifyListeners() aquí si lo hacemos en loadInitialData()
}

  // MODIFICADO: Ahora es parte de loadInitialData, pero se mantiene por si se necesita recargar solo los devices.
  Future<void> fetchDevices() async {
    // TODO: En el futuro, esta función debería recibir el ID del usuario para
    //       obtener solo los dispositivos que le pertenecen.
    _devices = await _repository.getDevices();
    // Ya no se notifica aquí para evitar múltiples rebuilds. loadInitialData se encarga.
  }

  // NUEVO: Método para que la vista pueda llamar al cierre de sesión
  Future<void> signOut() async {
    await _authService.signOut();
    // No es necesario notificar listeners, el AuthWrapper se encargará del cambio de pantalla.
  }

  Future<void> toggleLight(String deviceId) async {
    final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
    if (deviceIndex == -1) return;

    final device = _devices[deviceIndex];
    final newStatus = !device.isOn;

    _devices[deviceIndex].isOn = newStatus;
    notifyListeners();

    try {
      await _repository.updateLightState(deviceId, newStatus);
    } catch (e) {
      _devices[deviceIndex].isOn = !newStatus;
      notifyListeners();
    }
  }

  void processVoiceCommand(String command) {
    print("Comando de voz recibido: $command");
    if (command.toLowerCase().contains('encender') && command.toLowerCase().contains('dormitorio')) {
      toggleLight('esp32-01');
    } else if (command.toLowerCase().contains('apagar') && command.toLowerCase().contains('dormitorio')) {
      final device = _devices.firstWhere((d) => d.id == 'esp32-01', orElse: () => LightDevice(id: 'none', name: 'none'));
      if (device.isOn) {
        toggleLight('esp32-01');
      }
    }
  }
}