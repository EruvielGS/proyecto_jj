import 'package:flutter/material.dart';
import 'package:proyecto_jj/data/models/device_model.dart';
import 'package:proyecto_jj/domain/use_cases/device_usecase.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceUseCase _deviceUseCase;

  DeviceProvider(this._deviceUseCase);

  List<DeviceModel> _devices = [];
  List<DeviceModel> get devices => _devices;

  DeviceModel? _selectedDevice;
  DeviceModel? get selectedDevice => _selectedDevice;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Cargar dispositivos de un usuario
  Future<void> loadUserDevices(String userId) async {
    _setLoading(true);
    try {
      _devices = await _deviceUseCase.getUserDevices(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar un dispositivo
  Future<void> selectDevice(String deviceId) async {
    _setLoading(true);
    try {
      _selectedDevice = await _deviceUseCase.getDeviceById(deviceId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Crear un nuevo dispositivo
  Future<DeviceModel?> createDevice({
    required String userId,
    required String name,
    required String type,
    String? ipAddress,
  }) async {
    _setLoading(true);
    try {
      final device = await _deviceUseCase.createDevice(
        userId: userId,
        name: name,
        type: type,
        ipAddress: ipAddress,
      );

      _devices.add(device);
      _error = null;
      notifyListeners();
      return device;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar estado de un dispositivo
  Future<DeviceModel?> updateDeviceStatus(
      String deviceId, DeviceStatus status) async {
    _setLoading(true);
    try {
      final device = await _deviceUseCase.updateDeviceStatus(deviceId, status);

      // Actualizar la lista de dispositivos
      final index = _devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        _devices[index] = device;
      }

      // Actualizar el dispositivo seleccionado si es el mismo
      if (_selectedDevice?.id == deviceId) {
        _selectedDevice = device;
      }

      _error = null;
      notifyListeners();
      return device;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar un dispositivo
  Future<bool> deleteDevice(String deviceId) async {
    _setLoading(true);
    try {
      await _deviceUseCase.deleteDevice(deviceId);

      // Eliminar de la lista de dispositivos
      _devices.removeWhere((d) => d.id == deviceId);

      // Limpiar el dispositivo seleccionado si es el mismo
      if (_selectedDevice?.id == deviceId) {
        _selectedDevice = null;
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Enviar comando de riego a un dispositivo
  Future<bool> sendWateringCommand(
      String deviceId, String plantId, int duration) async {
    _setLoading(true);
    try {
      final success =
          await _deviceUseCase.sendWateringCommand(deviceId, plantId, duration);
      _error = null;
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Generar dispositivos de prueba
  Future<List<DeviceModel>> generateMockDevices(String userId) async {
    _setLoading(true);
    try {
      final devices = await _deviceUseCase.generateMockDevices(userId);
      _devices = devices;
      _error = null;
      notifyListeners();
      return devices;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
