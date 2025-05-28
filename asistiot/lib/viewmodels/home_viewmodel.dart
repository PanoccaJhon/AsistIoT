import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeViewModel extends StateNotifier<String> {
  HomeViewModel() : super('');

  void listenToVoiceCommand() {
    // lógica para escuchar voz
    state = 'nuevo comando de voz';
  }

  String get lastCommand => state;
}

// Provider global
final homeViewModelProvider = StateNotifierProvider<HomeViewModel, String>(
  (ref) => HomeViewModel(),
);
