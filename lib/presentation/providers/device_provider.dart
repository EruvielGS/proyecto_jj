import 'package:flutter/material.dart';
import 'package:proyecto_jj/data/models/device_model.dart';
import 'package:proyecto_jj/domain/use_cases/device_usecase.dart';
import 'package:proyecto_jj/services/esp_service.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceUseCase _deviceUseCase;
  final ESPService _espService = ESPService();

  DeviceProvider(this._deviceUseCase) {
    // Inicializar el servicio ESP
    _espService.initialize();

    // Suscribirse a cambios en la conexión
    _espService.connectionStatus.listen((isConnected) {
      if (isConnected) {
        print('Dispositivo ESP conectado');
      } else {
        print('Dispositivo ESP desconectado');
      }
      notifyListeners();
    });
  }

  List<DeviceModel> _devices = [];
  List<DeviceModel> get devices => _devices;

  DeviceModel? _selectedDevice;
  DeviceModel? get selectedDevice => _selectedDevice;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Verificar si hay un ESP conectado
  bool get isESPConnected => _espService.isConnected;
  String? get connectedESPIP => _espService.connectedDeviceIP;

  // Cargar dispositivos de un usuario
  Future<void> loadUserDevices(String userId) async {
    _setLoading(true);
    try {
      // Cargar dispositivos de la base de datos
      _devices = await _deviceUseCase.getUserDevices(userId);

      // Escanear la red en busca de dispositivos ESP
      final espDevices = await _espService.scanNetwork();

      // Verificar si los dispositivos ESP ya están en la lista
      for (var espDevice in espDevices) {
        final existingIndex = _devices.indexWhere((d) => d.id == espDevice.id);
        if (existingIndex >= 0) {
          // Actualizar el dispositivo existente
          _devices[existingIndex] = espDevice;
        } else {
          // Agregar el nuevo dispositivo a la base de datos
          await _deviceUseCase.createDevice(
            userId: userId,
            name: espDevice.name,
            type: espDevice.type,
            ipAddress: espDevice.ipAddress,
          );

          // Agregar a la lista local
          _devices.add(espDevice);
        }
      }

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

      // Si el dispositivo tiene IP, intentar conectar
      if (_selectedDevice?.ipAddress != null) {
        await _espService.connectToDevice(_selectedDevice!);
      }

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
      // Si es un ESP conectado, usar el servicio ESP
      if (_espService.isConnected &&
          _espService.connectedDeviceId == deviceId) {
        final success =
            await _espService.sendWateringCommand(plantId, duration);
        _error = null;
        return success;
      } else {
        // Usar el método simulado para otros dispositivos
        final success = await _deviceUseCase.sendWateringCommand(
            deviceId, plantId, duration);
        _error = null;
        return success;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Configurar riego automático
  Future<bool> configureAutomaticWatering(
      String deviceId, String plantId, int threshold, int duration) async {
    _setLoading(true);
    try {
      // Si es un ESP conectado, usar el servicio ESP
      if (_espService.isConnected &&
          _espService.connectedDeviceId == deviceId) {
        final success = await _espService.configureAutomaticWatering(
            plantId, threshold, duration);
        _error = null;
        return success;
      } else {
        // No hay implementación para dispositivos simulados
        _error = null;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Escanear la red en busca de dispositivos ESP
  Future<List<DeviceModel>> scanForESPDevices() async {
    bool wasLoading = _isLoading;

    if (!wasLoading) {
      _isLoading = true;
      // Usar Future.microtask para evitar notificar durante el build
      Future.microtask(() => notifyListeners());
    }

    try {
      final devices = await _espService.scanNetwork();
      _error = null;

      if (!wasLoading) {
        _isLoading = false;
        notifyListeners();
      }

      return devices;
    } catch (e) {
      _error = e.toString();

      if (!wasLoading) {
        _isLoading = false;
        notifyListeners();
      }

      return [];
    }
  }

  // Conectar a una IP conocida
  Future<DeviceModel?> connectToKnownIP(String ip) async {
    _setLoading(true);
    try {
      final device = await _espService.connectToKnownIP(ip);
      _error = null;
      _setLoading(false);
      return device;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
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
    if (_isLoading != loading) {
      _isLoading = loading;
      // Usar Future.microtask para evitar notificar durante el build
      Future.microtask(() => notifyListeners());
    }
  }

  @override
  void dispose() {
    _espService.dispose();
    super.dispose();
  }
}
