import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/data/models/user_model.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final UserModel? user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Jardín'),
        automaticallyImplyLeading: false, // Quitar la flecha de retorno
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {
              // Implementar notificaciones
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                    color: theme.colorScheme.onSurface.withAlpha(178), // 0.7 * 255 ≈ 178
                  ),
                ),
                SizedBox(height: 24),
              ],
              
              // Resumen de plantas
              _buildSectionTitle(context, 'Resumen de Plantas'),
              SizedBox(height: 16),
              _buildStatCards(context),
              SizedBox(height: 24),
              
              // Plantas recientes
              _buildSectionTitle(context, 'Plantas Recientes'),
              SizedBox(height: 16),
              _buildRecentPlants(context),
              SizedBox(height: 24),
              
              // Consejos del día
              _buildSectionTitle(context, 'Consejo del Día'),
              SizedBox(height: 16),
              _buildTipCard(context),
            ],
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

  Widget _buildStatCards(BuildContext context) {
    final theme = Theme.of(context);
    
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
                    '5',
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
                    '3',
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

  Widget _buildRecentPlants(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: EdgeInsets.only(right: 16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    color: theme.colorScheme.primaryContainer,
                    child: Center(
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
                          'Planta ${index + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Humedad: ${70 + index * 5}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    final theme = Theme.of(context);
    
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
                  'Consejo de Riego',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'La mayoría de las plantas de interior necesitan ser regadas cuando la capa superior del suelo (2-3 cm) está seca al tacto. Evita el exceso de agua para prevenir la pudrición de raíces.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}