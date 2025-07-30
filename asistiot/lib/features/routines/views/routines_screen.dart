import 'package:flutter/material.dart';

// Modelo de datos de ejemplo. Luego lo reemplazarás con tu modelo real.
class _Routine {
  final String title;
  final String time;
  final String days;
  final IconData icon;
  bool isActive;

  _Routine({
    required this.title,
    required this.time,
    required this.days,
    required this.icon,
    this.isActive = true,
  });
}

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DATOS DE EJEMPLO (se reemplazarán con el ViewModel) ---
    final List<_Routine> routines = [
      _Routine(
        title: 'Apagar luces de noche',
        time: '11:00 PM',
        days: 'Todos los días',
        icon: Icons.bedtime_outlined,
        isActive: true,
      ),
      _Routine(
        title: 'Alarma despertador',
        time: '6:30 AM',
        days: 'Lunes a Viernes',
        icon: Icons.alarm_on_rounded,
        isActive: true,
      ),
      _Routine(
        title: 'Encender luces al atardecer',
        time: '6:00 PM',
        days: 'Sáb, Dom',
        icon: Icons.wb_sunny_outlined,
        isActive: false,
      ),
    ];
    // ---------------------------------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        centerTitle: true,
      ),
      body: routines.isEmpty
          ? _buildEmptyState()
          : _buildRoutinesList(routines),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navegar a una pantalla para crear una nueva rutina
        },
        tooltip: 'Añadir Rutina',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Construye la lista de rutinas si no está vacía.
  Widget _buildRoutinesList(List<_Routine> routines) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: routines.length,
      itemBuilder: (context, index) {
        final routine = routines[index];
        return _RoutineCard(routine: routine);
      },
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
  const _RoutineCard({required this.routine});

  final _Routine routine;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        secondary: CircleAvatar(
          child: Icon(routine.icon),
        ),
        title: Text(routine.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${routine.days} a las ${routine.time}'),
        value: routine.isActive,
        onChanged: (bool newValue) {
          // TODO: Llamar a una función en el ViewModel para activar/desactivar la rutina
          // viewModel.toggleRoutine(routine.id, newValue);
        },
      ),
    );
  }
}