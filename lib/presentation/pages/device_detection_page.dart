import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/device_model.dart';
import '../providers/device_provider.dart';
import '../widgets/custom_button.dart';

class DeviceDetectionPage extends StatefulWidget {
  final String userId;

  const DeviceDetectionPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DeviceDetectionPage> createState() => _DeviceDetectionPageState();
}

class _DeviceDetectionPageState extends State<DeviceDetectionPage> {
  bool _isScanning = false;
  List<DeviceModel> _foundDevices = [];
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Usar Future.microtask para programar la operación después de que se complete el build
    Future.microtask(() => _scanForDevices());
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _scanForDevices() async {
    if (!mounted) return;

    setState(() {
      _isScanning = true;
    });

    try {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      final devices = await deviceProvider.scanForESPDevices();

      if (!mounted) return;

      setState(() {
        _foundDevices = devices;
        _isScanning = false;
      });

      if (devices.isEmpty && mounted) {
        AlertHelper.showInfoAlert(context,
            'No se encontraron dispositivos ESP8266 en la red. Puedes intentar conectarte directamente usando la IP.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isScanning = false;
      });

      AlertHelper.showErrorAlert(
          context, 'Error al escanear dispositivos: ${e.toString()}');
    }
  }

  Future<void> _connectToIP() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      AlertHelper.showWarningAlert(
          context, 'Por favor ingresa una dirección IP válida');
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);
      final device = await deviceProvider.connectToKnownIP(ip);

      setState(() {
        _isScanning = false;
      });

      if (device != null) {
        setState(() {
          _foundDevices = [device];
        });
        // Eliminamos el alert de éxito para simplificar el flujo
      } else {
        AlertHelper.showErrorAlert(
            context, 'No se encontró un dispositivo ESP8266 en la IP $ip');
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      AlertHelper.showErrorAlert(
          context, 'Error al conectar a la IP: ${e.toString()}');
    }
  }

  Future<void> _addDeviceToAccount(DeviceModel device) async {
    try {
      final deviceProvider =
          Provider.of<DeviceProvider>(context, listen: false);

      // Verificar si el dispositivo ya está en la cuenta
      final existingDevice = deviceProvider.devices.firstWhere(
        (d) => d.ipAddress == device.ipAddress || d.id == device.id,
        orElse: () => device,
      );

      if (existingDevice != device) {
        // Si ya existe, simplemente regresar ese dispositivo
        Navigator.pop(context, existingDevice);
        return;
      }

      // Agregar el dispositivo a la cuenta
      final newDevice = await deviceProvider.createDevice(
        userId: widget.userId,
        name: device.name,
        type: device.type,
        ipAddress: device.ipAddress,
      );

      if (newDevice != null) {
        if (mounted) {
          // Regresar inmediatamente con el nuevo dispositivo
          Navigator.pop(context, newDevice);
        }
      } else {
        throw Exception('Error al agregar el dispositivo');
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
            context, 'Error al agregar dispositivo: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Detectar Dispositivos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispositivos ESP8266 Detectados',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Se buscarán dispositivos ESP8266 en tu red WiFi. Asegúrate de que tu dispositivo esté conectado a la misma red.',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 16),

            // Botón para escanear
            CustomButton(
              text: 'Escanear Nuevamente',
              isLoading: _isScanning,
              icon: Icons.refresh,
              onPressed: _scanForDevices,
            ),
            SizedBox(height: 24),

            // Sección para conectar directamente por IP
            Text(
              'Conectar por IP',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Si conoces la IP de tu ESP8266, puedes conectarte directamente:',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      hintText: 'Ej: 192.168.1.100',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isScanning ? null : _connectToIP,
                  child: Text('Conectar'),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Lista de dispositivos encontrados
            Expanded(
              child: _isScanning
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Escaneando la red...',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : _foundDevices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No se encontraron dispositivos',
                                style: theme.textTheme.titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Asegúrate de que tu ESP8266 esté conectado a la misma red WiFi',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _foundDevices.length,
                          itemBuilder: (context, index) {
                            final device = _foundDevices[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.developer_board,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  device.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text('Tipo: ${device.type}'),
                                    SizedBox(height: 2),
                                    Text('IP: ${device.ipAddress}'),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _addDeviceToAccount(device),
                                  child: Text('Agregar'),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
