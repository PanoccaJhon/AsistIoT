import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class CloudVoiceService {
  final String _projectId;
  final String _credentialsPath;
  AutoRefreshingAuthClient? _authClient;

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _audioPath;

  CloudVoiceService({
    required String projectId,
    required String credentialsPath,
  })  : _projectId = projectId,
        _credentialsPath = credentialsPath;

  /// Inicializa el cliente de autenticación para las APIs de Google Cloud.
  Future<bool> initialize() async {
    if (_authClient != null) return true;
    try {
      final jsonString = await rootBundle.loadString(_credentialsPath);
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      // Necesitamos permisos para STT y Dialogflow
      final scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      _authClient = await clientViaServiceAccount(credentials, scopes);
      return true;
    } catch (e) {
      print("Error inicializando autenticación: $e");
      return false;
    }
  }

  /// Inicia la grabación de un clip de audio.
  Future<void> startRecording() async {
    final tempDir = await getTemporaryDirectory();
    _audioPath = '${tempDir.path}/temp_audio.wav';
    
    // Graba en un formato compatible con la API de Google (WAV en este caso)
    await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1,),
        path: _audioPath!);
  }

  /// Detiene la grabación y envía el audio a la API de Google Speech-to-Text.
  Future<String?> stopRecordingAndTranscribe() async {
    if (!await _audioRecorder.isRecording()) return null;
    
    await _audioRecorder.stop();

    if (_audioPath == null || _authClient == null) return null;

    final audioFile = File(_audioPath!);
    if (!await audioFile.exists()) return null;
    
    // Lee el archivo de audio y lo codifica en base64
    final audioBytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(audioBytes);

    // Prepara la llamada a la API de Google Cloud STT
    final url = Uri.parse('https://speech.googleapis.com/v1/speech:recognize');
    final body = {
      "config": {
        "encoding": "LINEAR16", // O 'LINEAR16' si usas ese encoder
        "sampleRateHertz": 16000, // Asegúrate de que coincida con la grabación
        "languageCode": "es-ES",
      },
      "audio": {
        "content": base64Audio,
      }
    };

    try {
      final response = await _authClient!.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Extrae el texto transcrito de la respuesta
        if (responseBody['results'] != null && responseBody['results'].isNotEmpty) {
          return responseBody['results'][0]['alternatives'][0]['transcript'];
        }
      } else {
        print("Error en Google Cloud STT API: ${response.body}");
      }
    } catch (e) {
      print("Excepción al transcribir: $e");
    }
    
    return null; // Devuelve nulo si algo falla
  }

  /// Envía el texto ya transcrito a Dialogflow.
  Future<Map<String, dynamic>?> detectIntent(String text, String sessionId) async {
    if (_authClient == null) return null;
    
    final url = Uri.parse('https://dialogflow.googleapis.com/v2/projects/$_projectId/agent/sessions/$sessionId:detectIntent');
    final body = {
      "queryInput": {
        "text": {"text": text, "languageCode": "es"}
      }
    };

    try {
      final response = await _authClient!.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['queryResult'];
      } else {
        print("Error en Dialogflow API: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Excepción al llamar a Dialogflow: $e");
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}