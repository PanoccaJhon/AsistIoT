import 'package:asistiot_project/features/home/viewmodels/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/routine.dart'; // Importa el modelo de datos correcto
import '../viewmodels/routines_viewmodel.dart'; // Importa el ViewModel
import 'add_routine_screen.dart'; // Importa la pantalla para añadir rutinas

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. El ChangeNotifierProvider se mantiene aquí
    return ChangeNotifierProvider(
      create: (context) => RoutinesViewModel(),
      // 2. Usamos un Consumer para obtener un nuevo `context` que "ve" el ViewModel
      child: Consumer<RoutinesViewModel>(
        builder: (context, viewModel, child) {
          // Este 'context' ahora SÍ tiene acceso a RoutinesViewModel
          return Scaffold(
            appBar: AppBar(
              title: const Text('Mis Rutinas'),
              centerTitle: true,
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator.adaptive())
                : viewModel.routines.isEmpty
                    ? _buildEmptyState()
                    : _buildRoutinesList(viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // 3. Pasamos el `context` del builder a la función del diálogo
                _showDeviceSelectionDialog(context);
              },
              tooltip: 'Añadir Rutina',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  /// Muestra un diálogo para que el usuario seleccione un dispositivo.
  Future<void> _showDeviceSelectionDialog(BuildContext context) async {
    // Ahora `context` puede encontrar ambos ViewModels
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    final routinesViewModel = Provider.of<RoutinesViewModel>(context, listen: false);
    
    final devices = homeViewModel.devices;

    final selectedDeviceId = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Selecciona un dispositivo'),
          children: devices.map((device) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext, device.id); 
              },
              child: Text(device.name),
            );
          }).toList(),
        );
      },
    );

    if (selectedDeviceId != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: routinesViewModel,
            child: AddRoutineScreen(deviceId: selectedDeviceId),
          ),
        ),
      );
    }
  }

  /// Construye la lista de rutinas usando los datos del ViewModel.
  Widget _buildRoutinesList(RoutinesViewModel viewModel) {
    // 4. Se añade RefreshIndicator para la funcionalidad de "deslizar para actualizar"
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: viewModel.routines.length,
        itemBuilder: (context, index) {
          final routine = viewModel.routines[index];
          return _RoutineCard(
            routine: routine,
            // 5. Se pasa la función del ViewModel al onChanged del Switch
            onToggle: (newValue) {
              viewModel.toggleRoutineStatus(routine, newValue);
            },
          );
        },
      ),
    );
  }

  /// Construye el widget que se muestra cuando no hay rutinas.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_alarm_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'No hay rutinas creadas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón "+" para programar acciones automáticas como encender luces o poner alarmas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }


}

/// Widget para mostrar la tarjeta de una sola rutina.
class _RoutineCard extends StatelessWidget {
  // 6. Se actualiza para recibir el modelo 'Routine' y una función de callback
  const _RoutineCard({required this.routine, required this.onToggle});

  final Routine routine;
  final ValueChanged<bool> onToggle;

  // Helper para formatear los días
  String _formatDays(List<int> days) {
    if (days.length == 7) return 'Todos los días';
    if (days.isEmpty) return 'Nunca';
    final dayMap = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days.map((d) => dayMap[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    // Formateamos la hora para mostrarla correctamente (ej: 06:05 AM)
    final time = TimeOfDay(hour: routine.hour, minute: routine.minute);
    final formattedTime = time.format(context);
    final formattedDays = _formatDays(routine.days);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        secondary: CircleAvatar(
          // Aquí puedes mapear el iconCodePoint guardado a un IconData si lo implementas
          child: const Icon(Icons.timer_outlined), 
        ),
        title: Text(routine.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$formattedDays a las $formattedTime'),
        value: routine.isActive,
        onChanged: onToggle, // Llama a la función del ViewModel
      ),
    );
  }
}