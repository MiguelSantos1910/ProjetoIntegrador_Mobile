import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/core/api/api_config.dart';
import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/data/repositories/usuario_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
import 'package:mobile_integrador/presentation/widgets/shared/linhaDetalhe/linha_detalhe.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/routes/routes.dart';

/// Configurações da conta e do app.
///
/// - Perfil: nome e e-mail (edição só para professor, como no back).
/// - Segurança: troca da própria senha (todos os papéis).
/// - Conexão: servidor em uso e teste de disponibilidade.
/// - Sobre o app e saída da conta.
class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  static const String _versaoApp = '1.0.0';

  final UsuariosService _usuariosService = UsuariosService();

  // Perfil
  final _formPerfil = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  bool _salvandoPerfil = false;
  Map<String, String> _errosPerfil = {};

  // Senha
  final _formSenha = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _alterandoSenha = false;
  String? _erroSenhaApi;

  // Conexão
  bool _testando = false;
  Duration? _tempoResposta;
  String? _erroConexao;

  static final _padraoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _preencherPerfil();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    _usuariosService.dispose();
    super.dispose();
  }

  void _preencherPerfil() {
    final usuario = context.read<SessaoProvider>().usuario;
    _nomeController.text = usuario?.nomeCompleto ?? '';
    _emailController.text = usuario?.email ?? '';
  }

  // ------------------------------------------------------------------
  // Ações
  // ------------------------------------------------------------------

  void _mostrar(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvarPerfil() async {
    if (_salvandoPerfil) return;

    setState(() => _errosPerfil = {});
    if (!_formPerfil.currentState!.validate()) return;

    final sessao = context.read<SessaoProvider>();
    final usuario = sessao.usuario;
    if (usuario == null) return;

    final partes = _nomeController.text.trim().split(RegExp(r'\s+'));

    setState(() => _salvandoPerfil = true);

    try {
      await sessao.comToken(
        (token) => _usuariosService.atualizarPerfil(
          accessToken: token,
          id: usuario.id,
          firstName: partes.first,
          lastName: partes.skip(1).join(' '),
          email: _emailController.text.trim(),
        ),
      );

      // Atualiza o nome em todo o app (saudação da Home, etc.).
      await sessao.recarregarUsuario();

      if (!mounted) return;
      _preencherPerfil();
      _mostrar('Perfil atualizado.');
    } on ApiException catch (e) {
      if (!mounted) return;

      final erros = <String, String>{};
      e.errosPorCampo.forEach((campo, mensagem) {
        final campoTela =
            campo == 'first_name' || campo == 'last_name' ? 'nome' : campo;
        erros.putIfAbsent(campoTela, () => mensagem);
      });

      setState(() => _errosPerfil = erros);
      _formPerfil.currentState!.validate();

      if (erros.isEmpty) _mostrar(e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _salvandoPerfil = false);
    }
  }

  Future<void> _alterarSenha() async {
    if (_alterandoSenha) return;

    setState(() => _erroSenhaApi = null);
    if (!_formSenha.currentState!.validate()) return;

    final sessao = context.read<SessaoProvider>();
    final usuario = sessao.usuario;
    if (usuario == null) return;

    setState(() => _alterandoSenha = true);

    try {
      await sessao.comToken(
        (token) => _usuariosService.alterarSenha(
          accessToken: token,
          id: usuario.id,
          novaSenha: _senhaController.text,
        ),
      );

      if (!mounted) return;

      _senhaController.clear();
      _confirmarController.clear();
      FocusScope.of(context).unfocus();
      _mostrar('Senha alterada. Use a nova senha no próximo login.');
    } on ApiException catch (e) {
      if (!mounted) return;

      // Regras do Django (senha comum, só números...) vêm em "password".
      setState(() => _erroSenhaApi = e.errosPorCampo['password']);
      _formSenha.currentState!.validate();

      if (_erroSenhaApi == null) _mostrar(e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _alterandoSenha = false);
    }
  }

  Future<void> _testarConexao() async {
    setState(() {
      _testando = true;
      _tempoResposta = null;
      _erroConexao = null;
    });

    try {
      final tempo = await _usuariosService.verificarServidor();
      if (!mounted) return;
      setState(() => _tempoResposta = tempo);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erroConexao = e.mensagem);
    } finally {
      if (mounted) setState(() => _testando = false);
    }
  }

  Future<void> _sair() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Sua sessão será encerrada neste aparelho e no servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    await context.read<SessaoProvider>().logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

  Widget _cartao({
    required String titulo,
    required IconData icone,
    String? descricao,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCards,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: AppColors.mainColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (descricao != null)
                      Text(
                        descricao,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCabecalho(SessaoProvider sessao) {
    final usuario = sessao.usuario;
    final nome = sessao.nomeExibicao;
    final iniciais = nome
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte[0].toUpperCase())
        .join();

    const papeis = {
      'PROFESSOR': 'Professor',
      'SUPORTE': 'Suporte técnico',
      'ALUNO': 'Aluno',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCards,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.mainColor,
            child: Text(
              iniciais.isEmpty ? '?' : iniciais,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${usuario?.username ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Etiqueta(
                  texto: papeis[sessao.papel] ?? 'Usuário',
                  cor: AppColors.mainColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfil(SessaoProvider sessao) {
    if (!sessao.podeEditarPerfil) {
      final usuario = sessao.usuario;

      return _cartao(
        titulo: 'Dados do perfil',
        icone: Icons.badge_outlined,
        descricao: 'Somente o professor altera nome e e-mail.',
        child: Column(
          children: [
            LinhaDetalhe(
              icone: Icons.person_outline_rounded,
              rotulo: 'Nome',
              valor: (usuario?.nomeCompleto ?? '').isEmpty
                  ? 'Não informado'
                  : usuario!.nomeCompleto,
            ),
            LinhaDetalhe(
              icone: Icons.mail_outline_rounded,
              rotulo: 'E-mail',
              valor: (usuario?.email ?? '').isEmpty
                  ? 'Não informado'
                  : usuario!.email,
              ultima: true,
            ),
          ],
        ),
      );
    }

    return _cartao(
      titulo: 'Dados do perfil',
      icone: Icons.badge_outlined,
      descricao: 'Nome e e-mail exibidos no sistema.',
      child: Form(
        key: _formPerfil,
        child: Column(
          children: [
            FormData(
              label: 'Nome completo',
              hintText: 'Digite seu nome',
              prefixIcon: Icons.person_outline_rounded,
              controller: _nomeController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _errosPerfil.remove('nome'),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe seu nome.';
                }
                return _errosPerfil['nome'];
              },
            ),
            const SizedBox(height: 18),
            FormData(
              label: 'E-mail',
              hintText: 'Digite seu e-mail',
              prefixIcon: Icons.mail_outline_rounded,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onChanged: (_) => _errosPerfil.remove('email'),
              validator: (valor) {
                final email = valor?.trim() ?? '';
                if (email.isEmpty) return 'Informe seu e-mail.';
                if (!_padraoEmail.hasMatch(email)) {
                  return 'Informe um e-mail válido.';
                }
                return _errosPerfil['email'];
              },
            ),
            const SizedBox(height: 20),
            BotaoApp(
              texto: 'Salvar perfil',
              icone: Icons.check_rounded,
              carregando: _salvandoPerfil,
              onPressed: _salvarPerfil,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSenha() {
    return _cartao(
      titulo: 'Alterar senha',
      icone: Icons.lock_outline_rounded,
      descricao: 'Mínimo de 8 caracteres; evite senhas comuns.',
      child: Form(
        key: _formSenha,
        child: AutofillGroup(
          child: Column(
            children: [
              FormData(
                label: 'Nova senha',
                hintText: 'Digite a nova senha',
                prefixIcon: Icons.lock_outline_rounded,
                controller: _senhaController,
                isPassword: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) => _erroSenhaApi = null,
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Digite a nova senha.';
                  }
                  if (valor.length < 8) {
                    return 'A senha deve ter pelo menos 8 caracteres.';
                  }
                  return _erroSenhaApi;
                },
              ),
              const SizedBox(height: 18),
              FormData(
                label: 'Confirmar nova senha',
                hintText: 'Digite a senha novamente',
                prefixIcon: Icons.lock_outline_rounded,
                controller: _confirmarController,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _alterarSenha(),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Confirme a nova senha.';
                  }
                  if (valor != _senhaController.text) {
                    return 'As senhas não coincidem.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              BotaoApp(
                texto: 'Alterar senha',
                icone: Icons.key_rounded,
                carregando: _alterandoSenha,
                onPressed: _alterarSenha,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConexao() {
    Widget resultado;

    if (_testando) {
      resultado = const Etiqueta(
        texto: 'Testando...',
        cor: AppColors.textSecondary,
      );
    } else if (_tempoResposta != null) {
      resultado = Etiqueta(
        texto: 'Online · ${_tempoResposta!.inMilliseconds} ms',
        cor: AppColors.success,
      );
    } else if (_erroConexao != null) {
      resultado = const Etiqueta(texto: 'Sem resposta', cor: AppColors.error);
    } else {
      resultado = const Etiqueta(
        texto: 'Não testado',
        cor: AppColors.textSecondary,
      );
    }

    return _cartao(
      titulo: 'Conexão',
      icone: Icons.cloud_outlined,
      descricao: 'Servidor da API usado pelo app.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinhaDetalhe(
            icone: Icons.dns_outlined,
            rotulo: 'Servidor',
            valor: ApiConfig.baseUrl,
            selecionavel: true,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_tethering_rounded,
                  size: 20,
                  color: AppColors.mainColor,
                ),
                const SizedBox(width: 12),
                const SizedBox(
                  width: 110,
                  child: Text(
                    'Situação',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                resultado,
              ],
            ),
          ),
          if (_erroConexao != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _erroConexao!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ),
          if (ApiConfig.baseUrl.startsWith('http://'))
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Conexão sem HTTPS: aceita apenas para a demonstração.',
                style: TextStyle(color: AppColors.warning, fontSize: 12),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testando ? null : _testarConexao,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mainColor,
                side: const BorderSide(color: AppColors.mainColor),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.network_check_rounded),
              label: const Text(
                'Testar conexão',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSobre() {
    return _cartao(
      titulo: 'Sobre o app',
      icone: Icons.info_outline_rounded,
      child: const Column(
        children: [
          LinhaDetalhe(
            icone: Icons.apps_rounded,
            rotulo: 'Aplicativo',
            valor: 'Easy Asset Mobile',
          ),
          LinhaDetalhe(
            icone: Icons.tag_rounded,
            rotulo: 'Versão',
            valor: _versaoApp,
          ),
          LinhaDetalhe(
            icone: Icons.school_outlined,
            rotulo: 'Projeto',
            valor: 'Projeto Integrador IV · ADS · SENAI Roberto Mange',
            ultima: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessao = context.watch<SessaoProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _buildCabecalho(sessao),
          const SizedBox(height: 12),
          _buildPerfil(sessao),
          const SizedBox(height: 12),
          _buildSenha(),
          const SizedBox(height: 12),
          _buildConexao(),
          const SizedBox(height: 12),
          _buildSobre(),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _sair,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Sair da conta',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
