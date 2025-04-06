class PlantModel {
  final String id;
  final String name;
  final String type;
  final String? imageUrl;
  final String deviceId;
  final DateTime createdAt;
  final int wateringThreshold; // Umbral de humedad para riego automático (%)
  final int wateringDuration; // Duración del riego en segundos

  PlantModel({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
    required this.deviceId,
    required this.createdAt,
    this.wateringThreshold = 30, // Por defecto, regar cuando humedad < 30%
    this.wateringDuration = 5, // Por defecto, regar durante 5 segundos
  });

  // Crear una copia del modelo con campos actualizados
  PlantModel copyWith({
    String? name,
    String? type,
    String? imageUrl,
    String? deviceId,
    int? wateringThreshold,
    int? wateringDuration,
  }) {
    return PlantModel(
      id: this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      deviceId: deviceId ?? this.deviceId,
      createdAt: this.createdAt,
      wateringThreshold: wateringThreshold ?? this.wateringThreshold,
      wateringDuration: wateringDuration ?? this.wateringDuration,
    );
  }

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'imageUrl': imageUrl,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
      'wateringThreshold': wateringThreshold,
      'wateringDuration': wateringDuration,
    };
  }

  // Crear desde un mapa de Firestore
  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      imageUrl: map['imageUrl'],
      deviceId: map['deviceId'],
      createdAt: DateTime.parse(map['createdAt']),
      wateringThreshold: map['wateringThreshold'] ?? 30,
      wateringDuration: map['wateringDuration'] ?? 5,
    );
  }
}
