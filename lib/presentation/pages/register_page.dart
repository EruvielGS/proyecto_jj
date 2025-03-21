import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/toast.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/widgets/custom_button.dart';
import 'package:proyecto_jj/presentation/widgets/custom_textfield.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
                label: 'First Name', controller: firstNameController),
            SizedBox(height: 16),
            CustomTextField(label: 'Last Name', controller: lastNameController),
            SizedBox(height: 16),
            CustomTextField(label: 'Email', controller: emailController),
            SizedBox(height: 16),
            CustomTextField(
                label: 'Password',
                controller: passwordController,
                obscureText: true),
            SizedBox(height: 16),
            CustomButton(
              text: 'Register',
              onPressed: () async {
                try {
                  await authProvider.signUp(
                    email: emailController.text,
                    password: passwordController.text,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                  );
                  showToast('Registration successful');
                  Navigator.pushReplacementNamed(
                      context, '/home'); // Redirigir a Home
                } catch (e) {
                  showToast('Registration failed: $e', isError: true);
                }
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
