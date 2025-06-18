import 'package:asistiot_project/features/add_device/views/add_device_screen.dart';
import 'package:asistiot_project/features/device_details/views/device_detail_screen.dart';
import 'package:asistiot_project/features/home/models/light_device.dart';
import 'package:asistiot_project/features/home/viewmodels/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// La pantalla ahora es un StatefulWidget para poder cargar datos en initState.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Usamos WidgetsBinding para asegurarnos de que el context esté disponible
    // y llamamos a la función que carga todos los datos iniciales.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el ViewModel para que la UI se reconstruya con cada cambio.
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        // El título ahora es más específico para esta pantalla.
        title: const Text('Mis Dispositivos'),
        actions: [
          // Botón para ir a la pantalla de añadir un nuevo dispositivo.
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Añadir Dispositivo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
              );
            },
          ),
        ],
      ),
      // El cuerpo principal de la pantalla.
      body: _buildBody(context, viewModel),
      // El botón flotante para el control por voz.
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Simulación de la función de voz.
          viewModel.processVoiceCommand("encender luz del dormitorio");
        },
        tooltip: 'Control por Voz',
        child: const Icon(Icons.mic),
      ),
    );
  }

  /// Construye el cuerpo de la pantalla basado en el estado del ViewModel.
  Widget _buildBody(BuildContext context, HomeViewModel viewModel) {
    // Muestra un indicador de carga mientras los datos se están obteniendo.
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    // Muestra un mensaje amigable si la lista de dispositivos está vacía.
    if (viewModel.devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_other, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No hay dispositivos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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

    // Muestra la lista de dispositivos si todo está correcto.
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: viewModel.devices.length,
      itemBuilder: (context, index) {
        final device = viewModel.devices[index];
        return _DeviceCard(device: device);
      },
    );
  }
}

/// Widget para mostrar la tarjeta de un solo dispositivo.
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final LightDevice device;

  @override
  Widget build(BuildContext context) {
    // Usamos context.read aquí para llamar a funciones sin causar reconstrucciones innecesarias.
    final viewModel = context.read<HomeViewModel>();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        onTap: () {
          // Navega a la pantalla de detalles al tocar la tarjeta.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeviceDetailScreen(deviceId: device.id),
            ),
          );
        },
        leading: Icon(
          Icons.lightbulb_outline,
          color: device.isOn ? Colors.amber.shade700 : Colors.grey.shade600,
          size: 40,
        ),
        title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'Modo automático: ${device.isAutoMode ? "Activado" : "Desactivado"}\nNivel de luz: ${device.lightLevel ?? "N/A"} lux',
        ),
        trailing: Switch.adaptive(
          value: device.isOn,
          onChanged: (newValue) {
            // Llama a la función del ViewModel para cambiar el estado de la luz.
            viewModel.toggleLight(device.id);
          },
        ),
      ),
    );
  }
}