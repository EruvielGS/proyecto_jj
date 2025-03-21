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

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (user != null) ...[
              Text('Welcome, ${user.firstName} ${user.lastName}!',
                  style: TextStyle(fontSize: 24)),
              SizedBox(height: 16),
              Text('Email: ${user.email}', style: TextStyle(fontSize: 18)),
            ],
          ],
        ),
      ),
    );
  }
}
