import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { watering, humidity, system, info }

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? plantId;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.plantId,
    this.imageUrl,
  });

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'plantId': plantId,
      'imageUrl': imageUrl,
    };
  }

  // Crear desde un mapa de Firestore
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      message: map['message'],
      type: _parseNotificationType(map['type']),
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
      plantId: map['plantId'],
      imageUrl: map['imageUrl'],
    );
  }

  // Crear una copia con campos actualizados
  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: this.id,
      userId: this.userId,
      title: this.title,
      message: this.message,
      type: this.type,
      timestamp: this.timestamp,
      isRead: isRead ?? this.isRead,
      plantId: this.plantId,
      imageUrl: this.imageUrl,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    if (type == 'NotificationType.watering') return NotificationType.watering;
    if (type == 'NotificationType.humidity') return NotificationType.humidity;
    if (type == 'NotificationType.system') return NotificationType.system;
    if (type == 'NotificationType.info') return NotificationType.info;
    return NotificationType.info;
  }
}
