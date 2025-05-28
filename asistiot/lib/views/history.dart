import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({Key? key}) : super(key: key);

  // Ejemplo de datos del historial
  final List<String> historial = const [
    'Lampara - Encendido - 11:00 02/05/2025' ,
    'Lampara - Apagado - 10:30 02/05/2025',
    'Lampara - Encendido - 10:00 02/05/2025' ,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
      ),
      body: historial.isEmpty
          ? const Center(
              child: Text('El historial está vacío'),
            )
          : ListView.builder(
              itemCount: historial.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(historial[index]),
                );
              },
            ),
    );
  }
}