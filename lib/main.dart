import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/theme/app_theme.dart';
import 'package:proyecto_jj/data/repositories/auth_repository.dart';
import 'package:proyecto_jj/domain/use_cases/auth_use_case.dart';
import 'package:proyecto_jj/firebase_options.dart';
import 'package:proyecto_jj/presentation/pages/login_page.dart';
import 'package:proyecto_jj/presentation/pages/main_layout.dart';
import 'package:proyecto_jj/presentation/pages/register_page.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthUseCase(AuthRepository())),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Plant Monitor',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.theme,
            initialRoute: '/login',
            routes: {
              '/login': (context) => LoginPage(),
              '/register': (context) => RegisterPage(),
              '/home': (context) => MainLayout(),
            },
          );
        },
      ),
    );
  }
}
