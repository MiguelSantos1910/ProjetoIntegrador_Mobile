import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/models/ordem_manutencao.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/data/repositories/ordens_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/routes/routes.dart';

/// Abertura de chamado (ordem de manutenção) para um ativo.
///
/// Professor e suporte abrem o chamado; o aluno vê um aviso (o back
/// responderia 403). [ativoIdInicial] já deixa um ativo selecionado
/// (ex.: vindo da folha de detalhes da tela de Ativos).
class OrdemServicoPage extends StatefulWidget {
  final String? ativoIdInicial;

  const OrdemServicoPage({super.key, this.ativoIdInicial});

  @override
  State<OrdemServicoPage> createState() => _OrdemServicoPageState();
}

class _OrdemServicoPageState extends State<OrdemServicoPage> {
  final _formKey = GlobalKey<FormState>();

  final _descricaoController = TextEditingController();
  final _responsavelController = TextEditingController();
  final _custoController = TextEditingController();

  final AtivosService _ativosService = AtivosService();
  final OrdensService _ordensService = OrdensService();

  List<Ativo> _ativos = [];
  Ativo? _ativoSelecionado;

  bool _carregandoAtivos = true;
  String? _erroAtivos;
  bool _enviando = false;

  /// Também muda o status do ativo para "Em manutenção" (gera a
  /// movimentação MANUTENCAO no histórico).
  bool _marcarEmManutencao = true;

  Map<String, String> _errosApi = {};
  String? _erroAtivo;

  @override
  void initState() {
    super.initState();

    final sessao = context.read<SessaoProvider>();
    _responsavelController.text = sessao.nomeExibicao;

    if (sessao.podeAlterar) {
      _carregarAtivos();
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _responsavelController.dispose();
    _custoController.dispose();
    _ativosService.dispose();
    _ordensService.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Dados
  // ------------------------------------------------------------------

  Future<void> _carregarAtivos() async {
    setState(() {
      _carregandoAtivos = true;
      _erroAtivos = null;
    });

    try {
      final ativos = await context.read<SessaoProvider>().comToken(
        (token) => _ativosService.buscarAtivos(accessToken: token),
      );

      if (!mounted) return;

      // Ativo inativo não recebe chamado.
      final disponiveis = ativos
          .where(
            (ativo) =>
                StatusAtivo.normalizar(ativo.status) != StatusAtivo.inativo,
          )
          .toList()
        ..sort(
          (a, b) => a.descricao.toLowerCase().compareTo(
            b.descricao.toLowerCase(),
          ),
        );

      Ativo? inicial;
      for (final ativo in disponiveis) {
        if (ativo.id == widget.ativoIdInicial) inicial = ativo;
      }

      setState(() {
        _ativos = disponiveis;
        _ativoSelecionado = inicial ?? _ativoSelecionado;
        _carregandoAtivos = false;
      });
    } catch (_) {
      if (!mounted) return;

      if (!_sessaoAtiva()) return;

      setState(() {
        _erroAtivos = 'Não foi possível carregar os ativos.';
        _carregandoAtivos = false;
      });
    }
  }

  /// Se a sessão venceu, volta ao login e devolve false.
  bool _sessaoAtiva() {
    if (context.read<SessaoProvider>().logado) return true;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
    return false;
  }

  /// "1.234,50" ou "1234.5" -> "1234.50" (formato do DecimalField).
  String? _custoParaApi() {
    final texto = _custoController.text.trim();
    if (texto.isEmpty) return null;

    final normalizado = texto.contains(',')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto;

    final valor = double.tryParse(normalizado);
    return valor?.toStringAsFixed(2);
  }

  Future<void> _abrirChamado() async {
    if (_enviando) return;

    setState(() {
      _errosApi = {};
      _erroAtivo = _ativoSelecionado == null
          ? 'Selecione o ativo com problema.'
          : null;
    });

    final formularioValido = _formKey.currentState!.validate();
    if (!formularioValido || _erroAtivo != null) return;

    final ativo = _ativoSelecionado!;
    final sessao = context.read<SessaoProvider>();

    setState(() => _enviando = true);

    try {
      final ordem = await sessao.comToken(
        (token) => _ordensService.criarOrdem(
          accessToken: token,
          ativoId: ativo.id,
          descricao: _descricaoController.text.trim(),
          responsavel: _responsavelController.text.trim(),
          custoEstimado: _custoParaApi(),
        ),
      );

      // Movimentação do ativo: só se ainda não estiver em manutenção.
      String? avisoStatus;
      final jaEmManutencao =
          StatusAtivo.normalizar(ativo.status) == StatusAtivo.emManutencao;

      if (_marcarEmManutencao && !jaEmManutencao) {
        try {
          await sessao.comToken(
            (token) => _ativosService.atualizarStatus(
              accessToken: token,
              id: ativo.id,
              status: StatusAtivo.emManutencao,
            ),
          );
        } catch (_) {
          avisoStatus =
              'O chamado foi aberto, mas não foi possível mudar o '
              'status do ativo.';
        }
      }

      if (!mounted) return;

      await _mostrarSucesso(ordem, ativo, avisoStatus);
    } on ApiException catch (e) {
      if (!mounted || !_sessaoAtiva()) return;

      setState(() {
        _errosApi = e.errosPorCampo;
        _erroAtivo = e.errosPorCampo['ativo'];
      });
      _formKey.currentState!.validate();

      if (e.errosPorCampo.isEmpty) _mostrarErro(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _mostrarErro('Não foi possível abrir o chamado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _limparFormulario() {
    _descricaoController.clear();
    _custoController.clear();
    _responsavelController.text =
        context.read<SessaoProvider>().nomeExibicao;

    setState(() {
      _ativoSelecionado = null;
      _errosApi = {};
      _erroAtivo = null;
    });

    // Os ativos podem ter mudado de status (Em manutenção).
    _carregarAtivos();
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

  Future<void> _mostrarSucesso(
    OrdemManutencao ordem,
    Ativo ativo,
    String? avisoStatus,
  ) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chamado #${ordem.id} aberto',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ativo.descricao} · status ${ordem.status}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (avisoStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    avisoStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                BotaoApp(
                  texto: 'Ver chamado',
                  icone: Icons.visibility_outlined,
                  onPressed: () => Navigator.of(context).pop('ver'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop('outro'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.mainColor,
                    side: const BorderSide(color: AppColors.mainColor),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Abrir outro chamado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop('ativos'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mainColor,
                  ),
                  child: const Text(
                    'Ver ativos',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (acao == 'ver') {
      // Abre o detalhe e deixa o formulário limpo para quando voltar.
      _limparFormulario();
      Navigator.of(context).pushNamed(
        AppRoutes.detalheChamado,
        arguments: ordem.id,
      );
    } else if (acao == 'ativos') {
      // Veio da tela de Ativos: volta para ela; senão, abre a lista.
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      } else {
        navigator.pushReplacementNamed(AppRoutes.ativos);
      }
    } else {
      _limparFormulario();
    }
  }

  // ------------------------------------------------------------------
  // Seleção do ativo
  // ------------------------------------------------------------------

  Future<void> _escolherAtivo() async {
    final escolhido = await showModalBottomSheet<Ativo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SeletorAtivo(ativos: _ativos),
    );

    if (escolhido != null) {
      setState(() {
        _ativoSelecionado = escolhido;
        _erroAtivo = null;
      });
    }
  }

  Widget _buildCampoAtivo() {
    final ativo = _ativoSelecionado;

    Widget? sufixo;
    if (_carregandoAtivos) {
      sufixo = const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      sufixo = const Icon(
        Icons.expand_more_rounded,
        color: AppColors.textSecondary,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ativo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 9),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _carregandoAtivos || _erroAtivos != null
              ? null
              : _escolherAtivo,
          child: InputDecorator(
            isEmpty: ativo == null,
            decoration: FormData.decoracaoPadrao(
              hintText: _erroAtivos ?? 'Selecione o ativo com problema',
              prefixIcon: ativo == null
                  ? Icons.inventory_2_outlined
                  : StatusAtivo.iconeTipo(ativo.tipo),
              suffixIcon: sufixo,
              errorText: _erroAtivo,
            ),
            child: ativo == null
                ? null
                : Text(
                    [
                      ativo.descricao,
                      if ((ativo.numeroPatrimonio ?? '').isNotEmpty)
                        'Pat. ${ativo.numeroPatrimonio}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
        if (_erroAtivos != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _carregarAtivos,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mainColor,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar carregar de novo'),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

  Widget _buildCartao({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCards,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _buildSemPermissao() {
    final papel = context.watch<SessaoProvider>().usuario?.papel ?? '';

    return _buildCartao(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.mainColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Abertura de chamado restrita',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seu perfil${papel.isEmpty ? '' : ' ($papel)'} pode consultar '
            'os ativos. Para relatar um problema, procure o professor ou o '
            'suporte técnico, que abrem o chamado.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          BotaoApp(
            texto: 'Ver ativos',
            icone: Icons.list_alt_outlined,
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.ativos),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return _buildCartao(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCampoAtivo(),

            const SizedBox(height: 22),

            FormData(
              label: 'Descrição do problema',
              hintText: 'Ex.: não liga, tela piscando...',
              prefixIcon: Icons.report_problem_outlined,
              controller: _descricaoController,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              maxLines: 4,
              onChanged: (_) => _errosApi.remove('descricao'),
              validator: (value) {
                if (value == null || value.trim().length < 5) {
                  return 'Descreva o problema (mínimo de 5 caracteres).';
                }
                return _errosApi['descricao'];
              },
            ),

            const SizedBox(height: 22),

            FormData(
              label: 'Responsável',
              hintText: 'Quem vai atender o chamado',
              prefixIcon: Icons.engineering_outlined,
              controller: _responsavelController,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.name,
              maxLength: 100,
              onChanged: (_) => _errosApi.remove('responsavel'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o responsável.';
                }
                return _errosApi['responsavel'];
              },
            ),

            const SizedBox(height: 12),

            FormData(
              label: 'Custo estimado (opcional)',
              hintText: 'Ex.: 150,00',
              prefixIcon: Icons.payments_outlined,
              controller: _custoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) => _errosApi.remove('custo_estimado'),
              validator: (value) {
                if ((value ?? '').trim().isNotEmpty &&
                    _custoParaApi() == null) {
                  return 'Informe um valor válido (ex.: 150,00).';
                }
                return _errosApi['custo_estimado'];
              },
            ),

            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                color: AppColors.lightBackgroundColor,
                border: Border.all(color: AppColors.borderColor),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                value: _marcarEmManutencao,
                onChanged: (valor) =>
                    setState(() => _marcarEmManutencao = valor),
                activeThumbColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: const Text(
                  'Marcar o ativo como "Em manutenção"',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Registra a movimentação no histórico do ativo.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            BotaoApp(
              texto: 'Abrir chamado',
              icone: Icons.send_rounded,
              carregando: _enviando,
              onPressed: _abrirChamado,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final podeAbrir = context.watch<SessaoProvider>().podeAlterar;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chamado',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text(
            'Abrir chamado',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Registre um problema em um ativo. O chamado é criado como '
            'ordem de manutenção pendente.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 18),
          if (podeAbrir) _buildFormulario() else _buildSemPermissao(),
        ],
      ),
    );
  }
}

// ================================================================
// SELETOR DE ATIVO (folha inferior com busca)
// ================================================================

class _SeletorAtivo extends StatefulWidget {
  final List<Ativo> ativos;

  const _SeletorAtivo({required this.ativos});

  @override
  State<_SeletorAtivo> createState() => _SeletorAtivoState();
}

class _SeletorAtivoState extends State<_SeletorAtivo> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final termo = _busca.trim().toLowerCase();

    final ativos = widget.ativos.where((ativo) {
      return termo.isEmpty ||
          ativo.descricao.toLowerCase().contains(termo) ||
          (ativo.numeroPatrimonio ?? '').toLowerCase().contains(termo) ||
          ativo.sala.toLowerCase().contains(termo);
    }).toList();

    return SafeArea(
      child: Padding(
        // Sobe junto com o teclado.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Selecione o ativo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  autofocus: true,
                  onChanged: (valor) => setState(() => _busca = valor),
                  decoration: FormData.decoracaoPadrao(
                    hintText: 'Buscar por nome, patrimônio ou sala',
                    prefixIcon: Icons.search,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ativos.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum ativo encontrado.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: ativos.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 20,
                          endIndent: 20,
                          color: AppColors.borderColor,
                        ),
                        itemBuilder: (context, index) {
                          final ativo = ativos[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            onTap: () => Navigator.of(context).pop(ativo),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.mainColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                StatusAtivo.iconeTipo(ativo.tipo),
                                color: AppColors.mainColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              ativo.descricao,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              [
                                StatusAtivo.rotuloTipo(ativo.tipo),
                                if ((ativo.numeroPatrimonio ?? '').isNotEmpty)
                                  'Pat. ${ativo.numeroPatrimonio}',
                                if (ativo.sala.isNotEmpty) ativo.sala,
                              ].join(' · '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: StatusBadge(status: ativo.status),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
