import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/plant_model.dart';
import '../providers/auth_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/device_provider.dart';
import 'plant_detail_page.dart';
import 'add_plant_page.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({Key? key}) : super(key: key);

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initData();
  }

  Future<void> _initData() async {
    if (!_isInitialized) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final plantProvider =
            Provider.of<PlantProvider>(context, listen: false);
        final deviceProvider =
            Provider.of<DeviceProvider>(context, listen: false);

        if (authProvider.user != null) {
          await plantProvider.loadUserPlants(authProvider.user!.uid);
          await deviceProvider.loadUserDevices(authProvider.user!.uid);
        }

        _isInitialized = true;
      } catch (e) {
        if (mounted) {
          AlertHelper.showErrorAlert(
              context, 'Error al cargar datos: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plantProvider = Provider.of<PlantProvider>(context);
    final plants = plantProvider.plants;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Plantas'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              if (authProvider.user != null) {
                await plantProvider.loadUserPlants(authProvider.user!.uid);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : plants.isEmpty
              ? _buildEmptyState(theme)
              : _buildPlantsList(plants, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlantPage(),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No tienes plantas',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Agrega tu primera planta para comenzar a monitorearla',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPlantPage(),
                ),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Agregar Planta'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantsList(List<PlantModel> plants, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user != null) {
          await Provider.of<PlantProvider>(context, listen: false)
              .loadUserPlants(authProvider.user!.uid);
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];
          return _buildPlantCard(plant, theme);
        },
      ),
    );
  }

  Widget _buildPlantCard(PlantModel plant, ThemeData theme) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          _navigateToPlantDetail(plant.id);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la planta o placeholder
            Container(
              height: 150,
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              child: plant.imageUrl != null
                  ? Image.network(
                      plant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.eco,
                            size: 60,
                            color: theme.colorScheme.primary,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.eco,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y tipo
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
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 12),
                  // Fecha de registro
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Registrada el ${_formatDate(plant.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Umbral de riego
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Riego automático: ${plant.wateringThreshold}% humedad',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToPlantDetail(String plantId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantDetailPage(plantId: plantId),
      ),
    );

    // Si se eliminó una planta, recargar la lista
    if (result == true) {
      final plantProvider = Provider.of<PlantProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.user != null) {
        await plantProvider.loadUserPlants(authProvider.user!.uid);
      }
    }
  }
}
