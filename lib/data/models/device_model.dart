enum DeviceStatus { connected, disconnected, unknown }

class DeviceModel {
  final String id;
  final String name;
  final String type;
  final DeviceStatus status;
  final DateTime lastConnection;
  final String? ipAddress;

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.status = DeviceStatus.unknown,
    required this.lastConnection,
    this.ipAddress,
  });

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status.toString(),
      'lastConnection': lastConnection.toIso8601String(),
      'ipAddress': ipAddress,
    };
  }

  // Crear desde un mapa de Firestore
  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      status: _parseStatus(map['status']),
      lastConnection: DateTime.parse(map['lastConnection']),
      ipAddress: map['ipAddress'],
    );
  }

  static DeviceStatus _parseStatus(String? status) {
    if (status == 'DeviceStatus.connected') return DeviceStatus.connected;
    if (status == 'DeviceStatus.disconnected') return DeviceStatus.disconnected;
    return DeviceStatus.unknown;
  }
}
