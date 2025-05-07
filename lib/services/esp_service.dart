import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:proyecto_jj/data/models/device_model.dart';
import 'package:proyecto_jj/data/models/reading_model.dart';

class ESPService {
  // Singleton pattern
  static final ESPService _instance = ESPService._internal();
  factory ESPService() => _instance;
  ESPService._internal();

  // Estado de la conexión
  bool _isConnected = false;
  String? _connectedDeviceIP;
  String? _connectedDeviceId;
  Timer? _connectionCheckTimer;
  Timer? _dataFetchTimer;

  // Stream para notificar cambios en la conexión
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  // Stream para notificar nuevas lecturas
  final _newReadingController = StreamController<ReadingModel>.broadcast();
  Stream<ReadingModel> get newReading => _newReadingController.stream;

  // Métodos para obtener el estado actual
  bool get isConnected => _isConnected;
  String? get connectedDeviceIP => _connectedDeviceIP;
  String? get connectedDeviceId => _connectedDeviceId;

  // Iniciar el servicio
  void initialize() {
    // Iniciar timer para verificar conexión periódicamente
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_connectedDeviceIP != null) {
        _checkConnection(_connectedDeviceIP!);
      } else {
        scanNetwork();
      }
    });

    // Iniciar escaneo inicial
    scanNetwork();
  }

  // Detener el servicio
  void dispose() {
    _connectionCheckTimer?.cancel();
    _dataFetchTimer?.cancel();
    _connectionStatusController.close();
    _newReadingController.close();
  }

  // Escanear la red en busca de dispositivos ESP8266
  Future<List<DeviceModel>> scanNetwork() async {
    List<DeviceModel> foundDevices = [];

    try {
      // Verificar que estamos en WiFi
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.wifi) {
        print('No estás conectado a WiFi. No se puede escanear la red.');
        return [];
      }

      // Obtener información de la red WiFi
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();

      if (wifiIP == null) {
        print('No se pudo obtener la IP WiFi');
        return [];
      }

      print('IP WiFi: $wifiIP');

      // Extraer el prefijo de la red (los primeros 3 octetos)
      final ipParts = wifiIP.split('.');
      if (ipParts.length != 4) {
        print('Formato de IP inesperado: $wifiIP');
        return [];
      }

      final networkPrefix = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
      print('Escaneando red: $networkPrefix.*');

      // Intentar primero con la IP conocida del ESP8266 (si la conocemos)
      // Puedes agregar aquí la IP de tu ESP8266 si la conoces
      final knownIPs = [
        '$networkPrefix.1', // Router/Gateway común
        '$networkPrefix.100', // IP común para ESP8266
        '$networkPrefix.101', // Otra IP común
        '$networkPrefix.102', // Otra IP común
        '$networkPrefix.103', // Otra IP común
        '$networkPrefix.104', // Otra IP común
      ];

      // Intentar primero con las IPs conocidas
      for (final ip in knownIPs) {
        print('Intentando con IP conocida: $ip');
        final device = await _checkIfESP(ip);
        if (device != null) {
          foundDevices.add(device);
          print('Dispositivo encontrado en IP conocida: $ip');
        }
      }

      // Si no encontramos dispositivos en las IPs conocidas, escanear un rango más amplio
      if (foundDevices.isEmpty) {
        print(
            'No se encontraron dispositivos en IPs conocidas, escaneando rango completo...');

        // Lista para almacenar futuros de escaneo
        List<Future<DeviceModel?>> scanFutures = [];

        // Escanear un rango más amplio (1-254)
        for (int i = 1; i <= 254; i++) {
          final ip = '$networkPrefix.$i';
          // Saltarse las IPs que ya verificamos
          if (!knownIPs.contains(ip)) {
            scanFutures.add(_checkIfESP(ip));
          }

          // Procesar en lotes para no sobrecargar la red
          if (i % 10 == 0 || i == 254) {
            print('Escaneando IPs $networkPrefix.${i - 9} a $networkPrefix.$i');
            final results = await Future.wait(scanFutures)
                .timeout(Duration(seconds: 5), onTimeout: () {
              return List<DeviceModel?>.filled(scanFutures.length, null);
            });

            // Filtrar resultados nulos
            final devices = results
                .where((device) => device != null)
                .cast<DeviceModel>()
                .toList();
            foundDevices.addAll(devices);

            // Si encontramos dispositivos, podemos detener el escaneo
            if (devices.isNotEmpty) {
              print('Dispositivos encontrados, deteniendo escaneo');
              break;
            }

            // Limpiar la lista para el próximo lote
            scanFutures = [];
          }
        }
      }

      print('Dispositivos ESP encontrados: ${foundDevices.length}');

      // Si encontramos dispositivos, conectar al primero
      if (foundDevices.isNotEmpty) {
        await connectToDevice(foundDevices.first);
      }

      return foundDevices;
    } catch (e) {
      print('Error al escanear la red: $e');
      return [];
    }
  }

  // Verificar si una IP corresponde a un ESP8266
  Future<DeviceModel?> _checkIfESP(String ip) async {
    try {
      print('Verificando IP: $ip');
      // Intentar conectar al endpoint /info del ESP8266 con un timeout más corto
      final response = await http
          .get(
            Uri.parse('http://$ip/info'),
          )
          .timeout(Duration(milliseconds: 500));

      if (response.statusCode == 200) {
        try {
          print('Respuesta recibida de $ip: ${response.body}');
          final data = json.decode(response.body);

          // Verificar si la respuesta tiene el formato esperado
          if (data['device_type'] != null &&
              data['device_id'] != null &&
              data['name'] != null) {
            print('ESP encontrado en $ip: ${data['name']}');

            return DeviceModel(
              id: data['device_id'],
              name: data['name'],
              type: data['device_type'],
              status: DeviceStatus.connected,
              lastConnection: DateTime.now(),
              ipAddress: ip,
            );
          }
        } catch (e) {
          print('Error al procesar respuesta de $ip: $e');
          return null;
        }
      }
    } catch (e) {
      // Timeout o error de conexión, no es un ESP o no está disponible
      return null;
    }

    return null;
  }

  // Conectar a un dispositivo ESP8266
  Future<bool> connectToDevice(DeviceModel device) async {
    try {
      final ip = device.ipAddress;
      if (ip == null) {
        print('El dispositivo no tiene una dirección IP');
        return false;
      }

      final connected = await _checkConnection(ip);

      if (connected) {
        _connectedDeviceIP = ip;
        _connectedDeviceId = device.id;
        _isConnected = true;
        _connectionStatusController.add(true);

        // Iniciar timer para obtener datos periódicamente
        _dataFetchTimer?.cancel();
        _dataFetchTimer = Timer.periodic(Duration(seconds: 10), (timer) {
          fetchSensorData(device.id);
        });

        print('Conectado exitosamente al dispositivo ${device.name} ($ip)');
        return true;
      } else {
        print('No se pudo conectar al dispositivo ${device.name} ($ip)');
        return false;
      }
    } catch (e) {
      print('Error al conectar al dispositivo: $e');
      return false;
    }
  }

  // Verificar la conexión con un dispositivo
  Future<bool> _checkConnection(String ip) async {
    try {
      final response = await http
          .get(
            Uri.parse('http://$ip/status'),
          )
          .timeout(Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      print('Error al verificar conexión con $ip: $e');

      // Si estábamos conectados, notificar desconexión
      if (_isConnected && _connectedDeviceIP == ip) {
        _isConnected = false;
        _connectionStatusController.add(false);
        _dataFetchTimer?.cancel();
      }

      return false;
    }
  }

  // Método para conectar directamente a una IP conocida
  Future<DeviceModel?> connectToKnownIP(String ip) async {
    try {
      print('Intentando conectar a IP conocida: $ip');
      final device = await _checkIfESP(ip);

      if (device != null) {
        await connectToDevice(device);
        return device;
      }

      return null;
    } catch (e) {
      print('Error al conectar a IP conocida: $e');
      return null;
    }
  }

  // Obtener datos de los sensores
  Future<ReadingModel?> fetchSensorData(String plantId) async {
    if (!_isConnected || _connectedDeviceIP == null) {
      print('No hay conexión con el dispositivo');
      return null;
    }

    try {
      final response = await http
          .get(
            Uri.parse('http://$_connectedDeviceIP/sensors'),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          // Crear modelo de lectura
          final reading = ReadingModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            plantId: plantId,
            timestamp: DateTime.now(),
            soilMoisture: data['soil_moisture']?.toDouble() ?? 0.0,
            temperature: data['temperature']?.toDouble(),
            lightLevel: data['light_level']?.toDouble(),
          );

          // Notificar nueva lectura
          _newReadingController.add(reading);

          return reading;
        } catch (e) {
          print('Error al procesar datos de sensores: $e');
          return null;
        }
      } else {
        print('Error al obtener datos de sensores: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error al obtener datos de sensores: $e');
      return null;
    }
  }

  // Enviar comando de riego
  Future<bool> sendWateringCommand(String plantId, int duration) async {
    if (!_isConnected || _connectedDeviceIP == null) {
      print('No hay conexión con el dispositivo');
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('http://$_connectedDeviceIP/water'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'duration': duration,
              'plant_id': plantId,
            }),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('Comando de riego enviado correctamente');
        return true;
      } else {
        print('Error al enviar comando de riego: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error al enviar comando de riego: $e');
      return false;
    }
  }

  // Configurar riego automático
  Future<bool> configureAutomaticWatering(
      String plantId, int threshold, int duration) async {
    if (!_isConnected || _connectedDeviceIP == null) {
      print('No hay conexión con el dispositivo');
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('http://$_connectedDeviceIP/config'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'plant_id': plantId,
              'watering_threshold': threshold,
              'watering_duration': duration,
            }),
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        print('Configuración de riego automático enviada correctamente');
        return true;
      } else {
        print(
            'Error al enviar configuración de riego automático: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error al enviar configuración de riego automático: $e');
      return false;
    }
  }
}
