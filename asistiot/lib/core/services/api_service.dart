import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// ApiService es responsable de todas las comunicaciones directas con AWS a través de Amplify.
/// No conoce los modelos de la UI, solo maneja peticiones y respuestas crudas.
class ApiService {
  /// Asocia un nuevo dispositivo a la cuenta del usuario.
  Future<bool> associateDevice(String thingName) async {
    // (Este método se mantiene sin cambios, ya es correcto)
    try {
      final result = await Amplify.Auth.fetchUserAttributes();
      final userEmail =
          result
              .firstWhere(
                (attr) =>
                    attr.userAttributeKey == CognitoUserAttributeKey.email,
              )
              .value;

      final body = HttpPayload.json({
        'thingName': thingName,
        'email': userEmail,
      });

      final restOperation = Amplify.API.post('/dispositivos', body: body);
      final response = await restOperation.response;
      safePrint('Respuesta de asociación: ${response.decodeBody()}');
      return response.statusCode == 200;
    } catch (e) {
      safePrint('Error al asociar dispositivo: $e');
      return false;
    }
  }

  Future<List<Device>> listDevices() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        // Si estamos logueados, obtenemos el token JWT.
        final authUser = await Amplify.Auth.getCurrentUser();
        final jwtToken =
            authUser.toString(); // Obtenemos el token JWT del usuario
        print('--- DIAGNÓSTICO DE SESIÓN ---');
        print('El usuario ESTÁ logueado correctamente.');
        print(
          'Token JWT (primeros 30 caracteres): ${jwtToken.substring(0, 30)}...',
        );
        // Si necesitas el token completo para el Paso 4, descomenta la siguiente línea:
        // print('Token JWT Completo: $jwtToken');
        print('-----------------------------');
      } else {
        print('--- DIAGNÓSTICO DE SESIÓN ---');
        print('ERROR: Amplify reporta que el usuario NO está logueado.');
        print('-----------------------------');
      }
    } catch (e) {
      print('--- DIAGNÓSTICO DE SESIÓN ---');
      print('EXCEPCIÓN al llamar a fetchAuthSession: $e');
      print('-----------------------------');
    }
    try {
      final restOperation = Amplify.API.get('/dispositivos');
      final response = await restOperation.response;
      final jsonResponse = jsonDecode(response.decodeBody());

      final List<dynamic> deviceListJson = jsonResponse;
      return deviceListJson.map((json) => Device.fromJson(json)).toList();
    } on ApiException catch (e) {
      print('Error al listar dispositivos: $e');
      return [];
    }
  }

  Future<bool> sendCommand(
    String thingName, {
    required String component,
    required String value,
  }) async {
    try {
      final command = {'componente': component, 'valor': value};
      final restOperation = Amplify.API.post(
        '/dispositivos/$thingName/comando',
        body: HttpPayload.json(command),
      );
      final response = await restOperation.response;
      return response.statusCode == 202; // 202 Accepted
    } on ApiException catch (e) {
      print('Error al enviar comando: $e');
      return false;
    }
  }
}
