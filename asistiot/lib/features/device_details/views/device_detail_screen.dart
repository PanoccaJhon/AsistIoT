import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/iot_repository.dart'; // Necesario para la inyección
import '../viewmodels/device_detail_viewmodel.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    // Creamos un Provider específico para esta pantalla y su ViewModel.
    // Se destruirá automáticamente cuando la pantalla se cierre.
    return ChangeNotifierProvider(
      create: (context) => DeviceDetailViewModel(
        deviceId: deviceId,
        // Obtenemos el repositorio que ya fue provisto en main.dart
        repository: Provider.of<IotRepository>(context, listen: false), 
      ),
      child: Scaffold(
        appBar: AppBar(
          // El Consumer nos permite acceder al ViewModel para obtener el nombre
          title: Consumer<DeviceDetailViewModel>(
            builder: (context, viewModel, child) {
              return Text(viewModel.device?.name ?? 'Cargando...');
            },
          ),
        ),
        body: Consumer<DeviceDetailViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (viewModel.device == null) {
              return const Center(child: Text('Dispositivo no encontrado.'));
            }

            final device = viewModel.device!;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  // Tarjeta de control principal
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.lightbulb,
                        size: 40,
                        color: device.isOn ? Colors.amber : Colors.grey,
                      ),
                      title: const Text('Luz Principal'),
                      trailing: Switch.adaptive(
                        value: device.isOn,
                        onChanged: (value) {
                          // Aquí deberíamos llamar a un método en el ViewModel de detalles
                          // o reutilizar el de Home si el estado es global.
                          // Por simplicidad, este control podría estar deshabilitado
                          // o requerir añadir `toggleLight` al DeviceDetailViewModel.
                        },
                      ),
                    ),
                  ),
                  
                  // Tarjeta de modo automático
                  Card(
                    child: SwitchListTile.adaptive(
                      title: const Text('Modo Automático'),
                      subtitle: const Text('Encendido por movimiento y poca luz'),
                      value: device.isAutoMode,
                      onChanged: (value) {
                        viewModel.toggleAutoMode(value);
                      },
                    ),
                  ),

                  // Tarjeta de información de sensores
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text('Datos de Sensores', style: Theme.of(context).textTheme.titleLarge),
                           const SizedBox(height: 12),
                           Text('Detección de Movimiento: ${device.motionDetected == true ? "Sí" : "No"}'),
                           const SizedBox(height: 8),
                           Text('Nivel de Iluminación: ${device.lightLevel} lux'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}