import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/device_viewmodel.dart';
import '../views/device_list_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeviceViewModel()..loadDevices(),
      child: MaterialApp(
        home: DeviceListView(),
      ),
    );
  }
}
