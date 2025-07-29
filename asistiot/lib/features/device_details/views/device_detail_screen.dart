import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/iot_repository.dart'; // Necesario para la inyección
import '../viewmodels/device_detail_viewmodel.dart';
// Asumiendo que tienes una pantalla de historial
// import 'history_screen.dart'; 

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DeviceDetailViewModel(
        deviceId: deviceId,
        repository: Provider.of<IotRepository>(context, listen: false),
      ),
      child: Scaffold(
        appBar: AppBar(
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
            // Lógica para determinar si el dispositivo está conectado
            final isConnected = device.online; // Usamos el dato del shadow
            final lastSeen = device.lastSeenTimestamp != 0
                ? DateTime.fromMillisecondsSinceEpoch(device.lastSeenTimestamp)
                : null;

            return RefreshIndicator(
              onRefresh: () async {
                await viewModel.refresh();
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // --- INICIO DE NUEVOS WIDGETS ---

                    // Tarjeta de estado de conexión
                    Card(
                      child: ListTile(
                        leading: Icon(
                          isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          color: isConnected ? Colors.green : Colors.red,
                          size: 40,
                        ),
                        title: const Text('Estado de Conexión'),
                        subtitle: Text(
                          isConnected
                              ? 'Conectado'
                              : (lastSeen != null ? 'Última vez online: ${lastSeen.toLocal()}' : 'Desconocido'),
                        ),
                      ),
                    ),

                    // --- FIN DE WIDGETS DE CONTROL EXISTENTES ---
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
                    Row(
                      children: [
                        // --- Tarjeta para la Luz 1 ---
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Para que la tarjeta se ajuste al contenido
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 40.0,
                                    // El color del ícono cambia según el estado
                                    color: device.luz1 ? Colors.amber : Colors.grey,
                                  ),
                                  const SizedBox(height: 8.0),
                                  const Text(
                                    'Luz 1',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    // El texto cambia según el estado
                                    device.luz1 ? 'ENCENDIDO' : 'APAGADO',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: device.luz1 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Switch.adaptive(value: device.luz1, onChanged: (value) {
                                    viewModel.toggleLight(value, 1);
                                  })
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8.0), // Espacio entre las tarjetas

                        // --- Tarjeta para la Luz 2 ---
                        Expanded(
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 40.0,
                                    color: device.luz2 ? Colors.amber : Colors.grey,
                                  ),
                                  const SizedBox(height: 8.0),
                                  const Text(
                                    'Luz 2',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    device.luz2 ? 'ENCENDIDO' : 'APAGADO',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: device.luz2 ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Switch.adaptive(value: device.luz2, onChanged: (value) {
                                    viewModel.toggleLight(value, 2);
                                  })
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Datos de Sensores', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 12),
                            const SizedBox(height: 8),
                            Text('Nivel de Iluminación: ${device.lightLevel} lux'),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24), // Espaciador

                  ],
                ),
              )
            );
          },
        ),
      ),
    );
  }
}