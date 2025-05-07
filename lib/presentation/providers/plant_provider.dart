import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/data/models/plant_model.dart';
import 'package:proyecto_jj/data/models/reading_model.dart';
import 'package:proyecto_jj/data/models/watering_event_model.dart';
import 'package:proyecto_jj/domain/use_cases/plant_usecase.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/providers/notification_provider.dart';
import 'package:proyecto_jj/services/esp_service.dart';
import 'package:proyecto_jj/main.dart';

class PlantProvider with ChangeNotifier {
  final PlantUseCase _plantUseCase;
  final ESPService _espService = ESPService();

  PlantProvider(this._plantUseCase) {
    // Suscribirse a nuevas lecturas del ESP
    _espService.newReading.listen((reading) {
      // Si la lectura es para la planta seleccionada, agregarla a la lista
      if (_selectedPlant != null && reading.plantId == _selectedPlant!.id) {
        _readings.insert(0, reading);

        // Guardar la lectura en la base de datos
        _plantUseCase.saveReading(reading);

        // Notificar a los listeners
        notifyListeners();
      }
    });
  }

  List<PlantModel> _plants = [];
  List<PlantModel> get plants => _plants;

  PlantModel? _selectedPlant;
  PlantModel? get selectedPlant => _selectedPlant;

  List<ReadingModel> _readings = [];
  List<ReadingModel> get readings => _readings;

  List<WateringEventModel> _wateringEvents = [];
  List<WateringEventModel> get wateringEvents => _wateringEvents;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Verificar si hay un ESP conectado
  bool get isESPConnected => _espService.isConnected;

  // Cargar plantas de un usuario
  Future<void> loadUserPlants(String userId) async {
    if (_isLoading) return; // Evitar múltiples cargas simultáneas

    _isLoading = true;
    // Notificar fuera del ciclo de build
    Future.microtask(() => notifyListeners());

    try {
      _plants = await _plantUseCase.getUserPlants(userId);

      // Intentar obtener datos actuales para cada planta si hay un ESP conectado
      if (_espService.isConnected) {
        for (var plant in _plants) {
          try {
            final reading = await _espService.fetchSensorData(plant.id);
            if (reading != null) {
              // Guardar la lectura en la base de datos
              await _plantUseCase.saveReading(reading);
            }
          } catch (e) {
            print('Error al obtener datos para planta ${plant.id}: $e');
          }
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading user plants: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Seleccionar una planta y cargar sus datos
  Future<void> selectPlant(String plantId) async {
    _setLoading(true);
    try {
      print('Selecting plant: $plantId');
      _selectedPlant = await _plantUseCase.getPlantById(plantId);
      if (_selectedPlant != null) {
        await loadPlantData(plantId);

        // Si hay un ESP conectado, obtener datos actuales
        if (_espService.isConnected) {
          final reading = await _espService.fetchSensorData(plantId);
          if (reading != null) {
            // Guardar la lectura en la base de datos
            await _plantUseCase.saveReading(reading);

            // Actualizar la lista de lecturas
            _readings.insert(0, reading);
            notifyListeners();
          }
        }
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error selecting plant: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar datos de una planta (lecturas y eventos de riego)
  Future<void> loadPlantData(String plantId) async {
    _setLoading(true);
    try {
      print('Loading data for plant: $plantId');

      // Verificar y corregir problemas con los eventos de riego
      await _plantUseCase.verifyAndFixWateringEvents(plantId);

      // Cargar lecturas y eventos de riego
      _readings = await _plantUseCase.getPlantReadings(plantId, limit: 24);
      _wateringEvents =
          await _plantUseCase.getWateringHistory(plantId, limit: 50);

      // Imprimir información de depuración
      print('Loaded ${_readings.length} readings for plant: $plantId');
      print(
          'Loaded ${_wateringEvents.length} watering events for plant: $plantId');

      if (_wateringEvents.isNotEmpty) {
        print(
            'First watering event: ${_wateringEvents.first.id}, type: ${_wateringEvents.first.type}, timestamp: ${_wateringEvents.first.timestamp}');
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error loading plant data: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Crear una nueva planta
  Future<PlantModel?> createPlant({
    required String userId,
    required String name,
    required String type,
    required String deviceId,
    File? imageFile,
    int? wateringThreshold,
    int? wateringDuration,
  }) async {
    _setLoading(true);
    try {
      final plant = await _plantUseCase.createPlant(
        userId: userId,
        name: name,
        type: type,
        deviceId: deviceId,
        imageFile: imageFile,
        wateringThreshold: wateringThreshold,
        wateringDuration: wateringDuration,
      );

      _plants.add(plant);
      _error = null;
      notifyListeners();

      // Si hay un ESP conectado, configurar el riego automático
      if (_espService.isConnected &&
          _espService.connectedDeviceId == deviceId) {
        await _espService.configureAutomaticWatering(
          plant.id,
          wateringThreshold ?? 30,
          wateringDuration ?? 5,
        );
      }

      return plant;
    } catch (e) {
      _error = e.toString();
      print('Error creating plant: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar una planta existente
  Future<PlantModel?> updatePlant({
    required String plantId,
    String? name,
    String? type,
    String? deviceId,
    File? imageFile,
    int? wateringThreshold,
    int? wateringDuration,
  }) async {
    _setLoading(true);
    try {
      final plant = await _plantUseCase.updatePlant(
        plantId: plantId,
        name: name,
        type: type,
        deviceId: deviceId,
        imageFile: imageFile,
        wateringThreshold: wateringThreshold,
        wateringDuration: wateringDuration,
      );

      // Actualizar la lista de plantas
      final index = _plants.indexWhere((p) => p.id == plantId);
      if (index != -1) {
        _plants[index] = plant;
      }

      // Actualizar la planta seleccionada si es la misma
      if (_selectedPlant?.id == plantId) {
        _selectedPlant = plant;
      }

      _error = null;
      notifyListeners();

      // Si hay un ESP conectado y se actualizaron los parámetros de riego, configurar el riego automático
      if (_espService.isConnected &&
          _espService.connectedDeviceId == deviceId &&
          (wateringThreshold != null || wateringDuration != null)) {
        await _espService.configureAutomaticWatering(
          plantId,
          wateringThreshold ?? plant.wateringThreshold,
          wateringDuration ?? plant.wateringDuration,
        );
      }

      return plant;
    } catch (e) {
      _error = e.toString();
      print('Error updating plant: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar una planta
  Future<bool> deletePlant(String plantId) async {
    _setLoading(true);
    try {
      await _plantUseCase.deletePlant(plantId);

      // Eliminar de la lista de plantas
      _plants.removeWhere((p) => p.id == plantId);

      // Limpiar la planta seleccionada si es la misma
      if (_selectedPlant?.id == plantId) {
        _selectedPlant = null;
        _readings = [];
        _wateringEvents = [];
      }

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      print('Error deleting plant: $_error');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registrar un evento de riego manual
  Future<WateringEventModel?> recordManualWatering({
    required String plantId,
    required int duration,
    double? moistureBefore,
  }) async {
    _setLoading(true);
    try {
      print('Recording manual watering for plant: $plantId');
      final event = await _plantUseCase.recordManualWatering(
        plantId: plantId,
        duration: duration,
        moistureBefore: moistureBefore,
      );

      // Asegurarse de que el evento se añade a la lista local
      _wateringEvents.insert(0, event);

      // Imprimir información de depuración
      print('Manual watering recorded: ${event.id}');
      print('Current watering events count: ${_wateringEvents.length}');

      _error = null;
      notifyListeners();

      // Recargar los datos para asegurar sincronización
      await Future.delayed(Duration(seconds: 1));
      await loadPlantData(plantId);

      return event;
    } catch (e) {
      _error = e.toString();
      print('Error recording manual watering: $_error');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Generar datos de prueba para una planta
  Future<void> generateMockData(String plantId) async {
    _setLoading(true);
    try {
      await _plantUseCase.generateMockData(plantId);
      await loadPlantData(plantId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error generating mock data: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Verificar y corregir problemas con los eventos de riego
  Future<void> verifyAndFixWateringEvents(String plantId) async {
    _setLoading(true);
    try {
      await _plantUseCase.verifyAndFixWateringEvents(plantId);
      await loadPlantData(plantId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error verifying watering events: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Obtener datos actuales del ESP
  Future<ReadingModel?> fetchCurrentData(String plantId) async {
    if (!_espService.isConnected) {
      print('No hay conexión con el ESP');
      return null;
    }

    try {
      final reading = await _espService.fetchSensorData(plantId);
      if (reading != null) {
        // Guardar la lectura en la base de datos
        await _plantUseCase.saveReading(reading);

        // Actualizar la lista de lecturas
        _readings.insert(0, reading);

        // Verificar si se debe generar una notificación de humedad baja
        if (_selectedPlant != null &&
            reading.soilMoisture < _selectedPlant!.wateringThreshold) {
          // Obtener el provider de notificaciones
          final notificationProvider = Provider.of<NotificationProvider>(
              navigatorKey.currentContext!,
              listen: false);
          final authProvider = Provider.of<AuthProvider>(
              navigatorKey.currentContext!,
              listen: false);

          if (authProvider.user != null) {
            await notificationProvider.createHumidityWarningNotification(
              userId: authProvider.user!.uid,
              plantName: _selectedPlant!.name,
              plantId: _selectedPlant!.id,
              humidity: reading.soilMoisture,
              imageUrl: _selectedPlant!.imageUrl,
            );
          }
        }

        notifyListeners();
      }
      return reading;
    } catch (e) {
      print('Error al obtener datos actuales: $e');
      return null;
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
