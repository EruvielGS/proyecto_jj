import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingModel {
  final String id;
  final String plantId;
  final DateTime timestamp;
  final double soilMoisture; // Porcentaje de humedad del suelo (0-100)
  final double? temperature; // Temperatura en grados Celsius
  final double? lightLevel; // Nivel de luz (0-100)

  ReadingModel({
    required this.id,
    required this.plantId,
    required this.timestamp,
    required this.soilMoisture,
    this.temperature,
    this.lightLevel,
  });

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'timestamp': timestamp.toIso8601String(),
      'soilMoisture': soilMoisture,
      'temperature': temperature,
      'lightLevel': lightLevel,
    };
  }

  // Crear desde un mapa de Firestore
  factory ReadingModel.fromMap(Map<String, dynamic> map) {
    try {
      // Verificar que los campos requeridos existan
      if (map['id'] == null ||
          map['plantId'] == null ||
          map['timestamp'] == null ||
          map['soilMoisture'] == null) {
        print('Reading missing required fields: $map');
        throw Exception('Reading missing required fields');
      }

      // Parsear timestamp con manejo de errores
      DateTime timestamp;
      try {
        timestamp = map['timestamp'] is String
            ? DateTime.parse(map['timestamp'])
            : (map['timestamp'] as Timestamp).toDate();
      } catch (e) {
        print('Error parsing timestamp: ${map['timestamp']}');
        timestamp = DateTime.now(); // Valor por defecto
      }

      // Parsear soilMoisture con manejo de errores
      double soilMoisture;
      try {
        soilMoisture = map['soilMoisture'] is double
            ? map['soilMoisture']
            : double.parse(map['soilMoisture'].toString());
      } catch (e) {
        print('Error parsing soilMoisture: ${map['soilMoisture']}');
        soilMoisture = 50.0; // Valor por defecto
      }

      // Parsear temperature con manejo de errores
      double? temperature;
      if (map['temperature'] != null) {
        try {
          temperature = map['temperature'] is double
              ? map['temperature']
              : double.parse(map['temperature'].toString());
        } catch (e) {
          print('Error parsing temperature: ${map['temperature']}');
        }
      }

      // Parsear lightLevel con manejo de errores
      double? lightLevel;
      if (map['lightLevel'] != null) {
        try {
          lightLevel = map['lightLevel'] is double
              ? map['lightLevel']
              : double.parse(map['lightLevel'].toString());
        } catch (e) {
          print('Error parsing lightLevel: ${map['lightLevel']}');
        }
      }

      return ReadingModel(
        id: map['id'],
        plantId: map['plantId'],
        timestamp: timestamp,
        soilMoisture: soilMoisture,
        temperature: temperature,
        lightLevel: lightLevel,
      );
    } catch (e) {
      print('Error creating ReadingModel from map: $e');
      print('Map data: $map');
      rethrow;
    }
  }
}
