import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/device_model.dart';
import 'package:proyecto_jj/presentation/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/custom_button.dart';

class AddPlantPage extends StatefulWidget {
  const AddPlantPage({super.key});

  @override
  State<AddPlantPage> createState() => _AddPlantPageState();
}

class _AddPlantPageState extends State<AddPlantPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? selectedDeviceId;
  File? _selectedImage;
  int wateringThreshold = 30; // Valor por defecto
  int wateringDuration = 5; // Valor por defecto
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
            context, 'Error al seleccionar imagen: ${e.toString()}');
      }
    }
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedDeviceId == null) {
      AlertHelper.showWarningAlert(
          context, 'Por favor selecciona un dispositivo');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      if (authProvider.user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final plant = await plantProvider.createPlant(
        userId: authProvider.user!.uid,
        name: nameController.text,
        type: typeController.text,
        deviceId: selectedDeviceId!,
        imageFile: _selectedImage,
        wateringThreshold: wateringThreshold,
        wateringDuration: wateringDuration,
      );

      if (plant != null) {
        // Generar datos de prueba para la planta
        await plantProvider.generateMockData(plant.id);

        if (mounted) {
          AlertHelper.showSuccessAlert(
              context, 'Planta agregada correctamente');

          // Esperar un momento para que el usuario vea el mensaje antes de volver
          await Future.delayed(Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        throw Exception('Error al crear la planta');
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
            context, 'Error al agregar planta: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceProvider = Provider.of<DeviceProvider>(context);
    final devices = deviceProvider.devices;

    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Planta'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la planta
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 50,
                                  color: theme.colorScheme.primary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Agregar foto',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Información de la planta
                Text(
                  'Información de la planta',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                CustomTextField(
                  label: 'Nombre',
                  controller: nameController,
                  prefixIcon: Icon(Icons.eco_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                CustomTextField(
                  label: 'Tipo/Especie',
                  controller: typeController,
                  prefixIcon: Icon(Icons.category_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el tipo o especie';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Selección de dispositivo
                Text(
                  'Dispositivo de monitoreo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                Text(
                  'Selecciona el dispositivo que monitoreará esta planta',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 16),

                if (deviceProvider.isLoading)
                  Center(child: CircularProgressIndicator())
                else if (devices.isEmpty)
                  _buildNoDevicesMessage(theme)
                else
                  _buildDeviceSelector(devices, theme),

                SizedBox(height: 24),

                // Configuración de riego
                Text(
                  'Configuración de riego',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Umbral de humedad
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Umbral de humedad para riego automático',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '$wateringThreshold%',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: wateringThreshold.toDouble(),
                  min: 10,
                  max: 60,
                  divisions: 10,
                  label: '$wateringThreshold%',
                  onChanged: (value) {
                    setState(() {
                      wateringThreshold = value.round();
                    });
                  },
                ),
                Text(
                  'La planta se regará automáticamente cuando la humedad esté por debajo de este valor',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 16),

                // Duración del riego
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Duración del riego',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '$wateringDuration seg',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: wateringDuration.toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  label: '$wateringDuration seg',
                  onChanged: (value) {
                    setState(() {
                      wateringDuration = value.round();
                    });
                  },
                ),
                Text(
                  'Tiempo que durará el riego cuando se active',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: 32),

                // Botón guardar
                CustomButton(
                  text: 'Guardar Planta',
                  isLoading: isLoading,
                  icon: Icons.save,
                  onPressed: _savePlant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDevicesMessage(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.device_unknown,
              size: 48,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: 16),
            Text(
              'No hay dispositivos disponibles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Necesitas agregar al menos un dispositivo para monitorear tus plantas',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                if (authProvider.user != null) {
                  await Provider.of<DeviceProvider>(context, listen: false)
                      .generateMockDevices(authProvider.user!.uid);
                }
              },
              child: Text('Generar dispositivos de prueba'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSelector(List<DeviceModel> devices, ThemeData theme) {
    return Column(
      children: devices.map((device) {
        final isSelected = selectedDeviceId == device.id;
        final isConnected = device.status == DeviceStatus.connected;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? BorderSide(color: theme.colorScheme.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedDeviceId = device.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.developer_board,
                      color: isConnected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          device.type,
                          style: theme.textTheme.bodySmall,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isConnected ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              isConnected ? 'Conectado' : 'Desconectado',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isConnected ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
