import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({Key? key}) : super(key: key);

  // Ejemplo de datos del historial
  final List<String> historial = const [
    'Busqueda 001 - 01/05/2025',
    'Busqueda 001 - 02/05/2025',
    'Busqueda 001 - 03/05/2025',
    'Busqueda 001 - 04/05/2025',
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