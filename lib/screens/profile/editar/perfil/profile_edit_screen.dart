// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'package:ecommerceassim/screens/screens_index.dart';
import 'package:ecommerceassim/shared/components/bottomNavigation/BottomNavigation.dart';
import 'package:ecommerceassim/shared/core/controllers/profile_controller.dart';
import 'package:ecommerceassim/shared/validation/validate_mixin.dart';
import 'package:flutter/material.dart';
import 'package:ecommerceassim/components/buttons/primary_button.dart';
import 'package:ecommerceassim/components/forms/custom_text_form_field.dart';
import 'package:ecommerceassim/shared/constants/app_text_constants.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';
import 'package:ecommerceassim/components/appBar/custom_app_bar.dart';
import 'package:ecommerceassim/shared/core/user_storage.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen>
    with ValidationMixin {
  final UserStorage userStorage = UserStorage();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  var phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool isEditing = false;
  bool isLoading = true;
  bool isSaving = false;
  String errorMessage = '';
  int selectedIndex = 3;

  String originalName = '';
  String originalPhone = '';
  String originalEmail = '';

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback para evitar chamar setState durante a construção
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserDetails();
    });
  }

  void loadUserDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final profileController = Provider.of<ProfileController>(context, listen: false);
      final userData = await profileController.getUserProfile();
      
      setState(() {
        originalName = userData['name'] ?? '';
        originalPhone = userData['phone'] ?? '';
        originalEmail = userData['email'] ?? '';
        nameController.text = originalName;
        phoneController.text = originalPhone;
        emailController.text = originalEmail;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar dados do perfil';
        isLoading = false;
      });
      print('Error fetching user details: $e');
    }
  }

  Future<void> saveUserProfile() async {
    print('Iniciando saveUserProfile, isEditing: $isEditing');
    
    if (!isEditing) return;
    
    print('Validando formulário');
    if (!_formKey.currentState!.validate()) {
      print('Formulário inválido');
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      print('Obtendo token e ID do usuário');
      String userToken = await userStorage.getUserToken();
      String userId = await userStorage.getUserId();
      print('Token obtido: ${userToken.substring(0, 10)}... (parcial)');
      print('ID obtido: $userId');
      
      // Formatar o telefone
      print('Telefone original: ${phoneController.text}');
      String cleanPhone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      print('Telefone limpo: $cleanPhone');
      String formattedPhone = cleanPhone;
      if (cleanPhone.length >= 11) {
        formattedPhone = "(${cleanPhone.substring(0, 2)}) ${cleanPhone.substring(2, 7)}-${cleanPhone.substring(7)}";
        print('Telefone formatado: $formattedPhone');
      } else {
        print('AVISO: Telefone com menos de 11 dígitos');
      }
      
      // Construir o payload
      final url = Uri.parse('$kBaseURL/users/$userId');
      print('URL: $url');
      final payload = {
        'name': nameController.text,
        'telefone': formattedPhone,
        'email': emailController.text,
        'ativo': true,
        'roles': [5]
      };
      
      print('Enviando dados para atualização: $payload');
      
      print('Iniciando requisição PATCH');
      final response = await http.patch(
        url,
        body: json.encode(payload),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );
      
      print('Resposta recebida: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        print('Atualizando dados locais');
        await userStorage.saveUserCredentials(id: userId, token: userToken, nome: nameController.text);
        
        setState(() {
          isEditing = false;
          isSaving = false;
          originalName = nameController.text;
          originalPhone = phoneController.text;
          originalEmail = emailController.text;
        });
        
        print('Exibindo SnackBar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        print('Navegando para tela de perfil');
        Navigator.pushNamed(context, Screens.profile);
      } else {
        setState(() {
          isSaving = false;
          errorMessage = 'Não foi possível atualizar o perfil';
        });
        
        print('Erro ao atualizar perfil: Status code ${response.statusCode}');
        print('Resposta do servidor: ${response.body}');
        
        // Reverte as alterações em caso de erro
        revertChanges();
      }
    } catch (e, stackTrace) {
      print('Exceção capturada: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isSaving = false;
        errorMessage = 'Erro ao atualizar perfil: $e';
      });
      
      // Reverte as alterações em caso de erro
      revertChanges();
    }
  }

  void revertChanges() {
    setState(() {
      nameController.text = originalName;
      phoneController.text = originalPhone;
      emailController.text = originalEmail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavigation(paginaSelecionada: 3),
      body: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: kDetailColor))
              : Column(
                  children: [
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Nome',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CustomTextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              enabled: isEditing,
                              validateForm: (value) => isValidName(value),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Telefone',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CustomTextFormField(
                              controller: phoneController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              maskFormatter: phoneFormatter,
                              enabled: isEditing,
                              validateForm: (value) => isValidPhone(value),
                            ),
                            const SizedBox(height: 16),
                            // Campo de email
                            const Text(
                              'Email',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            CustomTextFormField(
                              controller: emailController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              enabled: isEditing,
                              validateForm: (value) => isEmailValid(value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isEditing)
                      PrimaryButton(
                        onPressed: () {
                          setState(() {
                            isEditing = true;
                          });
                        },
                        text: 'Editar Perfil',
                        color: kDetailColor,
                      ),
                    if (isEditing)
                      PrimaryButton(
                        onPressed: isSaving ? null : saveUserProfile,
                        text: isSaving ? 'Salvando...' : 'Salvar',
                        color: kDetailColor,
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
  
  // Use isEmailValid em vez de isValidEmail para evitar conflito com o ValidationMixin
  String? isEmailValid(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, informe seu email';
    }
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Por favor, informe um email válido';
    }
    return null;
  }
}