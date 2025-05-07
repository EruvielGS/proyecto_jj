import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/notification_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

import 'plant_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);

      if (authProvider.user != null) {
        await notificationProvider
            .loadUserNotifications(authProvider.user!.uid);
      }
    } catch (e) {
      print('Error al cargar notificaciones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificaciones'),
        actions: [
          if (notifications.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.done_all),
              tooltip: 'Marcar todas como leídas',
              onPressed: () async {
                if (authProvider.user != null) {
                  await notificationProvider
                      .markAllAsRead(authProvider.user!.uid);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Todas las notificaciones marcadas como leídas'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep),
              tooltip: 'Eliminar todas',
              onPressed: () async {
                final confirm = await AlertHelper.showConfirmAlert(
                  context,
                  '¿Estás seguro que deseas eliminar todas las notificaciones?',
                  confirmBtnText: 'Eliminar',
                  confirmBtnColor: Colors.red,
                );

                if (confirm && authProvider.user != null) {
                  await notificationProvider
                      .deleteAllNotifications(authProvider.user!.uid);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Todas las notificaciones eliminadas'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: notifications.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification, theme);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: theme.colorScheme.primary.withAlpha(128),
          ),
          SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las notificaciones sobre tus plantas aparecerán aquí',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      NotificationModel notification, ThemeData theme) {
    // Determinar el icono según el tipo de notificación
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.watering:
        icon = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case NotificationType.humidity:
        icon = Icons.water_damage;
        iconColor = Colors.orange;
        break;
      case NotificationType.system:
        icon = Icons.system_update;
        iconColor = Colors.purple;
        break;
      case NotificationType.info:
      default:
        icon = Icons.info;
        iconColor = theme.colorScheme.primary;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<NotificationProvider>(context, listen: false)
            .deleteNotification(notification.id);
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: notification.isRead
            ? null
            : theme.colorScheme.primaryContainer.withAlpha(51),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withAlpha(51),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(notification.message),
              SizedBox(height: 4),
              Text(
                _formatDateTime(notification.timestamp),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () async {
            // Marcar como leída
            if (!notification.isRead) {
              await Provider.of<NotificationProvider>(context, listen: false)
                  .markAsRead(notification.id);
            }

            // Si tiene plantId, navegar a la planta
            if (notification.plantId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlantDetailPage(plantId: notification.plantId!),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace un momento';
    }
  }
}
