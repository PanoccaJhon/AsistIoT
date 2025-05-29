import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({Key? key}) : super(key: key);

  // Datos simulados del historial
  final List<String> historial = const [
    'Lampara - Encendido - 11:00 02/05/2025',
    'Lampara - Apagado - 10:30 02/05/2025',
    'Lampara - Encendido - 10:00 02/05/2025',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: historial.isEmpty
          ? const Center(
              child: Text(
                'El historial está vacío',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: historial.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final parts = historial[index].split(' - ');
                final dispositivo = parts[0];
                final estado = parts[1];
                final fecha = parts[2];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    leading: Icon(
                      estado == 'Encendido'
                          ? Icons.toggle_on
                          : Icons.toggle_off,
                      color: estado == 'Encendido' ? Colors.green : Colors.red,
                      size: 30,
                    ),
                    title: Text(dispositivo),
                    subtitle: Text('Estado: $estado\nHora: $fecha'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
