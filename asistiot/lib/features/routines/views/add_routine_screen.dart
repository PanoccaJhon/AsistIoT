// lib/features/routines/views/add_routine_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../viewmodels/routines_viewmodel.dart';

class AddRoutineScreen extends StatefulWidget {

  final String deviceId;

  const AddRoutineScreen({super.key, required this.deviceId});

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  final List<bool> _selectedDays = List.generate(7, (_) => false);
  String? _selectedAction;

  // Mapa de acciones disponibles para el usuario
  final Map<String, String> _availableActions = {
    'Encender Luz 1': jsonEncode({'luz1': 'ON'}),
    'Apagar Luz 1': jsonEncode({'luz1': 'OFF'}),
    'Encender Luz 2': jsonEncode({'luz2': 'ON'}),
    'Apagar Luz 2': jsonEncode({'luz2': 'OFF'}),
    'Activar Modo Automático': jsonEncode({'modo_auto': true}),
    'Desactivar Modo Automático': jsonEncode({'modo_auto': false}),
  };

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _saveRoutine() {
    if (_formKey.currentState!.validate()) {
      final selectedDaysIndices = <int>[];
      for (int i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) {
          selectedDaysIndices.add(i + 1); // 1=Lunes, 7=Domingo
        }
      }

      if (selectedDaysIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona al menos un día.')),
        );
        return;
      }

      Provider.of<RoutinesViewModel>(context, listen: false).addRoutine(
        deviceId: widget.deviceId,
        title: _titleController.text,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        days: selectedDaysIndices,
        commandPayload: _selectedAction!,
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Rutina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRoutine,
            tooltip: 'Guardar Rutina',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la rutina',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce un nombre.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildTimePicker(),
            const SizedBox(height: 24),
            _buildDaySelector(),
            const SizedBox(height: 24),
            _buildActionSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: const Text('Hora de ejecución'),
      subtitle: Text(_selectedTime.format(context)),
      onTap: _pickTime,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repetir en:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: _selectedDays,
          onPressed: (index) {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          borderRadius: BorderRadius.circular(8),
          children: days.map((day) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(day),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildActionSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Acción a realizar',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.bolt),
      ),
      value: _selectedAction,
      items: _availableActions.keys.map((String action) {
        return DropdownMenuItem<String>(
          value: _availableActions[action],
          child: Text(action),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedAction = newValue;
        });
      },
      validator: (value) => value == null ? 'Por favor, selecciona una acción.' : null,
    );
  }
}