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

  /// Obtiene la lista de dispositivos (en formato JSON crudo) para un usuario.
  Future<List<dynamic>> listDevices() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final userEmail =
          attributes
              .firstWhere(
                (attr) =>
                    attr.userAttributeKey == CognitoUserAttributeKey.email,
              )
              .value;

      final restOperation = Amplify.API.get(
        '/dispositivos',
        queryParameters: {'email': userEmail},
      );
      final response = await restOperation.response;
      print(response.decodeBody());

      // Devuelve la lista JSON directamente, el Repositorio se encargará de mapearla.
      return jsonDecode(response.decodeBody()) as List<dynamic>;
    } catch (e) {
      safePrint('Error al listar dispositivos: $e');
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
