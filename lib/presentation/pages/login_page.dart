import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/presentation/pages/forgot_password_page.dart';
import 'package:proyecto_jj/presentation/pages/register_page.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/widgets/custom_button.dart';
import 'package:proyecto_jj/presentation/widgets/custom_textfield.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.05),
                  // Logo o Imagen
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 24),
                  // Título
                  Text(
                    'Bienvenido',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Inicia sesión para monitorear tus plantas',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  // Campos de formulario
                  CustomTextField(
                    label: 'Correo electrónico',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  CustomTextField(
                    label: 'Contraseña',
                    controller: passwordController,
                    obscureText: true,
                    prefixIcon: Icon(Icons.lock_outline),
                    isPassword: true, // Indicamos que es un campo de contraseña
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12),
                  // Olvidé mi contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Botón de inicio de sesión
                  CustomButton(
                    text: 'Iniciar Sesión',
                    isLoading: isLoading,
                    icon: Icons.login,
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          await authProvider.signIn(
                              emailController.text, passwordController.text);
                          if (mounted) {
                            AlertHelper.showSuccessAlert(
                                context, '¡Inicio de sesión exitoso!');
                            Navigator.pushReplacementNamed(context, '/home');
                          }
                        } catch (e) {
                          if (mounted) {
                            AlertHelper.showErrorAlert(context,
                                'Error al iniciar sesión: ${e.toString()}');
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      }
                    },
                  ),
                  SizedBox(height: 24),
                  // Registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes una cuenta?',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                          );
                        },
                        child: Text('Regístrate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
