import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/data/models/plant_model.dart';
import 'package:proyecto_jj/data/models/reading_model.dart';
import 'package:proyecto_jj/data/models/user_model.dart';
import 'package:proyecto_jj/presentation/pages/notifications_page.dart';
import 'package:proyecto_jj/presentation/pages/plant_detail_page.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/providers/notification_provider.dart';
import 'package:proyecto_jj/presentation/providers/plant_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Inicializar como false para que _loadData pueda ejecutarse
    _isLoading = false;
    // Usar microtask para evitar llamar a setState durante el build
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    if (_isLoading) return; // Evitar múltiples cargas simultáneas

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);

      if (authProvider.user != null) {
        await plantProvider.loadUserPlants(authProvider.user!.uid);
      }
    } catch (e) {
      print('Error al cargar datos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final plantProvider = Provider.of<PlantProvider>(context);
    final UserModel? user = authProvider.user;
    final List<PlantModel> plants = plantProvider.plants;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Jardín'),
        automaticallyImplyLeading: false, // Quitar la flecha de retorno
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_outlined),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    final unreadCount = notificationProvider.unreadCount;
                    if (unreadCount == 0) return SizedBox.shrink();

                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saludo al usuario
                      if (user != null) ...[
                        Text(
                          '¡Hola, ${user.firstName}!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bienvenido a tu jardín inteligente',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withAlpha(178), // 0.7 * 255 ≈ 178
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      // Resumen de plantas
                      _buildSectionTitle(context, 'Resumen de Plantas'),
                      SizedBox(height: 16),
                      _buildStatCards(context, plants),
                      SizedBox(height: 24),

                      // Plantas recientes
                      _buildSectionTitle(context, 'Plantas Recientes'),
                      SizedBox(height: 16),
                      _buildRecentPlants(context, plants),
                      SizedBox(height: 24),

                      // Consejos del día
                      _buildSectionTitle(context, 'Consejo del Día'),
                      SizedBox(height: 16),
                      _buildTipCard(context),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatCards(BuildContext context, List<PlantModel> plants) {
    final theme = Theme.of(context);

    // Calcular plantas que necesitan agua
    int plantsNeedingWater = 0;
    for (var plant in plants) {
      final readings = _getLatestReadingsForPlant(plant.id);
      if (readings.isNotEmpty) {
        final latestReading = readings.first;
        if (latestReading.soilMoisture < plant.wateringThreshold) {
          plantsNeedingWater++;
        }
      }
    }

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.eco_rounded,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${plants.length}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Plantas Activas'),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$plantsNeedingWater',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Necesitan Agua'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPlants(BuildContext context, List<PlantModel> plants) {
    final theme = Theme.of(context);
    final plantProvider = Provider.of<PlantProvider>(context);

    // Ordenar plantas por fecha de creación (más recientes primero)
    final sortedPlants = List<PlantModel>.from(plants)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Mostrar solo las 5 plantas más recientes
    final recentPlants = sortedPlants.take(5).toList();

    if (recentPlants.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.eco_outlined,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              'No tienes plantas registradas',
              style: theme.textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tu primera planta para comenzar a monitorearla',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentPlants.length,
        itemBuilder: (context, index) {
          final plant = recentPlants[index];
          final readings = _getLatestReadingsForPlant(plant.id);
          final currentMoisture =
              readings.isNotEmpty ? readings.first.soilMoisture : null;

          return Container(
            width: 160,
            margin: EdgeInsets.only(right: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailPage(plantId: plant.id),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 100,
                      color: theme.colorScheme.primaryContainer,
                      child: plant.imageUrl != null
                          ? Image.network(
                              plant.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.eco,
                                    size: 40,
                                    color: theme.colorScheme.primary,
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Icon(
                                Icons.eco,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plant.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            currentMoisture != null
                                ? 'Humedad: ${currentMoisture.toStringAsFixed(1)}%'
                                : 'Sin datos',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    final theme = Theme.of(context);

    // Lista de consejos
    final tips = [
      'La mayoría de las plantas de interior necesitan ser regadas cuando la capa superior del suelo (2-3 cm) está seca al tacto.',
      'Evita el exceso de agua para prevenir la pudrición de raíces.',
      'La luz indirecta es ideal para muchas plantas de interior.',
      'Rota tus plantas regularmente para que crezcan de manera uniforme.',
      'Las plantas tropicales prefieren ambientes húmedos. Considera usar un humidificador.',
      'Limpia las hojas de tus plantas regularmente para eliminar el polvo y permitir una mejor fotosíntesis.',
      'Fertiliza tus plantas durante su temporada de crecimiento (primavera y verano).',
      'Observa los signos de plagas como manchas, hojas amarillentas o insectos.',
    ];

    // Seleccionar un consejo aleatorio
    final randomTip = tips[DateTime.now().millisecondsSinceEpoch % tips.length];

    return Card(
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
                  'Consejo de Cuidado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              randomTip,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // Método para obtener las últimas lecturas de una planta
  List<ReadingModel> _getLatestReadingsForPlant(String plantId) {
    final plantProvider = Provider.of<PlantProvider>(context, listen: false);

    // Si la planta seleccionada es la que buscamos, usar sus lecturas
    if (plantProvider.selectedPlant?.id == plantId) {
      return plantProvider.readings;
    }

    // Si no, intentar obtener las lecturas (esto podría requerir cargar los datos)
    return [];
  }
}
