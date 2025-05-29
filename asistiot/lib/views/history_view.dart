import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/history_viewmodel.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historial = ref.watch(historyProvider);

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
