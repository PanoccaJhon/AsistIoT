import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../data/models/device.dart';

class ApiService {
  
  Future<bool> associateDevice(String thingName) async {
    
    try {
      final restOperation = Amplify.API.post(
        '/dispositivos',
        body: HttpPayload.json({'thingName': thingName}),
      );
      final response = await restOperation.response;
      print('Respuesta de asociación: ${response.decodeBody()}');
      return response.statusCode == 200;
    } on ApiException catch (e) {
      print('Error al asociar dispositivo: $e');
      return false;
    }
  }

  Future<List<Device>> listDevices() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        // Si estamos logueados, obtenemos el token JWT.
        final authUser = await Amplify.Auth.getCurrentUser();
        final jwtToken = authUser.toString(); // Obtenemos el token JWT del usuario
        print('--- DIAGNÓSTICO DE SESIÓN ---');
        print('El usuario ESTÁ logueado correctamente.');
        print('Token JWT (primeros 30 caracteres): ${jwtToken.substring(0, 30)}...');
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

  Future<bool> sendCommand(String thingName, {required String component, required String value}) async {
    try {
      final command = {
        'componente': component,
        'valor': value,
      };
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