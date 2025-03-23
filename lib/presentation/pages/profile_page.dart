import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermojiCircleAvatar.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/user_model.dart';
import 'package:proyecto_jj/presentation/pages/edit_profile_page.dart';
import 'package:proyecto_jj/presentation/pages/theme_selection_page.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
        automaticallyImplyLeading: false,
      ),
      body: user == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 16),
                    // Avatar
                    _buildAvatar(user, theme),
                    SizedBox(height: 16),
                    // Nombre del usuario
                    Text(
                      '${user.firstName} ${user.lastName}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                    SizedBox(height: 32),
                    // Opciones de perfil
                    _buildProfileOption(
                      context,
                      'Editar Perfil',
                      Icons.edit,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      context,
                      'Notificaciones',
                      Icons.notifications_outlined,
                      () {
                        // Implementar configuración de notificaciones
                        AlertHelper.showInfoAlert(
                          context, 
                          'Función de notificaciones próximamente'
                        );
                      },
                    ),
                    _buildProfileOption(
                      context,
                      'Tema de la Aplicación',
                      Icons.color_lens_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ThemeSelectionPage(),
                          ),
                        );
                      },
                    ),
                    _buildProfileOption(
                      context,
                      'Configuración',
                      Icons.settings_outlined,
                      () {
                        // Implementar configuración
                        AlertHelper.showInfoAlert(
                          context, 
                          'Función de configuración próximamente'
                        );
                      },
                    ),
                    _buildProfileOption(
                      context,
                      'Ayuda y Soporte',
                      Icons.help_outline,
                      () {
                        // Implementar ayuda y soporte
                        AlertHelper.showInfoAlert(
                          context, 
                          'Función de ayuda y soporte próximamente'
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    // Cerrar sesión
                    _buildProfileOption(
                      context,
                      'Cerrar Sesión',
                      Icons.logout,
                      () async {
                        final confirm = await AlertHelper.showConfirmAlert(
                          context,
                          '¿Estás seguro que deseas cerrar sesión?',
                        );
                        
                        if (confirm) {
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        }
                      },
                      isLogout: true,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatar(UserModel user, ThemeData theme) {
    if (user.avatarType == 'custom' && user.avatarData != null) {
      return FluttermojiCircleAvatar(
        radius: 60,
      );
    } else if (user.avatarUrl != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(user.avatarUrl!),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          '${user.firstName[0]}${user.lastName[0]}',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }
  }

  Widget _buildProfileOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? theme.colorScheme.error : null,
          fontWeight: isLogout ? FontWeight.bold : null,
        ),
      ),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
