import 'package:proyecto_jj/data/models/notification_model.dart';
import 'package:proyecto_jj/data/repositories/notification_repository.dart';

class NotificationUseCase {
  final NotificationRepository _notificationRepository;

  NotificationUseCase(this._notificationRepository);

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    return await _notificationRepository.getUserNotifications(userId);
  }

  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? plantId,
    String? imageUrl,
  }) async {
    return await _notificationRepository.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      plantId: plantId,
      imageUrl: imageUrl,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _notificationRepository.markAllAsRead(userId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
  }

  Future<void> deleteAllNotifications(String userId) async {
    await _notificationRepository.deleteAllNotifications(userId);
  }

  Future<NotificationModel> createWateringNotification({
    required String userId,
    required String plantName,
    required String plantId,
    String? imageUrl,
  }) async {
    return await _notificationRepository.createWateringNotification(
      userId: userId,
      plantName: plantName,
      plantId: plantId,
      imageUrl: imageUrl,
    );
  }

  Future<NotificationModel> createHumidityWarningNotification({
    required String userId,
    required String plantName,
    required String plantId,
    required double humidity,
    String? imageUrl,
  }) async {
    return await _notificationRepository.createHumidityWarningNotification(
      userId: userId,
      plantName: plantName,
      plantId: plantId,
      humidity: humidity,
      imageUrl: imageUrl,
    );
  }
}
