import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:asistiot_project/data/models/motion_event.dart';

/// ApiService es responsable de todas las comunicaciones directas con AWS a través de Amplify.
/// No conoce los modelos de la UI, solo maneja peticiones y respuestas crudas.
class ApiService {

  Future<dynamic> getDeviceById(String deviceId) async {
    try {
      final restOperation = Amplify.API.get('/dispositivos/$deviceId');
      final response = await restOperation.response;
      return jsonDecode(response.decodeBody());
    } on ApiException catch (e) {
      safePrint('Error al obtener dispositivo $deviceId: $e');
      rethrow;
    }
  }

  /// Asocia un nuevo dispositivo a la cuenta del usuario.
  Future<bool> associateDevice(String thingName) async {
    // (Este método se mantiene sin cambios, ya es correcto)
    try {
      final result = await Amplify.Auth.fetchUserAttributes();
      final userEmail = result.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.email,
      ).value;

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
      final userEmail = attributes.firstWhere(
        (attr) => attr.userAttributeKey == CognitoUserAttributeKey.email,
      ).value;

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

  // --- NUEVOS MÉTODOS ---

  /// Obtiene el estado (sombra) de un dispositivo específico.
  Future<Map<String, dynamic>> getDeviceState(String deviceId) async {
    try {
      final restOperation = Amplify.API.get('/dispositivos/$deviceId/estado');
      final response = await restOperation.response;
      return jsonDecode(response.decodeBody()) as Map<String, dynamic>;
    } on ApiException catch (e) {
      safePrint('Error al obtener estado del dispositivo $deviceId: $e');
      rethrow; // Lanza la excepción para que el ViewModel la maneje.
    }
  }

  /// Envía un comando genérico a un dispositivo.
  Future<void> sendCommand(String deviceId, String commandPayload) async {
    try {
      // La API espera un mapa, por lo que decodificamos el string JSON que nos llega.
      final body = HttpPayload.json(jsonDecode(commandPayload));
      print('Enviando comando a $deviceId: $commandPayload');
      
      final restOperation = Amplify.API.post(
        '/dispositivos/$deviceId', // Endpoint para enviar comandos
        body: body,
      );

      final response = await restOperation.response;

      if (response.statusCode != 202) {
        throw Exception('Error al enviar comando, estado: ${response.statusCode}');
      }
    } on Exception catch (e) {
      safePrint('Error al enviar comando a $deviceId: $e');
      rethrow;
    }
  }

  /// Desvincula (elimina la asociación) de un dispositivo.
  Future<void> unlinkDevice(String deviceId) async {
    try {
      final restOperation = Amplify.API.delete('/dispositivos/$deviceId');
      final response = await restOperation.response;

       if (response.statusCode != 200) {
        throw Exception('Error al desvincular, estado: ${response.statusCode}');
      }
    } on Exception catch (e) {
      safePrint('Error al desvincular el dispositivo $deviceId: $e');
      rethrow;
    }
  }

  /// Obtiene el historial de eventos de movimiento para un dispositivo específico.
  /// Devuelve una lista de objetos MotionEvent.
  Future<List<MotionEvent>> getMotionHistory(String thingName) async {
    try {

      final restOperation = Amplify.API.get('/dispositivos/$thingName/historial');

      final response = await restOperation.response;

      if (response.statusCode == 200) {
        // El cuerpo es una lista de objetos JSON
        final List<dynamic> data = jsonDecode(response.decodeBody());
        // Mapeamos cada objeto JSON a nuestro modelo MotionEvent
        return data.map((json) => MotionEvent.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener el historial: ${response.statusCode}');
      }
    } on Exception catch (e) {
      safePrint('Error en getMotionHistory para $thingName: $e');
      rethrow;
    }
  }
}