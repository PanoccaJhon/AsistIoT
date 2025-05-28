import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/home_view.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: HomeView(),
      ),
    ),
  );
}
