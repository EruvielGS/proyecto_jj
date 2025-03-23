import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:proyecto_jj/core/utils/alert_helper.dart';
import 'package:proyecto_jj/data/models/user_model.dart';
import 'package:proyecto_jj/presentation/providers/auth_provider.dart';
import 'package:proyecto_jj/presentation/widgets/custom_button.dart';
import 'package:proyecto_jj/presentation/widgets/custom_textfield.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  File? _selectedImage;
  bool _showCustomAvatar = false;

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      firstNameController.text = user.firstName;
      lastNameController.text = user.lastName;
      
      if (user.avatarType == 'custom') {
        setState(() {
          _showCustomAvatar = true;
        });
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  // Mejorar el método _pickImage para validar el formato de la imagen
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Reducir tamaño para optimizar
        maxHeight: 1024,
        imageQuality: 85, // Calidad ligeramente reducida para optimizar
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _showCustomAvatar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
          context, 
          'Error al seleccionar imagen: ${e.toString()}'
        );
      }
    }
  }

  // Modificar el método _saveProfile para mostrar alertas de éxito y manejar errores mejor
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Actualizar datos básicos del perfil
      await authProvider.updateUserProfile(
        firstName: firstNameController.text,
        lastName: lastNameController.text,
      );
      
      // Actualizar avatar si se seleccionó una imagen
      if (_selectedImage != null) {
        await authProvider.updateUserAvatar(_selectedImage!);
      }
      
      // Actualizar avatar personalizado si se está usando fluttermoji
      if (_showCustomAvatar) {
        final fluttermojiData = await FluttermojiFunctions().encodeMySVGtoMap();
        await authProvider.updateCustomAvatar(fluttermojiData);
      }
      
      if (mounted) {
        AlertHelper.showSuccessAlert(
          context, 
          'Perfil actualizado correctamente'
        );
        
        // Esperar un momento para que el usuario vea el mensaje antes de volver
        // await Future.delayed(Duration(seconds: 1));
        // if (mounted) {
        //   Navigator.pop(context);
        // }
      }
    } catch (e) {
      if (mounted) {
        AlertHelper.showErrorAlert(
          context, 
          'Error al actualizar el perfil: ${e.toString()}'
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).user;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Editar Perfil')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                
                // Avatar section
                _buildAvatarSection(user, theme),
                
                SizedBox(height: 32),
                
                // Información personal
                CustomTextField(
                  label: 'Nombre',
                  controller: firstNameController,
                  prefixIcon: Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                CustomTextField(
                  label: 'Apellido',
                  controller: lastNameController,
                  prefixIcon: Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu apellido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),
                
                // Botón guardar
                CustomButton(
                  text: 'Guardar Cambios',
                  isLoading: isLoading,
                  icon: Icons.save,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(UserModel user, ThemeData theme) {
    return Column(
      children: [
        // Avatar actual o seleccionado
        if (_selectedImage != null)
          CircleAvatar(
            radius: 60,
            backgroundImage: FileImage(_selectedImage!),
          )
        else if (_showCustomAvatar)
          FluttermojiCircleAvatar(
            radius: 60,
          )
        else if (user.avatarUrl != null)
          CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage(user.avatarUrl!),
          )
        else
          CircleAvatar(
            radius: 60,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${user.firstName[0]}${user.lastName[0]}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        
        SizedBox(height: 16),
        
        // Opciones de avatar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Galería'),
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.emoji_emotions),
              label: Text('Avatar'),
              onPressed: () {
                setState(() {
                  _showCustomAvatar = true;
                  _selectedImage = null;
                });
                _showFluttermojiCustomizer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        
        // Mostrar el personalizador de fluttermoji si está activo
        if (_showCustomAvatar) ...[
          SizedBox(height: 16),
          ElevatedButton(
            child: Text('Personalizar Avatar'),
            onPressed: _showFluttermojiCustomizer,
          ),
        ],
      ],
    );
  }

  void _showFluttermojiCustomizer() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personaliza tu Avatar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Expanded(
                  child: FluttermojiCustomizer(
                    scaffoldWidth: MediaQuery.of(context).size.width * 0.9,
                    autosave: true,
                    theme: FluttermojiThemeData(
                      primaryBgColor: Theme.of(context).colorScheme.background,
                      secondaryBgColor: Theme.of(context).colorScheme.surface,
                      iconColor: Theme.of(context).colorScheme.primary,
                      selectedIconColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}