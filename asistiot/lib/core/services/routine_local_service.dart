// lib/core/services/routine_local_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/routine.dart';

class RoutineLocalService {
  static const String _boxName = 'routinesBox';

  Future<Box<Routine>> _openBox() async {
    return await Hive.openBox<Routine>(_boxName);
  }

  Future<void> addRoutine(Routine routine) async {
    final box = await _openBox();
    await box.put(routine.id, routine);
  }

  Future<void> deleteRoutine(String routineId) async {
    final box = await _openBox();
    await box.delete(routineId);
  }

  Future<void> updateRoutine(Routine routine) async {
    await routine.save(); // HiveObject permite guardar directamente
  }

  Future<List<Routine>> getAllRoutines() async {
    final box = await _openBox();
    return box.values.toList();
  }
}