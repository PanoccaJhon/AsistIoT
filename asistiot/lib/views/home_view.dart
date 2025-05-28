import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistiot/viewmodels/home_viewmodel.dart';


class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HomeViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('AsistIoT'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Conéctate a WiFi para controlar\ndispositivos con tu voz',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                viewModel.listenToVoiceCommand();
              },
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue,
                child: Icon(Icons.mic, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'TOCA Y HABLA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Text(
              'Último comando: ${viewModel.lastCommand}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
