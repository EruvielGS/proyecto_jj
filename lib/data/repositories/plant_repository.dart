import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/plant_model.dart';
import '../models/reading_model.dart';
import '../models/watering_event_model.dart';

class PlantRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  // Obtener todas las plantas de un usuario
  Future<List<PlantModel>> getUserPlants(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('plants')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => PlantModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error al obtener plantas: $e');
      throw e;
    }
  }

  // Obtener una planta por ID
  Future<PlantModel?> getPlantById(String plantId) async {
    try {
      final doc = await _firestore.collection('plants').doc(plantId).get();
      if (doc.exists) {
        return PlantModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error al obtener planta: $e');
      throw e;
    }
  }

  // Crear una nueva planta
  Future<PlantModel> createPlant({
    required String userId,
    required String name,
    required String type,
    required String deviceId,
    File? imageFile,
    int? wateringThreshold,
    int? wateringDuration,
  }) async {
    try {
      final String plantId = _uuid.v4();
      String? imageUrl;

      // Subir imagen si existe
      if (imageFile != null) {
        imageUrl = await _uploadPlantImage(plantId, imageFile);
      }

      final plant = PlantModel(
        id: plantId,
        name: name,
        type: type,
        imageUrl: imageUrl,
        deviceId: deviceId,
        createdAt: DateTime.now(),
        wateringThreshold: wateringThreshold ?? 30,
        wateringDuration: wateringDuration ?? 5,
      );

      // Guardar en Firestore
      await _firestore.collection('plants').doc(plantId).set({
        ...plant.toMap(),
        'userId': userId,
      });

      return plant;
    } catch (e) {
      print('Error al crear planta: $e');
      throw e;
    }
  }

  // Actualizar una planta existente
  Future<PlantModel> updatePlant({
    required String plantId,
    String? name,
    String? type,
    String? deviceId,
    File? imageFile,
    int? wateringThreshold,
    int? wateringDuration,
  }) async {
    try {
      final docRef = _firestore.collection('plants').doc(plantId);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Planta no encontrada');
      }

      final currentPlant = PlantModel.fromMap(doc.data()!);
      String? imageUrl = currentPlant.imageUrl;

      // Subir nueva imagen si existe
      if (imageFile != null) {
        imageUrl = await _uploadPlantImage(plantId, imageFile);
      }

      final updatedPlant = currentPlant.copyWith(
        name: name,
        type: type,
        imageUrl: imageUrl,
        deviceId: deviceId,
        wateringThreshold: wateringThreshold,
        wateringDuration: wateringDuration,
      );

      // Actualizar en Firestore
      await docRef.update(updatedPlant.toMap());

      return updatedPlant;
    } catch (e) {
      print('Error al actualizar planta: $e');
      throw e;
    }
  }

  // Eliminar una planta
  Future<void> deletePlant(String plantId) async {
    try {
      // Eliminar imagen si existe
      try {
        await _storage.ref('plants/$plantId').delete();
      } catch (e) {
        // Ignorar error si la imagen no existe
      }

      // Eliminar lecturas asociadas
      final readingsSnapshot = await _firestore
          .collection('readings')
          .where('plantId', isEqualTo: plantId)
          .get();

      for (var doc in readingsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Eliminar eventos de riego asociados
      final wateringSnapshot = await _firestore
          .collection('watering_events')
          .where('plantId', isEqualTo: plantId)
          .get();

      for (var doc in wateringSnapshot.docs) {
        await doc.reference.delete();
      }

      // Eliminar la planta
      await _firestore.collection('plants').doc(plantId).delete();
    } catch (e) {
      print('Error al eliminar planta: $e');
      throw e;
    }
  }

  // Modificar el método getPlantReadings para usar el índice correctamente
  Future<List<ReadingModel>> getPlantReadings(String plantId,
      {int limit = 10}) async {
    try {
      print('Fetching readings for plant: $plantId with limit: $limit');

      // Usar la consulta con el índice que acabas de crear
      final snapshot = await _firestore
          .collection('readings')
          .where('plantId', isEqualTo: plantId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      print('Loaded ${snapshot.docs.length} readings for plant: $plantId');

      final readings =
          snapshot.docs.map((doc) => ReadingModel.fromMap(doc.data())).toList();

      // Si no hay lecturas, generar algunas de prueba
      if (readings.isEmpty) {
        print('No readings found, generating mock data');
        await addMockReadingData(plantId);

        // Volver a intentar cargar las lecturas
        final newSnapshot = await _firestore
            .collection('readings')
            .where('plantId', isEqualTo: plantId)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

        return newSnapshot.docs
            .map((doc) => ReadingModel.fromMap(doc.data()))
            .toList();
      }

      return readings;
    } catch (e) {
      print('Error al obtener lecturas: $e');
      throw e;
    }
  }

  // Guardar una lectura
  Future<void> saveReading(ReadingModel reading) async {
    try {
      await _firestore
          .collection('readings')
          .doc(reading.id)
          .set(reading.toMap());
    } catch (e) {
      print('Error al guardar lectura: $e');
      throw e;
    }
  }

  // Modificar el método getWateringHistory para usar el índice correctamente
  Future<List<WateringEventModel>> getWateringHistory(String plantId,
      {int limit = 50}) async {
    try {
      print('Fetching watering history for plant: $plantId with limit: $limit');

      // Usar una consulta más directa
      final snapshot = await _firestore
          .collection('watering_events')
          .where('plantId', isEqualTo: plantId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      print(
          'Watering events found: ${snapshot.docs.length} for plant: $plantId');

      if (snapshot.docs.isEmpty) {
        print('No watering events found for plant: $plantId');
      } else {
        // Imprimir el primer evento para depuración
        print('First watering event: ${snapshot.docs.first.data()}');
      }

      final events = snapshot.docs.map((doc) {
        try {
          return WateringEventModel.fromMap(doc.data());
        } catch (e) {
          print('Error parsing watering event: $e');
          print('Document data: ${doc.data()}');
          rethrow;
        }
      }).toList();

      print('Returning ${events.length} watering events');

      return events;
    } catch (e) {
      print('Error al obtener historial de riego: $e');
      throw e;
    }
  }

  // Registrar un evento de riego manual
  Future<WateringEventModel> recordManualWatering({
    required String plantId,
    required int duration,
    double? moistureBefore,
  }) async {
    try {
      final String eventId = _uuid.v4();
      final now = DateTime.now();

      print('Recording manual watering with ID: $eventId for plant: $plantId');

      final event = WateringEventModel(
        id: eventId,
        plantId: plantId,
        timestamp: now,
        type: WateringType.manual,
        duration: duration,
        moistureBefore: moistureBefore,
      );

      final eventMap = event.toMap();
      print('Saving watering event: $eventMap');

      await _firestore.collection('watering_events').doc(eventId).set(eventMap);

      print('Manual watering recorded successfully');

      return event;
    } catch (e) {
      print('Error al registrar riego manual: $e');
      throw e;
    }
  }

  // Método privado para subir imagen de planta
  Future<String> _uploadPlantImage(String plantId, File imageFile) async {
    try {
      // Obtener la extensión del archivo
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension.isEmpty) extension = 'jpg';

      String fileName = 'plants/$plantId/image.$extension';
      Reference storageRef = _storage.ref().child(fileName);

      SettableMetadata metadata = SettableMetadata(
        contentType: 'image/$extension',
      );

      await storageRef.putFile(imageFile, metadata);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen de planta: $e');
      throw e;
    }
  }

  // Método para simular datos de prueba
  Future<void> addMockReadingData(String plantId) async {
    try {
      print('Adding mock reading data for plant: $plantId');
      final now = DateTime.now();

      // Crear 24 lecturas simuladas (una por hora en el último día)
      for (int i = 0; i < 24; i++) {
        final timestamp = now.subtract(Duration(hours: i));
        final readingId = _uuid.v4();

        // Simular fluctuaciones de humedad (entre 20% y 80%)
        final baseMoisture = 50.0;
        final randomVariation =
            (DateTime.now().millisecondsSinceEpoch % 30) - 15;
        final moisture = (baseMoisture + randomVariation).clamp(20.0, 80.0);

        // Simular temperatura (entre 18°C y 28°C)
        final baseTemp = 23.0;
        final tempVariation = (DateTime.now().millisecondsSinceEpoch % 10) - 5;
        final temperature = baseTemp + tempVariation / 10;

        // Simular nivel de luz (más alto durante el día)
        double lightLevel;
        final hour = timestamp.hour;
        if (hour >= 6 && hour < 18) {
          // Día: 60-90%
          lightLevel = 60.0 + (DateTime.now().millisecondsSinceEpoch % 30);
        } else {
          // Noche: 0-20%
          lightLevel = (DateTime.now().millisecondsSinceEpoch % 20).toDouble();
        }

        final reading = ReadingModel(
          id: readingId,
          plantId: plantId,
          timestamp: timestamp,
          soilMoisture: moisture,
          temperature: temperature,
          lightLevel: lightLevel,
        );

        await _firestore
            .collection('readings')
            .doc(readingId)
            .set(reading.toMap());
      }

      print('Mock reading data added successfully');

      // Verificar si ya existen eventos de riego
      final wateringSnapshot = await _firestore
          .collection('watering_events')
          .where('plantId', isEqualTo: plantId)
          .get();

      if (wateringSnapshot.docs.isEmpty) {
        print('No watering events found, adding mock watering events');

        // Simular algunos eventos de riego
        final wateringTimes = [
          2,
          8,
          14,
          20
        ]; // Horas en las que ocurrió el riego

        for (final hour in wateringTimes) {
          final timestamp =
              DateTime(now.year, now.month, now.day).add(Duration(hours: hour));

          // Solo agregar si está en el pasado
          if (timestamp.isBefore(now)) {
            final eventId = _uuid.v4();
            final isAutomatic =
                hour == 2 || hour == 14; // Riego automático a las 2am y 2pm

            final event = WateringEventModel(
              id: eventId,
              plantId: plantId,
              timestamp: timestamp,
              type: isAutomatic ? WateringType.automatic : WateringType.manual,
              duration: isAutomatic ? 5 : 8, // Duración en segundos
              moistureBefore:
                  25.0 + (DateTime.now().millisecondsSinceEpoch % 10),
              moistureAfter:
                  75.0 + (DateTime.now().millisecondsSinceEpoch % 10),
            );

            await _firestore
                .collection('watering_events')
                .doc(eventId)
                .set(event.toMap());
          }
        }

        print('Mock watering events added successfully');
      } else {
        print('Watering events already exist, skipping mock data');
      }
    } catch (e) {
      print('Error al agregar datos de prueba: $e');
      throw e;
    }
  }

  // Método para verificar y corregir problemas con los eventos de riego
  Future<void> verifyAndFixWateringEvents(String plantId) async {
    try {
      print('Verifying watering events for plant: $plantId');

      // Obtener todos los eventos de riego para esta planta
      final snapshot = await _firestore
          .collection('watering_events')
          .where('plantId', isEqualTo: plantId)
          .get();

      print('Found ${snapshot.docs.length} watering events to verify');

      for (var doc in snapshot.docs) {
        final data = doc.data();
        bool needsUpdate = false;
        Map<String, dynamic> updatedData = Map.from(data);

        // Verificar el campo type
        if (data['type'] == 'WateringType.manual' ||
            data['type'] == 'WateringType.automatic') {
          updatedData['type'] =
              data['type'] == 'WateringType.manual' ? 'manual' : 'automatic';
          needsUpdate = true;
          print('Fixing type field for event: ${doc.id}');
        }

        // Verificar otros campos si es necesario

        // Actualizar el documento si es necesario
        if (needsUpdate) {
          await doc.reference.update(updatedData);
          print('Updated watering event: ${doc.id}');
        }
      }

      print('Verification and fixes completed');
    } catch (e) {
      print('Error verifying watering events: $e');
      throw e;
    }
  }
}
