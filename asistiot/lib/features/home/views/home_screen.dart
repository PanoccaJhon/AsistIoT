import 'package:asistiot_project/features/add_device/views/add_device_screen.dart';
import 'package:asistiot_project/features/device_details/views/device_detail_screen.dart';
import 'package:asistiot_project/data/models/light_device.dart';
import 'package:asistiot_project/features/home/viewmodels/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // La carga inicial se mantiene igual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Dispositivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir Dispositivo',
            onPressed: () async {
              // MODIFICADO: Espera a que la pantalla se cierre para refrescar
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
              );
              // Llama a refresh en el ViewModel
              if (mounted) {
                context.read<HomeViewModel>().refresh();
              }
            },
          ),
        ],
      ),
      body: _buildBody(context, viewModel),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          viewModel.isListening ? viewModel.stopListening() : viewModel.startListening();
        },
        tooltip: 'Control por Voz',
        child: const Icon(Icons.mic),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.devices.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (viewModel.devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_other, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('No hay dispositivos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Añade tu primer dispositivo usando el botón "+" en la esquina superior.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    // AÑADIDO: RefreshIndicator para "pull-to-refresh"
    return RefreshIndicator.adaptive(
      onRefresh: viewModel.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: viewModel.devices.length,
        itemBuilder: (context, index) {
          final device = viewModel.devices[index];
          return _DeviceCard(device: device);
        },
      ),
    );
  }
}
/// Widget para mostrar la tarjeta de un solo dispositivo.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final LightDevice device;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeViewModel>();
    final bool isOnline = device.online;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      // MODIFICADO: Cambia el color y la sombra si está desconectado para un efecto visual más claro.
      color: isOnline ? null : Theme.of(context).colorScheme.surface.withOpacity(0.5),
      elevation: isOnline ? null : 0.5,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        onTap: () {
          
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DeviceDetailScreen(deviceId: device.id),
              ),
            ).then((_) {
              // Refresca la lista al volver de la pantalla de detalles.
              if (context.mounted) {
                viewModel.refresh();
              }
            });
          
        },
        leading: Icon(
          Icons.lightbulb_outline_rounded,
          // El color ahora solo depende de si la luz está ON, `enabled` se encarga del gris.
          color: device.luz1 ? Colors.amber.shade700 : null,
          size: 40,
        ),
        title: Row(
          children: [
            Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 5,
              backgroundColor: isOnline ? Colors.green.shade400 : Colors.grey.shade400,
            ),
          ],
        ),
        subtitle: Text(
          isOnline 
              ? 'Conectado • Modo auto: ${device.isAutoMode ? "ON" : "OFF"}'
              : 'Desconectado',
          style: TextStyle(color: isOnline ? null : Colors.red.shade400),
        ),
      ),
    );
  }
}