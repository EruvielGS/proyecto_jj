import 'package:cloud_firestore/cloud_firestore.dart';

enum WateringType { automatic, manual }

class WateringEventModel {
  final String id;
  final String plantId;
  final DateTime timestamp;
  final WateringType type;
  final int duration; // Duración en segundos
  final double? moistureBefore; // Humedad antes del riego
  final double? moistureAfter; // Humedad después del riego

  WateringEventModel({
    required this.id,
    required this.plantId,
    required this.timestamp,
    required this.type,
    required this.duration,
    this.moistureBefore,
    this.moistureAfter,
  });

  // Convertir a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'timestamp': timestamp.toIso8601String(),
      'type': type == WateringType.automatic
          ? 'automatic'
          : 'manual', // Usar strings simples en lugar de enum.toString()
      'duration': duration,
      'moistureBefore': moistureBefore,
      'moistureAfter': moistureAfter,
    };
  }

  // Mejorar el manejo de errores en el modelo WateringEventModel
  factory WateringEventModel.fromMap(Map<String, dynamic> map) {
    try {
      // Verificar que los campos requeridos existan
      if (map['id'] == null ||
          map['plantId'] == null ||
          map['timestamp'] == null ||
          map['type'] == null ||
          map['duration'] == null) {
        print('Watering event missing required fields: $map');
        throw Exception('Watering event missing required fields');
      }

      // Determinar el tipo de riego
      WateringType wateringType;
      if (map['type'] == 'WateringType.automatic' ||
          map['type'] == 'automatic') {
        wateringType = WateringType.automatic;
      } else {
        wateringType = WateringType.manual;
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

      // Parsear duration con manejo de errores
      int duration;
      try {
        duration = map['duration'] is int
            ? map['duration']
            : int.parse(map['duration'].toString());
      } catch (e) {
        print('Error parsing duration: ${map['duration']}');
        duration = 5; // Valor por defecto
      }

      // Parsear moistureBefore con manejo de errores
      double? moistureBefore;
      if (map['moistureBefore'] != null) {
        try {
          moistureBefore = map['moistureBefore'] is double
              ? map['moistureBefore']
              : double.parse(map['moistureBefore'].toString());
        } catch (e) {
          print('Error parsing moistureBefore: ${map['moistureBefore']}');
        }
      }

      // Parsear moistureAfter con manejo de errores
      double? moistureAfter;
      if (map['moistureAfter'] != null) {
        try {
          moistureAfter = map['moistureAfter'] is double
              ? map['moistureAfter']
              : double.parse(map['moistureAfter'].toString());
        } catch (e) {
          print('Error parsing moistureAfter: ${map['moistureAfter']}');
        }
      }

      return WateringEventModel(
        id: map['id'],
        plantId: map['plantId'],
        timestamp: timestamp,
        type: wateringType,
        duration: duration,
        moistureBefore: moistureBefore,
        moistureAfter: moistureAfter,
      );
    } catch (e) {
      print('Error creating WateringEventModel from map: $e');
      print('Map data: $map');
      rethrow;
    }
  }
}
