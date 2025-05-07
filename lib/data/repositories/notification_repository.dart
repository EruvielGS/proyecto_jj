import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Obtener notificaciones de un usuario
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener notificaciones: $e');
      throw e;
    }
  }

  // Crear una nueva notificación
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? plantId,
    String? imageUrl,
  }) async {
    try {
      final String notificationId = _uuid.v4();

      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        plantId: plantId,
        imageUrl: imageUrl,
      );

      await _firestore.collection('notifications').doc(notificationId).set(
            notification.toMap(),
          );

      return notification;
    } catch (e) {
      print('Error al crear notificación: $e');
      throw e;
    }
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      throw e;
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error al marcar todas las notificaciones como leídas: $e');
      throw e;
    }
  }

  // Eliminar una notificación
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error al eliminar notificación: $e');
      throw e;
    }
  }

  // Eliminar todas las notificaciones de un usuario
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error al eliminar todas las notificaciones: $e');
      throw e;
    }
  }

  // Crear notificación de riego automático
  Future<NotificationModel> createWateringNotification({
    required String userId,
    required String plantName,
    required String plantId,
    String? imageUrl,
  }) async {
    return await createNotification(
      userId: userId,
      title: 'Riego Automático',
      message: 'Tu planta "$plantName" ha sido regada automáticamente.',
      type: NotificationType.watering,
      plantId: plantId,
      imageUrl: imageUrl,
    );
  }

  // Crear notificación de advertencia de humedad
  Future<NotificationModel> createHumidityWarningNotification({
    required String userId,
    required String plantName,
    required String plantId,
    required double humidity,
    String? imageUrl,
  }) async {
    return await createNotification(
      userId: userId,
      title: 'Advertencia de Humedad',
      message:
          'Tu planta "$plantName" tiene un nivel de humedad bajo ($humidity%). Considera regarla pronto.',
      type: NotificationType.humidity,
      plantId: plantId,
      imageUrl: imageUrl,
    );
  }
}
