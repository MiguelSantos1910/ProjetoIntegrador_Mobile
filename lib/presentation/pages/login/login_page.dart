import 'package:flutter/material.dart';

import 'package:mobile_integrador/data/repositories/usuario_service.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/routes/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final UsuariosService _usuariosService = UsuariosService();

  bool _carregando = false;
  bool _mostrarSenha = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usuariosService.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _carregando) {
      return;
    }

    setState(() {
      _carregando = true;
    });

    try {
      // Autentica o usuário na API.
      final tokens = await _usuariosService.authToken(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Recupera o token de acesso JWT.
      final accessToken = tokens['access']?.toString();

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('A API não retornou um token de acesso válido.');
      }

      final username = _usernameController.text.trim();

      // Redireciona para a Home enviando o token JWT.
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.home,
        arguments: {'accessToken': accessToken, 'username': username},
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível entrar: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  InputDecoration _decoracaoCampo({
    required String label,
    required IconData icone,
    Widget? sufixo,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icone, color: AppColors.mainColor),
      suffixIcon: sufixo,
      filled: true,
      fillColor: AppColors.lightBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.mainColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Identidade visual.
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.mainColor.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Easy Asset',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Gestão de ativos simplificada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Cartão de login.
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCards,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bem-vindo de volta!',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const Text(
                                  'Entre com seus dados para continuar.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),

                                const SizedBox(height: 28),

                                const Text(
                                  'Nome de usuário',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 9),

                                TextFormField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: _decoracaoCampo(
                                    label: 'Digite seu usuário',
                                    icone: Icons.person_outline_rounded,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe seu nome de usuário.';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 22),

                                const Text(
                                  'Senha',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 9),

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_mostrarSenha,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!_carregando) {
                                      _submitForm();
                                    }
                                  },
                                  decoration: _decoracaoCampo(
                                    label: 'Digite sua senha',
                                    icone: Icons.lock_outline_rounded,
                                    sufixo: IconButton(
                                      tooltip: _mostrarSenha
                                          ? 'Ocultar senha'
                                          : 'Mostrar senha',
                                      onPressed: () {
                                        setState(() {
                                          _mostrarSenha = !_mostrarSenha;
                                        });
                                      },
                                      icon: Icon(
                                        _mostrarSenha
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe sua senha.';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _carregando ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.mainColor,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: AppColors
                                          .mainColor
                                          .withValues(alpha: 0.6),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _carregando
                                        ? const SizedBox(
                                            width: 23,
                                            height: 23,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Entrar',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Acesso seguro ao sistema de ativos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
