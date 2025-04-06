import 'package:proyecto_jj/data/models/device_model.dart';
import 'package:proyecto_jj/data/repositories/device_repository.dart';

class DeviceUseCase {
  final DeviceRepository _deviceRepository;

  DeviceUseCase(this._deviceRepository);

  Future<List<DeviceModel>> getUserDevices(String userId) async {
    return await _deviceRepository.getUserDevices(userId);
  }

  Future<DeviceModel?> getDeviceById(String deviceId) async {
    return await _deviceRepository.getDeviceById(deviceId);
  }

  Future<DeviceModel> createDevice({
    required String userId,
    required String name,
    required String type,
    String? ipAddress,
  }) async {
    return await _deviceRepository.createDevice(
      userId: userId,
      name: name,
      type: type,
      ipAddress: ipAddress,
    );
  }

  Future<DeviceModel> updateDeviceStatus(
      String deviceId, DeviceStatus status) async {
    return await _deviceRepository.updateDeviceStatus(deviceId, status);
  }

  Future<void> deleteDevice(String deviceId) async {
    await _deviceRepository.deleteDevice(deviceId);
  }

  Future<bool> sendWateringCommand(
      String deviceId, String plantId, int duration) async {
    return await _deviceRepository.sendWateringCommand(
        deviceId, plantId, duration);
  }

  // Método para generar datos de prueba
  Future<List<DeviceModel>> generateMockDevices(String userId) async {
    return await _deviceRepository.addMockDevices(userId);
  }
}
