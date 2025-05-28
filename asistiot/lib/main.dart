import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistiot/viewmodels/home_viewmodel.dart';
import 'package:asistiot/views/home_view.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeView(),
    );
  }
}
