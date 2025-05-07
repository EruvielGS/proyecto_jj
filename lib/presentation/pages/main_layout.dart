import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:proyecto_jj/presentation/pages/add_plant_page.dart';
import 'package:proyecto_jj/presentation/pages/plants_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  late PageController _pageController;

  final List<Widget> _pages = [
    HomePage(),
    PlantsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Iniciar timer para verificar conexión periódicamente
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddPlantPage()),
    );

    // Si se agregó una planta, navegar a la página de plantas
    if (result == true) {
      _pageController.jumpToPage(1); // Ir a la página de plantas
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Prevenir que el usuario regrese a la pantalla de login con el botón de atrás
      canPop: false,
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _currentIndex,
          height: 60.0,
          items: <Widget>[
            Icon(Icons.home_rounded, size: 30, color: Colors.white),
            Icon(Icons.eco_rounded, size: 30, color: Colors.white),
            Icon(Icons.person_rounded, size: 30, color: Colors.white),
          ],
          color: theme.colorScheme.primary,
          buttonBackgroundColor: theme.colorScheme.primaryContainer,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: Duration(milliseconds: 300),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}
