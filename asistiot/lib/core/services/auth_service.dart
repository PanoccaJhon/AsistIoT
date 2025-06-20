import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

// Enum para representar los diferentes estados de autenticación
enum AuthStatus { signedIn, signedOut, sessionExpired, checking }
enum SignUpResult { success, userAlreadyExists, failure }

class AuthService {
  // Un StreamController para emitir el estado de autenticación.
  // Usamos .broadcast() para permitir múltiples oyentes.
  final _authStatusController = StreamController<AuthStatus>.broadcast();

  // El resto de la app escuchará este Stream para reaccionar a los cambios.
  Stream<AuthStatus> get authStatusStream => _authStatusController.stream;

  AuthService() {
    // Al crear el servicio, inmediatamente comprobamos el estado inicial
    // y nos ponemos a escuchar por futuros eventos.
    _checkInitialAuthStatus();
    _listenToAuthEvents();
  }

  // Comprueba el estado al arrancar la app
  Future<void> _checkInitialAuthStatus() async {
    try {
      await Amplify.Auth.getCurrentUser();
      _authStatusController.add(AuthStatus.signedIn);
    } on SignedOutException {
      _authStatusController.add(AuthStatus.signedOut);
    } on Exception catch (e) {
      print("Error inicial al comprobar usuario: $e");
      _authStatusController.add(AuthStatus.signedOut);
    }
  }

  // Se suscribe al Hub de Amplify para escuchar eventos en tiempo real
  void _listenToAuthEvents() {
    Amplify.Hub.listen(HubChannel.Auth, (hubEvent) {
      switch (hubEvent.eventName) {
        case 'SIGNED_IN':
          _authStatusController.add(AuthStatus.signedIn);
          break;
        case 'SIGNED_OUT':
          _authStatusController.add(AuthStatus.signedOut);
          break;
        case 'SESSION_EXPIRED':
          _authStatusController.add(AuthStatus.sessionExpired);
          break;
      }
    });
  }

  // --- Funciones públicas que la UI puede llamar ---

  Future<AuthUser?> getCurrentUser() async {
    try {
      return await Amplify.Auth.getCurrentUser();
    } on AuthException {
      return null;
    }
  }

  Future<SignUpResult> signUpUser({ // <-- MODIFICADO: Devuelve nuestro enum
  required String username,
  required String password,
  required String name,
}) async {
  try {
    final userAttributes = {AuthUserAttributeKey.name: name};
    await Amplify.Auth.signUp(
      username: username,
      password: password,
      options: SignUpOptions(userAttributes: userAttributes),
    );
    return SignUpResult.success;
  } on UsernameExistsException { // <-- MODIFICADO: Capturamos el error específico
    print('Este usuario ya existe, pero puede no estar confirmado.');
    return SignUpResult.userAlreadyExists;
  } on AuthException catch (e) {
    print('Error al registrar usuario: ${e.message}');
    return SignUpResult.failure;
  }
}

  Future<bool> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      final result = await Amplify.Auth.confirmSignUp(
        username: username,
        confirmationCode: confirmationCode,
      );
      return result.isSignUpComplete;
    } on AuthException catch (e) {
      print('Error al confirmar el registro: ${e.message}');
      return false;
    }
  }

  Future<bool> signInUser({
    required String username,
    required String password,
  }) async {
    try {
      final result = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
      // El Hub se encargará de notificar el cambio de estado
      return result.isSignedIn;
    } on AuthException catch (e) {
      print('Error al iniciar sesión: ${e.message}');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
      // El Hub se encargará de notificar el cambio de estado
    } on AuthException catch (e) {
      print('Error al cerrar sesión: ${e.message}');
    }
  }

  // Es buena práctica tener un método para cerrar el StreamController
  void dispose() {
    _authStatusController.close();
  }
}