import 'package:asistiot_project/core/services/auth_service.dart';
import 'package:asistiot_project/features/auth/views/confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // <-- NUEVO
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // <-- NUEVO
    super.dispose();
  }

  // --- NUEVAS FUNCIONES DE VALIDACIÓN ---
  String? _validateName(String? value) {
    if (value == null || value.isEmpty)
      return 'Por favor, introduce tu nombre.';
    if (value.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty)
      return 'Por favor, introduce tu correo.';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value))
      return 'Por favor, introduce un correo válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty)
      return 'Por favor, introduce una contraseña.';
    if (value.length < 8) return 'Mínimo 8 caracteres.';
    if (!value.contains(RegExp(r'[A-Z]')))
      return 'Necesita al menos una mayúscula.';
    if (!value.contains(RegExp(r'[a-z]')))
      return 'Necesita al menos una minúscula.';
    if (!value.contains(RegExp(r'[0-9]')))
      return 'Necesita al menos un número.';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      return 'Necesita al menos un símbolo.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty)
      return 'Por favor, confirma tu contraseña.';
    if (value != _passwordController.text)
      return 'Las contraseñas no coinciden.';
    return null;
  }
  // --- FIN DE FUNCIONES DE VALIDACIÓN ---

  Future<void> _signUp() async {
    // La validación ahora se dispara antes de llamar a esta función
    if (!_formKey.currentState!.validate()) {
      print("Formulario no válido");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();

    final result = await authService.signUpUser(
      name: _nameController.text.trim(),
      username: email,
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case SignUpResult.success:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ConfirmationScreen(email: email)),
        );
        break;
      case SignUpResult.userAlreadyExists:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este usuario ya existe. Por favor, introduce el código de confirmación.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ConfirmationScreen(email: email)),
        );
        break;
      case SignUpResult.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error en el registro. Inténtalo de nuevo.'),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Nueva Cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            // --- MODIFICACIÓN CLAVE PARA VALIDACIÓN EN TIEMPO REAL ---
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Únete a AsistIoT',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea una cuenta para empezar.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),

                // Campo de Nombre con su validador
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Campo de Email con su validador
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Campo de Contraseña con su validador
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // --- NUEVO CAMPO: Confirmar Contraseña ---
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),

                // Botón de Registrarse
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _signUp,
                      child: const Text('REGISTRARME'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
