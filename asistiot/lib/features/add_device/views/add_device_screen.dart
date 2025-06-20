import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lottie/lottie.dart'; // <-- Importar Lottie
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_device_viewmodel.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  late AddDeviceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AddDeviceViewModel();
    _checkPermissions();
  }

  // Reemplaza tu función existente con esta
Future<void> _checkPermissions() async {
  // Mapa para guardar el estado de los permisos solicitados
  Map<Permission, PermissionStatus> statuses;

  // En Android, los permisos requeridos cambiaron en la versión 12 (API 31)
  // En iOS, el permiso es más simple
  if (Platform.isAndroid) {
    statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location, // Siempre es buena idea pedirlo para compatibilidad
    ].request();
  } else { // Para iOS
    statuses = await [
      Permission.bluetooth,
    ].request();
  }

  // Ahora, verificamos si el permiso CLAVE para escanear fue otorgado
  var scanPermission = statuses[Permission.bluetoothScan] ?? PermissionStatus.denied;
  // Para Android viejo, el permiso clave es la ubicación
  if (await Permission.location.isGranted) {
      scanPermission = PermissionStatus.granted;
  }


  if (scanPermission.isGranted) {
    // ¡ÉXITO! Tenemos permiso, ahora sí podemos escanear.
    if (mounted) {
      Provider.of<AddDeviceViewModel>(context, listen: false).startScan();
    }
  } else {
    // El usuario negó el permiso. Mostramos un mensaje claro.
    print("Permiso de escaneo denegado por el usuario.");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se requieren permisos de Bluetooth y Ubicación para buscar dispositivos.'))
      );
      // Opcional: Abrir la configuración de la app para que el usuario los active manualmente
      // openAppSettings();
    }
  }
}
  
  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(title: const Text('Añadir Dispositivo')),
        body: Consumer<AddDeviceViewModel>(
          builder: (context, viewModel, child) {
            // Si ya estamos conectados a un dispositivo, mostramos el formulario WiFi
            if (viewModel.status == AddDeviceStatus.connected) {
              return _buildWifiFormUI(context, viewModel);
            }
            // Si no, mostramos la interfaz de escaneo
            return _buildScanningInterface(context, viewModel);
          },
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildScanningInterface(BuildContext context, AddDeviceViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 1. Cabecera con estado y animación
          _buildStatusHeader(viewModel),
          const SizedBox(height: 20),

          // 2. Lista de resultados
          Expanded(child: _buildResultsList(context, viewModel)),
          const SizedBox(height: 20),
          
          // 3. Botón de acción
          _buildActionButton(viewModel),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(AddDeviceViewModel viewModel) {
    String asset = 'ani_search_blue.json';
    String text = 'Pulsa "Buscar" para encontrar dispositivos';

    switch (viewModel.status) {
      case AddDeviceStatus.scanning:
        text = 'Buscando dispositivos cercanos...';
        break;
      case AddDeviceStatus.noResults:
        asset = 'assets/ble_not_found.json'; // (Necesitarías una animación para "no encontrado")
        text = 'No se encontraron dispositivos.\nAsegúrate de que esté encendido y cerca.';
        break;
      case AddDeviceStatus.resultsFound:
        asset = 'assets/ble_select.json'; // (Necesitarías una animación para "seleccionar")
        text = '¡Dispositivos encontrados! Selecciona uno para continuar.';
        break;
      case AddDeviceStatus.connecting:
        text = 'Conectando con ${viewModel.selectedDevice?.platformName}...';
        break;
      case AddDeviceStatus.error:
        asset = 'assets/ble_error.json'; // (Necesitarías una animación para "error")
        text = viewModel.errorMessage;
        break;
      default:
        break;
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          // Usamos un Lottie para el escaneo, o un Icono para otros estados
          child: viewModel.status == AddDeviceStatus.scanning
              ? Lottie.asset("assets/$asset")
              : Icon(Icons.bluetooth_searching, size: 80, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildResultsList(BuildContext context, AddDeviceViewModel viewModel) {
    // Si estamos conectando, mostramos un indicador de progreso
    if (viewModel.status == AddDeviceStatus.connecting) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return StreamBuilder<List<ScanResult>>(
      stream: viewModel.scanResultsStream,
      initialData: const [],
      builder: (c, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // No muestra nada si la lista está vacía
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final result = snapshot.data![index];
            if (result.device.platformName.isEmpty) return const SizedBox.shrink();
            
            return Card(
              child: ListTile(
                leading: const Icon(Icons.memory, size: 36),
                title: Text(result.device.platformName),
                subtitle: Text("Señal: ${result.rssi} dBm"),
                onTap: () => viewModel.connectToDevice(result.device),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton(AddDeviceViewModel viewModel) {
    bool isScanning = viewModel.status == AddDeviceStatus.scanning;
    String buttonText = 'Buscar Dispositivos';
    if (viewModel.status == AddDeviceStatus.noResults) buttonText = 'Reintentar Búsqueda';
    if (isScanning) buttonText = 'Buscando...';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isScanning ? Container(width: 20, height: 20, margin: const EdgeInsets.only(right: 8), child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Icon(Icons.search),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          // El botón se deshabilita mientras se escanea o conecta
          disabledBackgroundColor: Colors.grey,
        ),
        onPressed: isScanning || viewModel.status == AddDeviceStatus.connecting
            ? null 
            : () => viewModel.startScan(),
      ),
    );
  }

  // La función _buildWifiFormUI no necesita cambios y puedes pegarla aquí
  Widget _buildWifiFormUI(BuildContext context, AddDeviceViewModel viewModel) {
     return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conectado a: ${viewModel.selectedDevice!.platformName}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Introduce las credenciales de tu red Wi-Fi para configurar el dispositivo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: viewModel.ssidController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Red Wi-Fi (SSID)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña del Wi-Fi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (viewModel.status == AddDeviceStatus.connecting)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final success = await viewModel.sendWifiCredentials(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? '¡Credenciales enviadas! El dispositivo se reiniciará.'
                                : 'Error al enviar credenciales.'),
                          ),
                        );
                        if (success) Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Configurar y Conectar'),
                  ),
                ),
            ],
          ),
        );
  }
}