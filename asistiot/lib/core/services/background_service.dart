import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';

// Importa tus modelos y el ApiService
import '../../data/models/routine.dart';
import 'routine_local_service.dart';
import 'api_service.dart'; // Usa ApiService directamente
import '../../../config/amplifyconfiguration.dart';

// --- PUNTO DE ENTRADA PARA EL SERVICIO EN SEGUNDO PLANO ---
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 1. Asegura la inicialización de plugins
  DartPluginRegistrant.ensureInitialized();

  // 2. Configura los servicios necesarios DENTRO del isolate
  await _configureBackgroundServices();
  
  // 3. Instancia los servicios que usaremos
  final routineService = RoutineLocalService();
  final apiService = ApiService(); // <<< CAMBIO: Instanciamos ApiService directamente

  // 4. Inicia un temporizador que se ejecuta cada minuto
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    final now = DateTime.now();
    
    print('Servicio en segundo plano | Verificando rutinas a las ${now.hour}:${now.minute}');
    
    final routines = await routineService.getAllRoutines();

    for (final routine in routines) {
      final isToday = routine.days.contains(now.weekday);
      final isTime = routine.hour == now.hour && routine.minute == now.minute;

      if (routine.isActive && isToday && isTime) {
        print('¡RUTINA ACTIVADA! -> ${routine.title}');
        try {
          await apiService.sendCommand(routine.deviceId, routine.commandPayload);
          print('Comando de rutina enviado exitosamente.');

        } catch (e) {
          print('Error al enviar el comando de la rutina: $e');
        }
      }
    }
  });
}

/// Función auxiliar para configurar Hive y Amplify en el isolate del background.
Future<void> _configureBackgroundServices() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(RoutineAdapter().typeId)) {
    Hive.registerAdapter(RoutineAdapter());
  }

  try {
    if (!Amplify.isConfigured) {
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
      ]);
      await Amplify.configure(amplifyconfig);
      print("Amplify configurado en segundo plano.");
    }
  } catch (e) {
    print("Error al configurar Amplify en segundo plano: $e");
  }
}

/// Función para inicializar y lanzar el servicio desde la app principal.
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: (ServiceInstance service) => true,
    ),
  );
  service.startService();
}