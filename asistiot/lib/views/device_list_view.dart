import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/device_viewmodel.dart';

class DeviceListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DeviceViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Dispositivos disponibles')),
      body: Center(
        child: Builder(builder: (_) {
          if (viewModel.isLoading) {
            return CircularProgressIndicator();
          }

          if (viewModel.hasError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error al buscar dispositivos.'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: viewModel.loadDevices,
                  child: Text('Reintentar'),
                ),
              ],
            );
          }

          if (viewModel.devices.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No se encontraron dispositivos.'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: viewModel.loadDevices,
                  child: Text('Reintentar'),
                ),
              ],
            );
          }

          // Mostrar lista de dispositivos
          return ListView.builder(
            itemCount: viewModel.devices.length,
            itemBuilder: (context, index) {
              final device = viewModel.devices[index];
              return ListTile(
                leading: Icon(Icons.devices),
                title: Text(device.name),
                subtitle: Text(device.ip),
                onTap: () {
                  // Aquí podrías agregar la acción para conectar
                },
              );
            },
          );
        }),
      ),
    );
  }
}
