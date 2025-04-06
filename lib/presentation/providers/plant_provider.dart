import 'dart:io';
import 'package:flutter/material.dart';
import 'package:proyecto_jj/data/models/plant_model.dart';
import 'package:proyecto_jj/data/models/reading_model.dart';
import 'package:proyecto_jj/data/models/watering_event_model.dart';
import 'package:proyecto_jj/domain/use_cases/plant_usecase.dart';

class PlantProvider with ChangeNotifier {
  final PlantUseCase _plantUseCase;

  PlantProvider(this._plantUseCase);

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

  // Cargar plantas de un usuario
  Future<void> loadUserPlants(String userId) async {
    _setLoading(true);
    try {
      _plants = await _plantUseCase.getUserPlants(userId);
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
