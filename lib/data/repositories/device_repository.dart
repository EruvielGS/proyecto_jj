import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  // Obtener todos los dispositivos de un usuario
  Future<List<DeviceModel>> getUserDevices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('devices')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => DeviceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener dispositivos: $e');
      throw e;
    }
  }

  // Obtener un dispositivo por ID
  Future<DeviceModel?> getDeviceById(String deviceId) async {
    try {
      final doc = await _firestore.collection('devices').doc(deviceId).get();
      if (doc.exists) {
        return DeviceModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener dispositivo: $e');
      throw e;
    }
  }

  // Crear un nuevo dispositivo
  Future<DeviceModel> createDevice({
    required String userId,
    required String name,
    required String type,
    String? ipAddress,
  }) async {
    try {
      final String deviceId = _uuid.v4();

      final device = DeviceModel(
        id: deviceId,
        name: name,
        type: type,
        status: DeviceStatus.disconnected,
        lastConnection: DateTime.now(),
        ipAddress: ipAddress,
      );

      // Guardar en Firestore
      await _firestore.collection('devices').doc(deviceId).set({
        ...device.toMap(),
        'userId': userId,
      });

      return device;
    } catch (e) {
      print('Error al crear dispositivo: $e');
      throw e;
    }
  }

  // Actualizar estado de un dispositivo
  Future<DeviceModel> updateDeviceStatus(
      String deviceId, DeviceStatus status) async {
    try {
      final docRef = _firestore.collection('devices').doc(deviceId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Dispositivo no encontrado');
      }

      await docRef.update({
        'status': status.toString(),
        'lastConnection': DateTime.now().toIso8601String(),
      });

      final updatedDoc = await docRef.get();
      return DeviceModel.fromMap(updatedDoc.data()!);
    } catch (e) {
      print('Error al actualizar estado del dispositivo: $e');
      throw e;
    }
  }

  // Eliminar un dispositivo
  Future<void> deleteDevice(String deviceId) async {
    try {
      await _firestore.collection('devices').doc(deviceId).delete();
    } catch (e) {
      print('Error al eliminar dispositivo: $e');
      throw e;
    }
  }

  // Método para simular datos de prueba
  Future<List<DeviceModel>> addMockDevices(String userId) async {
    try {
      List<DeviceModel> devices = [];

      // Crear dispositivo ESP32
      final esp32Id = _uuid.v4();
      final esp32 = DeviceModel(
        id: esp32Id,
        name: 'ESP32 Principal',
        type: 'ESP32',
        status: DeviceStatus.connected,
        lastConnection: DateTime.now(),
        ipAddress: '192.168.1.100',
      );

      await _firestore.collection('devices').doc(esp32Id).set({
        ...esp32.toMap(),
        'userId': userId,
      });
      devices.add(esp32);

      // Crear dispositivo ESP8266
      final esp8266Id = _uuid.v4();
      final esp8266 = DeviceModel(
        id: esp8266Id,
        name: 'ESP8266 Secundario',
        type: 'ESP8266',
        status: DeviceStatus.disconnected,
        lastConnection: DateTime.now().subtract(Duration(days: 2)),
        ipAddress: '192.168.1.101',
      );

      await _firestore.collection('devices').doc(esp8266Id).set({
        ...esp8266.toMap(),
        'userId': userId,
      });
      devices.add(esp8266);

      return devices;
    } catch (e) {
      print('Error al agregar dispositivos de prueba: $e');
      throw e;
    }
  }

  // Simular envío de comando de riego a un dispositivo
  Future<bool> sendWateringCommand(
      String deviceId, String plantId, int duration) async {
    try {
      // En una implementación real, aquí se enviaría una solicitud HTTP al dispositivo ESP
      // o se publicaría un mensaje en un tema MQTT

      print(
          'Enviando comando de riego al dispositivo $deviceId para la planta $plantId durante $duration segundos');

      // Simular un retraso en la comunicación
      await Future.delayed(Duration(seconds: 1));

      // Simular éxito (90% de probabilidad)
      final success = (DateTime.now().millisecondsSinceEpoch % 10) < 9;

      if (success) {
        print('Comando de riego enviado con éxito');
      } else {
        print('Error al enviar comando de riego');
        throw Exception('Error de comunicación con el dispositivo');
      }

      return success;
    } catch (e) {
      print('Error al enviar comando de riego: $e');
      throw e;
    }
  }
}
