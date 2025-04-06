import 'dart:io';

import 'package:proyecto_jj/data/models/plant_model.dart';
import 'package:proyecto_jj/data/models/reading_model.dart';
import 'package:proyecto_jj/data/models/watering_event_model.dart';
import 'package:proyecto_jj/data/repositories/plant_repository.dart';

class PlantUseCase {
  final PlantRepository _plantRepository;

  PlantUseCase(this._plantRepository);

  Future<List<PlantModel>> getUserPlants(String userId) async {
    return await _plantRepository.getUserPlants(userId);
  }

  Future<PlantModel?> getPlantById(String plantId) async {
    return await _plantRepository.getPlantById(plantId);
  }

  Future<PlantModel> createPlant({
    required String userId,
    required String name,
    required String type,
    required String deviceId,
    File? imageFile,
    int? wateringThreshold,
    int? wateringDuration,
  }) async {
    return await _plantRepository.createPlant(
      userId: userId,
      name: name,
      type: type,
      deviceId: deviceId,
      imageFile: imageFile,
      wateringThreshold: wateringThreshold,
      wateringDuration: wateringDuration,
    );
  }

  Future<PlantModel> updatePlant({
    required String plantId,
    String? name,
    String? type,
    String? deviceId,
    File? imageFile,
    int? wateringThreshold,
    int? wateringDuration,
  }) async {
    return await _plantRepository.updatePlant(
      plantId: plantId,
      name: name,
      type: type,
      deviceId: deviceId,
      imageFile: imageFile,
      wateringThreshold: wateringThreshold,
      wateringDuration: wateringDuration,
    );
  }

  Future<void> deletePlant(String plantId) async {
    await _plantRepository.deletePlant(plantId);
  }

  Future<List<ReadingModel>> getPlantReadings(String plantId,
      {int limit = 10}) async {
    return await _plantRepository.getPlantReadings(plantId, limit: limit);
  }

  Future<List<WateringEventModel>> getWateringHistory(String plantId,
      {int limit = 10}) async {
    return await _plantRepository.getWateringHistory(plantId, limit: limit);
  }

  Future<WateringEventModel> recordManualWatering({
    required String plantId,
    required int duration,
    double? moistureBefore,
  }) async {
    return await _plantRepository.recordManualWatering(
      plantId: plantId,
      duration: duration,
      moistureBefore: moistureBefore,
    );
  }

  // Método para generar datos de prueba
  Future<void> generateMockData(String plantId) async {
    await _plantRepository.addMockReadingData(plantId);
  }

  // Método para verificar y corregir problemas con los eventos de riego
  Future<void> verifyAndFixWateringEvents(String plantId) async {
    await _plantRepository.verifyAndFixWateringEvents(plantId);
  }
}
