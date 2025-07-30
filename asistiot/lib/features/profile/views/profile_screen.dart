import 'package:asistiot_project/features/home/viewmodels/home_viewmodel.dart';
// Asumiendo que tienes un ThemeProvider para manejar el cambio de tema
// import 'package:asistiot_project/core/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos 'read' para funciones y 'watch' para datos que cambian
    final viewModel = context.watch<HomeViewModel>();
    // final themeProvider = context.watch<ThemeProvider>(); // Descomentar si tienes ThemeProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      // Usamos un ListView para que la pantalla sea scrollable si añadimos más opciones
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        children: [
          _buildProfileHeader(context, viewModel),
          const SizedBox(height: 32),
          _buildSettingsSection(context),
          const SizedBox(height: 32),
          _buildSignOutButton(context),
        ],
      ),
    );
  }

  /// Construye el encabezado con el avatar y el nombre del usuario.
  Widget _buildProfileHeader(BuildContext context, HomeViewModel viewModel) {
    final displayName = viewModel.userDisplayName ?? 'Cargando...';
    // Extraemos la primera letra para el avatar
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          // MODIFICADO: Un CircleAvatar se ve más personal que un ícono
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        // AÑADIDO: Mostrar el email del usuario (requiere añadirlo al ViewModel)
        Text(
          viewModel.userEmail ?? '', // Asumiendo que añades `userEmail` al ViewModel
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Construye la sección de ajustes de la aplicación.
  Widget _buildSettingsSection(BuildContext context) {
    // final themeProvider = context.read<ThemeProvider>(); // Descomentar si tienes ThemeProvider

    return Card(
      // AÑADIDO: Agrupamos las opciones en una tarjeta para mejor organización
      child: Column(
        children: [
          SwitchListTile.adaptive(
            title: const Text('Modo Oscuro'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: true, // Reemplazar con: themeProvider.isDarkMode
            onChanged: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta función se implementará próximamente.'),
                  duration: Duration(seconds: 2), // El mensaje desaparecerá tras 2 segundos
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos y Condiciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta función se implementará próximamente.'),
                  duration: Duration(seconds: 2), // El mensaje desaparecerá tras 2 segundos
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Construye el botón para cerrar sesión.
  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.1),
          foregroundColor: Colors.red.shade700,
          elevation: 0,
        ),
        onPressed: () {
          // AÑADIDO: Diálogo de confirmación antes de cerrar sesión
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Cerrar Sesión'),
              content: const Text('¿Estás seguro de que deseas cerrar tu sesión?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Cierra el diálogo
                    context.read<HomeViewModel>().signOut();
                  },
                  child: const Text('Confirmar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}