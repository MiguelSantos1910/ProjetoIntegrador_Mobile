import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/data/repositories/usuario_service.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';

/// Cadastro público de usuário (POST /api/contas/usuarios/).
///
/// O back cria toda conta como ALUNO; o professor muda o papel no painel
/// web. Ao concluir, volta ao login devolvendo o usuário criado.
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final UsuariosService _usuariosService = UsuariosService();

  bool _carregando = false;

  /// Erros devolvidos pela API, por campo da tela
  /// (nome, username, email e password).
  Map<String, String> _errosApi = {};

  static final _padraoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  // Mesmos caracteres aceitos pelo Django: letras, números e @ . + - _
  static final _padraoUsuario = RegExp(r'^[\w.@+-]+$');

  @override
  void dispose() {
    _nomeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _usuariosService.dispose();
    super.dispose();
  }

  /// Apaga o erro da API de um campo assim que o usuário edita esse campo.
  void _limparErroApi(String campo) {
    if (_errosApi.containsKey(campo)) {
      setState(() {
        _errosApi = Map.of(_errosApi)..remove(campo);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_carregando) return;

    setState(() {
      _errosApi = {};
    });

    if (!_formKey.currentState!.validate()) return;

    final partesNome = _nomeController.text.trim().split(RegExp(r'\s+'));
    final firstName = partesNome.first;
    final lastName = partesNome.skip(1).join(' ');
    final username = _usernameController.text.trim();

    setState(() {
      _carregando = true;
    });

    try {
      await _usuariosService.criarUsuario(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        password: _senhaController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada. Entre com seu usuário e senha.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(username);
    } on ApiException catch (e) {
      if (!mounted) return;

      // Os nomes do back são first_name e last_name; na tela é "nome".
      final erros = <String, String>{};

      e.errosPorCampo.forEach((campo, mensagem) {
        final campoTela =
            campo == 'first_name' || campo == 'last_name' ? 'nome' : campo;
        erros.putIfAbsent(campoTela, () => mensagem);
      });

      setState(() {
        _errosApi = erros;
      });

      // Mostra os erros embaixo de cada campo.
      _formKey.currentState!.validate();

      if (erros.isEmpty) {
        _mostrarErro(e.mensagem);
      }
    } catch (_) {
      if (!mounted) return;

      _mostrarErro('Não foi possível criar a conta. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
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
                        // Identidade visual (igual à do login).
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

                        // Cartão de cadastro (mesmo estilo do login).
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
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Criar conta',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  const Text(
                                    'Preencha seus dados para acessar o sistema.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  FormData(
                                    label: 'Nome completo',
                                    hintText: 'Digite seu nome',
                                    prefixIcon: Icons.badge_outlined,
                                    controller: _nomeController,
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    onChanged: (_) => _limparErroApi('nome'),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Informe seu nome.';
                                      }

                                      return _errosApi['nome'];
                                    },
                                  ),

                                  const SizedBox(height: 22),

                                  FormData(
                                    label: 'Nome de usuário',
                                    hintText: 'Digite um usuário para o login',
                                    prefixIcon: Icons.person_outline_rounded,
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    autofillHints: const [
                                      AutofillHints.newUsername,
                                    ],
                                    onChanged: (_) =>
                                        _limparErroApi('username'),
                                    validator: (value) {
                                      final usuario = value?.trim() ?? '';

                                      if (usuario.isEmpty) {
                                        return 'Informe um nome de usuário.';
                                      }

                                      if (!_padraoUsuario.hasMatch(usuario)) {
                                        return 'Use apenas letras, números '
                                            'e @ . + - _ (sem espaços).';
                                      }

                                      return _errosApi['username'];
                                    },
                                  ),

                                  const SizedBox(height: 22),

                                  FormData(
                                    label: 'E-mail',
                                    hintText: 'Digite seu e-mail',
                                    prefixIcon: Icons.mail_outline_rounded,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autocorrect: false,
                                    autofillHints: const [AutofillHints.email],
                                    onChanged: (_) => _limparErroApi('email'),
                                    validator: (value) {
                                      final email = value?.trim() ?? '';

                                      if (email.isEmpty) {
                                        return 'Informe seu e-mail.';
                                      }

                                      if (!_padraoEmail.hasMatch(email)) {
                                        return 'Informe um e-mail válido.';
                                      }

                                      return _errosApi['email'];
                                    },
                                  ),

                                  const SizedBox(height: 22),

                                  FormData(
                                    label: 'Senha',
                                    hintText: 'Crie uma senha',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    controller: _senhaController,
                                    isPassword: true,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    onChanged: (_) =>
                                        _limparErroApi('password'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Crie uma senha.';
                                      }

                                      // As demais regras (senha comum, só
                                      // números, parecida com o usuário)
                                      // são verificadas pelo back.
                                      if (value.length < 8) {
                                        return 'A senha deve ter pelo menos '
                                            '8 caracteres.';
                                      }

                                      return _errosApi['password'];
                                    },
                                  ),

                                  const SizedBox(height: 22),

                                  FormData(
                                    label: 'Confirmar senha',
                                    hintText: 'Digite a senha novamente',
                                    prefixIcon: Icons.lock_outline_rounded,
                                    controller: _confirmarSenhaController,
                                    isPassword: true,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submitForm(),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Confirme a senha.';
                                      }

                                      if (value != _senhaController.text) {
                                        return 'As senhas não coincidem.';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 28),

                                  BotaoApp(
                                    texto: 'Criar conta',
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
                                          'Já tem conta?',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _carregando
                                              ? null
                                              : () => Navigator.of(
                                                  context,
                                                ).pop(),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppColors.mainColor,
                                          ),
                                          child: const Text(
                                            'Entrar',
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
                                'Novas contas começam com acesso de aluno',
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
