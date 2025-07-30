// lib/data/models/routine.dart
import 'package:hive/hive.dart';

part 'routine.g.dart'; // Importante: esta parte la generará el build_runner

@HiveType(typeId: 0)
class Routine extends HiveObject {
  @HiveField(0)
  late String id;
  
  // --- AÑADE ESTE CAMPO ---
  @HiveField(7)
  late String deviceId;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late int hour; // Guardamos la hora (0-23)

  @HiveField(3)
  late int minute; // Guardamos el minuto (0-59)
  
  @HiveField(4)
  late List<int> days; // Guardamos los días (1=Lunes, 7=Domingo)

  @HiveField(5)
  late String commandPayload; // El JSON del comando a enviar

  @HiveField(6)
  late bool isActive;
  
  // Puedes añadir un campo para el ícono si lo necesitas
  // @HiveField(7)
  // late int iconCodePoint;
}