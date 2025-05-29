import 'package:flutter/material.dart';
import 'package:asistiot/viewmodels/devices_view_model.dart';

class DevicesView extends StatefulWidget {
  const DevicesView({super.key});

  @override
  State<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends State<DevicesView> {
  final viewModel = DevicesViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text(
          'AsistIoT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[700],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Di un comando para\ncontrolar tus dispositivos',
              style: TextStyle(fontSize: 22.0),
              textAlign: TextAlign.center,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DISPOSITIVOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lámpara',
                      style: TextStyle(fontSize: 24.0),
                    ),
                    Switch(
                      value: viewModel.isLampOn,
                      onChanged: (value) {
                        setState(() {
                          viewModel.toggleLamp();
                        });
                      },
                      activeColor: Colors.blue[700],
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    viewModel.toggleListening();
                  },
                  backgroundColor: Colors.blue[700],
                  child: const Icon(Icons.mic, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'TOCA PARA PAUSAR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
