import 'package:flutter/material.dart';
import '../../../core/services/iot_repository.dart'; // O tu ApiService
import '../../../data/models/motion_event.dart';

class HistoryViewModel extends ChangeNotifier {
  final IotRepository _repository;
  final String deviceId;

  HistoryViewModel({required this.deviceId, required IotRepository repository})
      : _repository = repository {
    fetchHistory();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<MotionEvent> _events = [];
  List<MotionEvent> get events => _events;

  Future<void> fetchHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      _events = await _repository.getMotionHistory(deviceId);
    } catch (e) {
      print("Error al cargar el historial: $e");
      _events = []; // En caso de error, muestra una lista vacía
    }
    _isLoading = false;
    notifyListeners();
  }
}