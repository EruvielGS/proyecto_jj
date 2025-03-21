import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/toast.dart';
import 'package:proyecto_jj/presentation/pages/register_page.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/widgets/custom_button.dart';
import 'package:proyecto_jj/presentation/widgets/custom_textfield.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(label: 'Email', controller: emailController),
            SizedBox(height: 16),
            CustomTextField(
                label: 'Password',
                controller: passwordController,
                obscureText: true),
            SizedBox(height: 16),
            CustomButton(
              text: 'Login',
              onPressed: () async {
                try {
                  await authProvider.signIn(
                      emailController.text, passwordController.text);
                  showToast('Login successful');
                  Navigator.pushReplacementNamed(
                      context, '/home'); // Redirigir a Home
                } catch (e) {
                  showToast('Login failed: $e', isError: true);
                }
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RegisterPage()));
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
