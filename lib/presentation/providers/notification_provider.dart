import 'package:flutter/material.dart';
import 'package:proyecto_jj/data/models/notification_model.dart';
import 'package:proyecto_jj/domain/use_cases/notification_usecase.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationUseCase _notificationUseCase;

  NotificationProvider(this._notificationUseCase);

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Cargar notificaciones de un usuario
  Future<void> loadUserNotifications(String userId) async {
    _setLoading(true);
    try {
      _notifications = await _notificationUseCase.getUserNotifications(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading notifications: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Crear una nueva notificación
  Future<NotificationModel?> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? plantId,
    String? imageUrl,
  }) async {
    _setLoading(true);
    try {
      final notification = await _notificationUseCase.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        plantId: plantId,
        imageUrl: imageUrl,
      );

      _notifications.insert(0, notification);
      _error = null;
      notifyListeners();
      return notification;
    } catch (e) {
      _error = e.toString();
      print('Error creating notification: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationUseCase.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      print('Error marking notification as read: $_error');
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    _setLoading(true);
    try {
      await _notificationUseCase.markAllAsRead(userId);

      _notifications =
          _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error marking all notifications as read: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar una notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationUseCase.deleteNotification(notificationId);

      _notifications.removeWhere((n) => n.id == notificationId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error deleting notification: $_error');
    }
  }

  // Eliminar todas las notificaciones
  Future<void> deleteAllNotifications(String userId) async {
    _setLoading(true);
    try {
      await _notificationUseCase.deleteAllNotifications(userId);

      _notifications = [];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error deleting all notifications: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Crear notificación de riego automático
  Future<NotificationModel?> createWateringNotification({
    required String userId,
    required String plantName,
    required String plantId,
    String? imageUrl,
  }) async {
    _setLoading(true);
    try {
      final notification =
          await _notificationUseCase.createWateringNotification(
        userId: userId,
        plantName: plantName,
        plantId: plantId,
        imageUrl: imageUrl,
      );

      _notifications.insert(0, notification);
      _error = null;
      notifyListeners();
      return notification;
    } catch (e) {
      _error = e.toString();
      print('Error creating watering notification: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Crear notificación de advertencia de humedad
  Future<NotificationModel?> createHumidityWarningNotification({
    required String userId,
    required String plantName,
    required String plantId,
    required double humidity,
    String? imageUrl,
  }) async {
    _setLoading(true);
    try {
      final notification =
          await _notificationUseCase.createHumidityWarningNotification(
        userId: userId,
        plantName: plantName,
        plantId: plantId,
        humidity: humidity,
        imageUrl: imageUrl,
      );

      _notifications.insert(0, notification);
      _error = null;
      notifyListeners();
      return notification;
    } catch (e) {
      _error = e.toString();
      print('Error creating humidity warning notification: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      // Usar Future.microtask para evitar notificar durante el build
      Future.microtask(() => notifyListeners());
    }
  }
}
