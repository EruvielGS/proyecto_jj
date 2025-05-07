import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/plant_model.dart';
import 'package:proyecto_jj/data/models/reading_model.dart';
import 'package:proyecto_jj/data/models/watering_event_model.dart';
import '../providers/plant_provider.dart';
import '../providers/device_provider.dart';
import 'edit_plant_page.dart';

class PlantDetailPage extends StatefulWidget {
  final String plantId;

  const PlantDetailPage({
    Key? key,
    required this.plantId,
  }) : super(key: key);

  @override
  State<PlantDetailPage> createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends State<PlantDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isInitialized = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      // Usar Future.microtask para evitar llamar a setState durante el build
      Future.microtask(() => _loadPlantData());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlantData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      // Cargar datos de la planta
      await plantProvider.selectPlant(widget.plantId);

      // Intentar obtener datos actuales del ESP si está conectado
      await plantProvider.fetchCurrentData(widget.plantId);
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
            context, 'Error al cargar datos de la planta: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      // Obtener datos actuales del ESP si está conectado
      await plantProvider.fetchCurrentData(widget.plantId);

      // Recargar datos de la planta
      await plantProvider.loadPlantData(widget.plantId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos actualizados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
            context, 'Error al actualizar datos: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _triggerManualWatering() async {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);

    final plant = plantProvider.selectedPlant;
    if (plant == null) return;

    final readings = plantProvider.readings;
    final currentMoisture =
        readings.isNotEmpty ? readings.first.soilMoisture : null;

    try {
      // Mostrar diálogo de confirmación
      final confirm = await AlertHelper.showConfirmAlert(
        context,
        '¿Estás seguro que deseas regar esta planta manualmente?\n\nDuración: ${plant.wateringDuration} segundos',
        confirmBtnText: 'Regar',
        confirmBtnColor: Theme.of(context).colorScheme.primary,
      );

      if (!confirm) return;

      // Mostrar diálogo de carga
      AlertHelper.showLoadingAlert(context, 'Enviando comando de riego...');

      // Enviar comando al dispositivo
      final success = await deviceProvider.sendWateringCommand(
          plant.deviceId, plant.id, plant.wateringDuration);

      // Cerrar diálogo de carga
      Navigator.pop(context);

      if (success) {
        // Registrar evento de riego
        final event = await plantProvider.recordManualWatering(
          plantId: plant.id,
          duration: plant.wateringDuration,
          moistureBefore: currentMoisture,
        );

        if (mounted) {
          AlertHelper.showSuccessAlert(
              context, 'Riego manual activado correctamente');

          // Recargar datos explícitamente después de un breve retraso
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              _refreshData();
            }
          });
        }
      } else {
        throw Exception('No se pudo enviar el comando de riego');
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
            context, 'Error al activar riego manual: ${e.toString()}');
      }
    }
  }

  Future<void> _deletePlant() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar planta'),
        content: Text(
            '¿Estás seguro de que deseas eliminar esta planta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await Provider.of<PlantProvider>(context, listen: false)
            .deletePlant(widget.plantId);

        if (success) {
          if (mounted) {
            // Mostrar mensaje de éxito y luego navegar hacia atrás
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Planta eliminada correctamente'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );

            // Esperar un momento y luego navegar hacia atrás
            Future.delayed(Duration(milliseconds: 1200), () {
              if (mounted) {
                Navigator.pop(context,
                    true); // Pasar true para indicar que se eliminó la planta
              }
            });
          }
        } else {
          throw Exception('No se pudo eliminar la planta');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          AlertHelper.showErrorAlert(
              context, 'Error al eliminar planta: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isESPConnected = Provider.of<PlantProvider>(context).isESPConnected;

    // Usar Consumer para evitar reconstrucciones innecesarias
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? Text('Detalle de Planta')
            : Consumer<PlantProvider>(
                builder: (context, plantProvider, _) {
                  final plant = plantProvider.selectedPlant;
                  return Text(plant?.name ?? 'Detalle de Planta');
                },
              ),
        actions: [
          if (!_isLoading) ...[
            IconButton(
              icon: _isRefreshing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshData,
              tooltip: 'Actualizar datos',
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                final plantProvider =
                    Provider.of<PlantProvider>(context, listen: false);
                final plant = plantProvider.selectedPlant;
                if (plant != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPlantPage(plantId: plant.id),
                    ),
                  ).then((_) => _loadPlantData());
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  await _deletePlant();
                } else if (value == 'refresh') {
                  await _refreshData();
                } else if (value == 'generate_mock') {
                  final plantProvider =
                      Provider.of<PlantProvider>(context, listen: false);
                  final plant = plantProvider.selectedPlant;
                  if (plant != null) {
                    await plantProvider.generateMockData(plant.id);
                    if (mounted) {
                      AlertHelper.showSuccessAlert(
                          context, 'Datos de prueba generados correctamente');
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: theme.colorScheme.primary),
                      SizedBox(width: 8),
                      Text('Actualizar datos'),
                    ],
                  ),
                ),
                if (!isESPConnected)
                  PopupMenuItem(
                    value: 'generate_mock',
                    child: Row(
                      children: [
                        Icon(Icons.data_array,
                            color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Text('Generar datos de prueba'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: theme.colorScheme.error),
                      SizedBox(width: 8),
                      Text('Eliminar planta'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<PlantProvider>(
              builder: (context, plantProvider, _) {
                final plant = plantProvider.selectedPlant;

                if (plant == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Planta no encontrada',
                          style: theme.textTheme.headlineSmall,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Volver'),
                        ),
                      ],
                    ),
                  );
                }

                return _buildContent(plant, plantProvider, theme);
              },
            ),
      floatingActionButton: _isLoading
          ? null
          : Consumer<PlantProvider>(
              builder: (context, plantProvider, _) {
                final plant = plantProvider.selectedPlant;
                if (plant == null) return SizedBox.shrink();

                return FloatingActionButton.extended(
                  onPressed: _triggerManualWatering,
                  icon: Icon(Icons.water_drop),
                  label: Text('Regar Ahora'),
                  backgroundColor: theme.colorScheme.primary,
                );
              },
            ),
    );
  }

  Widget _buildContent(
      PlantModel plant, PlantProvider plantProvider, ThemeData theme) {
    return Column(
      children: [
        // Encabezado con imagen y datos básicos
        _buildHeader(plant, theme),

        // Pestañas
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Resumen'),
            Tab(text: 'Gráficos'),
            Tab(text: 'Historial'),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(178),
          indicatorColor: theme.colorScheme.primary,
        ),

        // Contenido de las pestañas
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(plant, plantProvider, theme),
              // Modificar el método _buildChartsTab para manejar mejor la falta de datos
              _buildChartsTab(plantProvider, theme),
              _buildHistoryTab(plantProvider, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(PlantModel plant, ThemeData theme) {
    return Consumer<PlantProvider>(
      builder: (context, plantProvider, _) {
        final readings = plantProvider.readings;
        final currentMoisture =
            readings.isNotEmpty ? readings.first.soilMoisture : null;

        return Container(
          color: theme.colorScheme.primaryContainer.withAlpha(76),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen de la planta
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(128),
                    width: 2,
                  ),
                ),
                child: plant.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.eco,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.eco,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              SizedBox(width: 16),

              // Información básica
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      plant.type,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(178),
                      ),
                    ),
                    SizedBox(height: 8),
                    if (currentMoisture != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 16,
                            color: _getMoistureColor(currentMoisture, theme),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Humedad actual: ${currentMoisture.toStringAsFixed(1)}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getMoistureColor(currentMoisture, theme),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(
      PlantModel plant, PlantProvider plantProvider, ThemeData theme) {
    final readings = plantProvider.readings;
    final wateringEvents = plantProvider.wateringEvents;

    final currentMoisture =
        readings.isNotEmpty ? readings.first.soilMoisture : null;
    final currentTemp = readings.isNotEmpty ? readings.first.temperature : null;
    final currentLight = readings.isNotEmpty ? readings.first.lightLevel : null;

    final lastWatering =
        wateringEvents.isNotEmpty ? wateringEvents.first : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado actual
          Text(
            'Estado Actual',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              // Humedad
              Expanded(
                child: _buildStatusCard(
                  theme,
                  icon: Icons.water_drop,
                  title: 'Humedad',
                  value: currentMoisture != null
                      ? '${currentMoisture.toStringAsFixed(1)}%'
                      : 'N/A',
                  color: currentMoisture != null
                      ? _getMoistureColor(currentMoisture, theme)
                      : theme.colorScheme.onSurface.withAlpha(128),
                ),
              ),
              SizedBox(width: 16),

              // Temperatura
              Expanded(
                child: _buildStatusCard(
                  theme,
                  icon: Icons.thermostat,
                  title: 'Temperatura',
                  value: currentTemp != null
                      ? '${currentTemp.toStringAsFixed(1)}°C'
                      : 'N/A',
                  color: currentTemp != null
                      ? _getTemperatureColor(currentTemp, theme)
                      : theme.colorScheme.onSurface.withAlpha(128),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Row(
            children: [
              // Luz
              Expanded(
                child: _buildStatusCard(
                  theme,
                  icon: Icons.wb_sunny,
                  title: 'Nivel de Luz',
                  value: currentLight != null
                      ? '${currentLight.toStringAsFixed(1)}%'
                      : 'N/A',
                  color: currentLight != null
                      ? _getLightColor(currentLight, theme)
                      : theme.colorScheme.onSurface.withAlpha(128),
                ),
              ),
              SizedBox(width: 16),

              // Último riego
              Expanded(
                child: _buildStatusCard(
                  theme,
                  icon: Icons.history,
                  title: 'Último Riego',
                  value: lastWatering != null
                      ? _formatDateTime(lastWatering.timestamp)
                      : 'Sin registros',
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Configuración de riego
          Text(
            'Configuración de Riego',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Parámetros de Riego Automático',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Umbral de humedad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Umbral de humedad:'),
                      Text(
                        '${plant.wateringThreshold}%',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Duración del riego
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duración del riego:'),
                      Text(
                        '${plant.wateringDuration} segundos',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Estado actual
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: currentMoisture != null &&
                                  currentMoisture < plant.wateringThreshold
                              ? Colors.red
                              : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentMoisture != null &&
                                  currentMoisture < plant.wateringThreshold
                              ? 'La planta necesita riego (humedad por debajo del umbral)'
                              : 'La planta tiene suficiente humedad',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: currentMoisture != null &&
                                    currentMoisture < plant.wateringThreshold
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Consejos
          Text(
            'Consejos de Cuidado',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Recomendaciones',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Consejos basados en el tipo de planta
                  _buildCareAdvice(plant.type, currentMoisture, currentTemp,
                      currentLight, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modificar el método _buildChartsTab para manejar mejor la falta de datos
  Widget _buildChartsTab(PlantProvider plantProvider, ThemeData theme) {
    final readings = plantProvider.readings;

    if (readings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(128),
            ),
            SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Aún no se han registrado lecturas para esta planta',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              label: Text('Actualizar datos'),
            ),
          ],
        ),
      );
    }

    // Ordenar lecturas por fecha (más antiguas primero)
    final sortedReadings = List<ReadingModel>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Humedad del Suelo',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Últimas ${sortedReadings.length} lecturas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(178),
            ),
          ),
          SizedBox(height: 16),

          // Gráfico de humedad
          Container(
            height: 250,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: sortedReadings.length >= 2
                ? LineChart(_createMoistureChart(sortedReadings, theme))
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 48,
                          color: theme.colorScheme.primary.withAlpha(128),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Se necesitan al menos 2 lecturas para mostrar el gráfico',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
          ),
          SizedBox(height: 24),

          // Gráfico de temperatura si hay datos
          if (sortedReadings.any((r) => r.temperature != null)) ...[
            Text(
              'Temperatura',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Últimas 24 horas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(178),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 250,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                _createTemperatureChart(sortedReadings, theme),
              ),
            ),
            SizedBox(height: 24),
          ],

          // Gráfico de nivel de luz si hay datos
          if (sortedReadings.any((r) => r.lightLevel != null)) ...[
            Text(
              'Nivel de Luz',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Últimas 24 horas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(178),
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 250,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                _createLightChart(sortedReadings, theme),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Modificar el método _buildHistoryTab para mostrar un mensaje de depuración
  Widget _buildHistoryTab(PlantProvider plantProvider, ThemeData theme) {
    final wateringEvents = plantProvider.wateringEvents;

    // Añadir mensaje de depuración
    print('Building history tab with ${wateringEvents.length} watering events');

    if (wateringEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.primary.withAlpha(128),
            ),
            SizedBox(height: 16),
            Text(
              'No hay registros de riego',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Aún no se han registrado eventos de riego para esta planta',
              textAlign: TextAlign.center,
            ),
            // Añadir botón para recargar datos
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _loadPlantData();
              },
              icon: Icon(Icons.refresh),
              label: Text('Recargar datos'),
            ),
            // Añadir botón para generar datos de prueba
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final plantProvider =
                      Provider.of<PlantProvider>(context, listen: false);
                  final plant = plantProvider.selectedPlant;
                  if (plant != null) {
                    AlertHelper.showLoadingAlert(
                        context, 'Generando datos de prueba...');
                    await plantProvider.generateMockData(plant.id);
                    if (context.mounted) {
                      Navigator.pop(context); // Cerrar diálogo de carga
                      AlertHelper.showSuccessAlert(
                          context, 'Datos de prueba generados correctamente');
                      // Recargar datos después de generar
                      _loadPlantData();
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Cerrar diálogo de carga
                    AlertHelper.showErrorAlert(
                        context, 'Error al generar datos: ${e.toString()}');
                  }
                }
              },
              icon: Icon(Icons.data_array),
              label: Text('Generar datos de prueba'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: wateringEvents.length,
      itemBuilder: (context, index) {
        final event = wateringEvents[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                event.type == WateringType.automatic
                    ? Icons.auto_mode
                    : Icons.water_drop,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              event.type == WateringType.automatic
                  ? 'Riego Automático'
                  : 'Riego Manual',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(_formatDateTime(event.timestamp)),
                SizedBox(height: 2),
                Text('Duración: ${event.duration} segundos'),
                if (event.moistureBefore != null) ...[
                  SizedBox(height: 2),
                  Text(
                      'Humedad antes: ${event.moistureBefore!.toStringAsFixed(1)}%'),
                ],
                if (event.moistureAfter != null) ...[
                  SizedBox(height: 2),
                  Text(
                      'Humedad después: ${event.moistureAfter!.toStringAsFixed(1)}%'),
                ],
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareAdvice(
    String plantType,
    double? moisture,
    double? temperature,
    double? light,
    ThemeData theme,
  ) {
    List<Widget> advices = [];

    // Consejos basados en el tipo de planta
    if (plantType.toLowerCase().contains('cactus') ||
        plantType.toLowerCase().contains('suculenta')) {
      advices.add(_buildAdviceItem(
        'Riego poco frecuente. Los cactus y suculentas almacenan agua en sus tejidos.',
        theme,
      ));
    } else if (plantType.toLowerCase().contains('helecho')) {
      advices.add(_buildAdviceItem(
        'Mantén el suelo constantemente húmedo. Los helechos prefieren ambientes húmedos.',
        theme,
      ));
    } else if (plantType.toLowerCase().contains('orquídea')) {
      advices.add(_buildAdviceItem(
        'Riega solo cuando el sustrato esté seco. Las orquídeas son sensibles al exceso de agua.',
        theme,
      ));
    }

    // Consejos basados en las lecturas actuales
    if (moisture != null) {
      if (moisture < 30) {
        advices.add(_buildAdviceItem(
          'La humedad del suelo es baja. Considera regar pronto.',
          theme,
        ));
      } else if (moisture > 80) {
        advices.add(_buildAdviceItem(
          'El suelo está muy húmedo. Evita regar hasta que se seque un poco.',
          theme,
        ));
      }
    }

    if (temperature != null) {
      if (temperature < 15) {
        advices.add(_buildAdviceItem(
          'La temperatura es baja. La mayoría de las plantas de interior prefieren temperaturas entre 18-24°C.',
          theme,
        ));
      } else if (temperature > 30) {
        advices.add(_buildAdviceItem(
          'La temperatura es alta. Considera mover la planta a un lugar más fresco.',
          theme,
        ));
      }
    }

    if (light != null) {
      if (light < 20) {
        advices.add(_buildAdviceItem(
          'El nivel de luz es bajo. Considera mover la planta a un lugar más iluminado.',
          theme,
        ));
      } else if (light > 80) {
        advices.add(_buildAdviceItem(
          'El nivel de luz es alto. Si es luz directa, podría dañar algunas plantas.',
          theme,
        ));
      }
    }

    // Si no hay consejos específicos
    if (advices.isEmpty) {
      advices.add(_buildAdviceItem(
        'Mantén un riego regular y observa cómo responde tu planta a las condiciones actuales.',
        theme,
      ));
    }

    return Column(children: advices);
  }

  Widget _buildAdviceItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  LineChartData _createMoistureChart(
      List<ReadingModel> readings, ThemeData theme) {
    final spots = readings.map((reading) {
      // Convertir timestamp a horas (eje X)
      final hours = reading.timestamp.hour.toDouble();
      return FlSpot(hours, reading.soilMoisture);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: 4,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text('${hour}h'),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text('${value.toInt()}%'),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withAlpha(51),
          ),
        ),
      ],
    );
  }

  LineChartData _createTemperatureChart(
      List<ReadingModel> readings, ThemeData theme) {
    final spots =
        readings.where((reading) => reading.temperature != null).map((reading) {
      final hours = reading.timestamp.hour.toDouble();
      return FlSpot(hours, reading.temperature!);
    }).toList();

    // Encontrar min y max para el eje Y
    double minTemp = 15;
    double maxTemp = 30;
    if (spots.isNotEmpty) {
      final temps = spots.map((spot) => spot.y).toList();
      minTemp = (temps.reduce((a, b) => a < b ? a : b) - 2).clamp(0, 50);
      maxTemp = (temps.reduce((a, b) => a > b ? a : b) + 2).clamp(0, 50);
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        verticalInterval: 4,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text('${hour}h'),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 5,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text('${value.toInt()}°C'),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: 23,
      minY: minTemp,
      maxY: maxTemp,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withAlpha(51),
          ),
        ),
      ],
    );
  }

  LineChartData _createLightChart(
      List<ReadingModel> readings, ThemeData theme) {
    final spots =
        readings.where((reading) => reading.lightLevel != null).map((reading) {
      final hours = reading.timestamp.hour.toDouble();
      return FlSpot(hours, reading.lightLevel!);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        verticalInterval: 4,
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 4,
            getTitlesWidget: (value, meta) {
              final hour = value.toInt();
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text('${hour}h'),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                space: 8.0,
                child: Text('${value.toInt()}%'),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d), width: 1),
      ),
      minX: 0,
      maxX: 23,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.amber,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.amber.withAlpha(51),
          ),
        ),
      ],
    );
  }

  Color _getMoistureColor(double moisture, ThemeData theme) {
    if (moisture < 30) {
      return Colors.red;
    } else if (moisture < 50) {
      return Colors.orange;
    } else if (moisture < 70) {
      return theme.colorScheme.primary;
    } else {
      return Colors.blue;
    }
  }

  Color _getTemperatureColor(double temp, ThemeData theme) {
    if (temp < 15) {
      return Colors.blue;
    } else if (temp < 20) {
      return theme.colorScheme.primary;
    } else if (temp < 28) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  Color _getLightColor(double light, ThemeData theme) {
    if (light < 20) {
      return Colors.grey;
    } else if (light < 50) {
      return theme.colorScheme.primary;
    } else if (light < 80) {
      return Colors.amber;
    } else {
      return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
