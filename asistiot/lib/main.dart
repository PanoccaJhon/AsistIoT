import 'package:asistiot_project/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- NUEVAS IMPORTACIONES PARA AMPLIFY ---
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import 'config/amplifyconfiguration.dart';
// ------------------------------------

import 'core/services/iot_repository.dart';
import 'core/services/api_service.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'features/auth/views/auth_wrapper.dart';

import 'config/app_colors.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/routine.dart'; // Importa el modelo
import 'core/services/background_service.dart'; // Importa el servicio

// La función main ahora es asíncrona para esperar a Amplify
Future<void> main() async {
  // <-- MODIFICADO
  // Es necesario para asegurar que Flutter esté listo antes de llamar a código nativo
  WidgetsFlutterBinding.ensureInitialized(); // <-- NUEVO

  await Hive.initFlutter();
  Hive.registerAdapter(RoutineAdapter()); // Registra el adaptador generado

  await initializeBackgroundService();

  // Configuramos Amplify antes de correr la app
  await _configureAmplify(); // <-- NUEVO

  runApp(const MyApp());
}

// --- NUEVA FUNCIÓN PARA CONFIGURAR AMPLIFY ---
Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final api = AmplifyAPI();
    await Amplify.addPlugins([auth, api]);

    // Configurar Amplify con el string de nuestro archivo de configuración
    await Amplify.configure(amplifyconfig);

    print('Amplify configurado exitosamente');
  } on Exception catch (e) {
    print('Error al configurar Amplify: $e');
  }
}
// ------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Proveemos el AuthService para que esté disponible en toda la app
        Provider<AuthService>(create: (_) => AuthService()), // <-- NUEVO

        // 2. Proveemos el IotRepository como antes
        Provider<ApiService>(create: (_) => ApiService()  ),
        
        Provider<IotRepository>(
          create: (context) => ApiIotRepository(
            apiService: context.read<ApiService>(),
          ),
        ),

        // 3. El ViewModel ahora puede leer las dependencias que necesita
        ChangeNotifierProvider(
          // <-- MODIFICADO
          create: (context) => HomeViewModel(
            repository: context.read<IotRepository>(),
            authService: context.read<AuthService>(), // Le pasamos el servicio de Auth
          ),
        ),
      ],
      child: MaterialApp(
        title: 'IoT Home Control',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textLight,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textLight,
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}