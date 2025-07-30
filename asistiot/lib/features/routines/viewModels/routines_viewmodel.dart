import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Necesitarás añadir `uuid` a tu pubspec.yaml para generar IDs únicos
import '../../../core/services/routine_local_service.dart'; // Servicio para la base de datos local
import '../../../data/models/routine.dart'; // Modelo de datos de la rutina

class RoutinesViewModel extends ChangeNotifier {
  final RoutineLocalService _localService = RoutineLocalService();
  final Uuid _uuid = const Uuid(); // Generador de IDs únicos

  RoutinesViewModel() {
    // Carga las rutinas en cuanto se crea el ViewModel
    fetchRoutines();
  }

  bool _isLoading = true;
  /// Indica si se están cargando las rutinas.
  bool get isLoading => _isLoading;

  List<Routine> _routines = [];
  /// La lista de rutinas guardadas localmente.
  List<Routine> get routines => _routines;

  /// Carga todas las rutinas desde la base de datos local (Hive).
  Future<void> fetchRoutines() async {
    _isLoading = true;
    notifyListeners();

    _routines = await _localService.getAllRoutines();
    // Ordena las rutinas por hora para una mejor visualización
    _routines.sort((a, b) {
      final timeA = a.hour * 60 + a.minute;
      final timeB = b.hour * 60 + b.minute;
      return timeA.compareTo(timeB);
    });

    _isLoading = false;
    notifyListeners();
  }

  /// Añade una nueva rutina a la base de datos local.
  /// Esta función se llamaría desde una pantalla de "Crear Rutina".
  Future<void> addRoutine({
    required String deviceId,
    required String title,
    required int hour,
    required int minute,
    required List<int> days,
    required String commandPayload,
  }) async {
    final newRoutine = Routine()
      ..id = _uuid.v4() // Genera un ID único para la nueva rutina
      ..deviceId = deviceId
      ..title = title
      ..hour = hour
      ..minute = minute
      ..days = days
      ..commandPayload = commandPayload
      ..isActive = true;

    await _localService.addRoutine(newRoutine);
    // Vuelve a cargar la lista para mostrar la nueva rutina
    await fetchRoutines();
  }

  /// Elimina una rutina de la base de datos local.
  Future<void> deleteRoutine(String routineId) async {
    await _localService.deleteRoutine(routineId);
    // Elimina la rutina de la lista local para una actualización instantánea de la UI
    _routines.removeWhere((routine) => routine.id == routineId);
    notifyListeners();
  }

  /// Activa o desactiva una rutina específica.
  Future<void> toggleRoutineStatus(Routine routine, bool isActive) async {
    // Actualiza el estado del objeto en la lista local para una UI reactiva
    final index = _routines.indexWhere((r) => r.id == routine.id);
    if (index != -1) {
      _routines[index].isActive = isActive;
      
      // Guarda el cambio en la base de datos local
      await _localService.updateRoutine(_routines[index]);
      
      notifyListeners();
    }
  }

  /// Refresca la lista de rutinas, útil para el `RefreshIndicator`.
  Future<void> refresh() async {
    await fetchRoutines();
  }
}