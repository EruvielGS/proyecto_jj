import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/presentation/widgets/custom_textfield.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool _resetSent = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final email = emailController.text.trim();
      print('Intentando enviar correo de recuperación a: $email');

      await Provider.of<AuthProvider>(context, listen: false)
          .resetPassword(email);

      if (mounted) {
        setState(() {
          _resetSent = true;
          isLoading = false;
        });

        // Mostrar mensaje de éxito con instrucciones adicionales
        AlertHelper.showSuccessAlert(context,
            'Se ha enviado un correo de recuperación a $email\n\nSi no lo encuentras, revisa tu carpeta de spam o correo no deseado.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // Mostrar mensaje de error con sugerencias
        AlertHelper.showErrorAlert(context,
            'Error: ${e.toString()}\n\nSugerencias:\n- Verifica que el correo sea correcto\n- Revisa tu conexión a internet\n- Intenta nuevamente más tarde');

        print('Error detallado: $e');
      }
    }
  }

  Widget _buildAlternativeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 24),
        Text(
          '¿No recibiste el correo?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.help_outline),
          label: Text('Opciones alternativas'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Opciones alternativas'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Si no recibes el correo de recuperación:'),
                    SizedBox(height: 8),
                    Text('• Revisa tu carpeta de spam'),
                    Text('• Verifica que el correo sea correcto'),
                    Text('• Intenta con otro correo electrónico'),
                    Text('• Contacta al soporte técnico'),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text('Cerrar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Recuperar Contraseña'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  // Icono
                  Center(
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Título
                  Text(
                    'Recupera tu contraseña',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),

                  // Instrucciones
                  Text(
                    _resetSent
                        ? 'Se ha enviado un correo electrónico con instrucciones para restablecer tu contraseña. Por favor, revisa tu bandeja de entrada.'
                        : 'Ingresa tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(178),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  if (!_resetSent) ...[
                    // Campo de correo electrónico
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
                    SizedBox(height: 24),

                    // Botón de enviar
                    CustomButton(
                      text: 'Enviar Instrucciones',
                      isLoading: isLoading,
                      icon: Icons.send,
                      onPressed: _sendResetEmail,
                    ),

                    // Opciones alternativas
                    _buildAlternativeOptions(),
                  ] else ...[
                    // Botón para volver a intentar
                    CustomButton(
                      text: 'Volver a Intentar',
                      icon: Icons.refresh,
                      onPressed: () {
                        setState(() {
                          _resetSent = false;
                          emailController.clear();
                        });
                      },
                    ),
                  ],

                  SizedBox(height: 16),

                  // Botón para volver
                  CustomButton(
                    text: 'Volver al Inicio de Sesión',
                    isOutlined: true,
                    icon: Icons.arrow_back,
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
