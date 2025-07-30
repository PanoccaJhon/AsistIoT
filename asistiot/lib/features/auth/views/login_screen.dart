import 'package:asistiot_project/core/services/auth_service.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:asistiot_project/features/auth/views/signup_screen.dart';
import 'package:asistiot_project/features/auth/views/confirmation_screen.dart';

// Importa las futuras pantallas para la navegación
// import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
Future<void> _signIn() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() { _isLoading = true; });

  final authService = context.read<AuthService>();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  
  try {
    final success = await authService.signInUser(
      username: email,
      password: password,
    );
    // Si hay éxito, el AuthWrapper se encarga de navegar

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Email o contraseña incorrectos.')),
      );
    }
  } on UserNotConfirmedException { // <-- NUEVO: Capturar este error específico
    print("El usuario no está confirmado. Redirigiendo a la pantalla de confirmación.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tu cuenta no está confirmada. Por favor, introduce el código.')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConfirmationScreen(email: email)),
    );
  } on Exception catch (e) {
    print("Error de login: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.red, content: Text('Ocurrió un error inesperado.')),
    );
  } finally {
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo o Título de la App
                  Icon(
                    Icons.home_work_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenido a AsistIoT',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para controlar tu hogar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),

                  // Campo de Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Por favor, introduce un email válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, introduce tu contraseña.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón de Iniciar Sesión
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _signIn,
                          child: const Text('INICIAR SESIÓN'),
                        ),
                  const SizedBox(height: 16),

                  // Botón para ir a Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?'),
                      TextButton(
                        onPressed: () {
                          // Navegar a la pantalla de registro
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignUpScreen())
                          );
                        },
                        child: const Text('Regístrate'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}