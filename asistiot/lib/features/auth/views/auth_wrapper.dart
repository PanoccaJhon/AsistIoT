import 'package:asistiot_project/core/services/auth_service.dart';
import 'package:asistiot_project/features/auth/views/login_screen.dart';
import 'package:asistiot_project/features/home/views/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el servicio de autenticación desde el Provider
    final authService = context.read<AuthService>();

    // Usamos un StreamBuilder para escuchar el nuevo stream de nuestro servicio
    return StreamBuilder<AuthStatus>(
      stream: authService.authStatusStream,
      builder: (context, snapshot) {
        // Mientras esperamos el primer dato, mostramos un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si el estado es 'signedIn', mostramos la pantalla principal
        if (snapshot.data == AuthStatus.signedIn) {
          return const MainScreen();
        }
        // Para cualquier otro caso (signedOut, sessionExpired, error), mostramos el login
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
