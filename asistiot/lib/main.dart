import 'package:asistiot_project/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- NUEVAS IMPORTACIONES PARA AMPLIFY ---
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'config/amplifyconfiguration.dart';
// ------------------------------------

import 'core/services/iot_repository.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'features/auth/views/auth_wrapper.dart';

import 'config/app_colors.dart';

// La función main ahora es asíncrona para esperar a Amplify
Future<void> main() async {
  // <-- MODIFICADO
  // Es necesario para asegurar que Flutter esté listo antes de llamar a código nativo
  WidgetsFlutterBinding.ensureInitialized(); // <-- NUEVO

  // Configuramos Amplify antes de correr la app
  await _configureAmplify(); // <-- NUEVO

  runApp(const MyApp());
}

// --- NUEVA FUNCIÓN PARA CONFIGURAR AMPLIFY ---
Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    await Amplify.addPlugin(auth);

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
        Provider<IotRepository>(create: (_) => MockIotRepository()),

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