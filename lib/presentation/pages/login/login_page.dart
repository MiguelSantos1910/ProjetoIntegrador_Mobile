import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
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

  bool _carregando = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
      // Autentica na API e guarda tokens e usuário na sessão.
      await context.read<SessaoProvider>().login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;

      final mensagem = e is ApiException
          ? e.mensagem
          : 'Não foi possível entrar. Tente novamente.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
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

  // Abre o cadastro; ao voltar com sucesso, preenche o usuário criado.
  Future<void> _abrirCadastro() async {
    final usuarioCriado = await Navigator.of(context).pushNamed(
      AppRoutes.cadastro,
    );

    if (!mounted || usuarioCriado is! String) return;

    _usernameController.text = usuarioCriado;
    _passwordController.clear();
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
                        // Identidade visual: ícone do Easy Asset.
                        // O SVG já traz o selo verde arredondado; o
                        // Container só desenha a sombra por trás dele.
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
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
                          // O selo ocupa 160 dos 180 px do SVG; com 86 px,
                          // ele fica com os mesmos 76 px do Container.
                          child: OverflowBox(
                            maxWidth: 86,
                            maxHeight: 86,
                            child: SvgPicture.asset(
                              'lib/assets/easy-asset-icon-verde.svg',
                              width: 86,
                              height: 86,
                              semanticsLabel: 'Ícone do Easy Asset',
                            ),
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

                                FormData(
                                  label: 'Nome de usuário',
                                  hintText: 'Digite seu usuário',
                                  prefixIcon: Icons.person_outline_rounded,
                                  controller: _usernameController,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  autofillHints: const [AutofillHints.username],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe seu nome de usuário.';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 22),

                                FormData(
                                  label: 'Senha',
                                  hintText: 'Digite sua senha',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  controller: _passwordController,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) {
                                    if (!_carregando) {
                                      _submitForm();
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe sua senha.';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 28),

                                BotaoApp(
                                  texto: 'Entrar',
                                  icone: Icons.arrow_forward_rounded,
                                  carregando: _carregando,
                                  onPressed: _submitForm,
                                ),

                                const SizedBox(height: 16),

                                Center(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      const Text(
                                        'Ainda não tem conta?',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _carregando
                                            ? null
                                            : _abrirCadastro,
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.mainColor,
                                        ),
                                        child: const Text(
                                          'Criar conta',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
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
