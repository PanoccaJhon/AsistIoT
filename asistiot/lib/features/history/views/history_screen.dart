// lib/features/history/views/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/iot_repository.dart';
import '../viewmodels/history_viewmodel.dart';

class HistoryScreen extends StatelessWidget {
  final String deviceId;

  const HistoryScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HistoryViewModel(
        deviceId: deviceId,
        repository: Provider.of<IotRepository>(context, listen: false),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial de Movimiento'),
        ),
        body: Consumer<HistoryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (viewModel.events.isEmpty) {
              return const Center(
                child: Text(
                  'No hay eventos de movimiento registrados.',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            // Usamos RefreshIndicator para actualizar la lista
            return RefreshIndicator(
              onRefresh: () => viewModel.fetchHistory(),
              child: ListView.builder(
                itemCount: viewModel.events.length,
                itemBuilder: (context, index) {
                  final event = viewModel.events[index];
                  // Formateamos la fecha y hora para que sea legible
                  final formattedDate = event.timestamp != 0
                      ? DateTime.fromMillisecondsSinceEpoch(event.timestamp)
                      : null;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.directions_run, color: Colors.blue),
                      title: Text(event.message),
                      subtitle: Text('$formattedDate'),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}