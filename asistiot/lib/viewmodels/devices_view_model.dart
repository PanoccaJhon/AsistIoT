class DevicesViewModel {
  bool isLampOn = true;
  bool isListening = true;

  void toggleLamp() {
    isLampOn = !isLampOn;
  }

  void toggleListening() {
    isListening = !isListening;
    // Aquí puedes agregar lógica de micrófono
  }
}
