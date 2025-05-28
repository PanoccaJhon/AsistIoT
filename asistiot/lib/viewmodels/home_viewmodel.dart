import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class HomeViewModel extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _lastCommand = '';

  String get lastCommand => _lastCommand;

  Future<void> listenToVoiceCommand() async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) {
        _lastCommand = result.recognizedWords;
        notifyListeners();
      });
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
