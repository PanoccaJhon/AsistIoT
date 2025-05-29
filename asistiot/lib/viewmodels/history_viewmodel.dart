import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyProvider = Provider<List<String>>((ref) {
  return [
    'Lampara - Encendido - 11:00 02/05/2025',
    'Lampara - Apagado - 10:30 02/05/2025',
    'Lampara - Encendido - 10:00 02/05/2025',
  ];
});
