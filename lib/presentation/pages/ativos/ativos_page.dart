import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/core/utils/formatar_data.dart';
import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';
import 'package:mobile_integrador/presentation/widgets/shared/linhaDetalhe/linha_detalhe.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';

class AtivosPage extends StatefulWidget {
  // O token vem do SessaoProvider, não mais dos argumentos da rota.
  const AtivosPage({super.key});

  @override
  State<AtivosPage> createState() => _AtivosPageState();
}

class _AtivosPageState extends State<AtivosPage> {
  /// Filtro padrão: tudo menos os inativos (como no painel web).
  static const String _filtroEmUso = 'EM_USO';
  static const String _filtroTodos = 'TODOS';

  final AtivosService _ativosService = AtivosService();
  final TextEditingController _buscaController = TextEditingController();

  bool _carregando = true;
  String? _erro;

  String _filtroStatus = _filtroEmUso;
  String _busca = '';

  List<Ativo> _ativos = [];

  @override
  void initState() {
    super.initState();
    _carregarAtivos();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    _ativosService.dispose();
    super.dispose();
  }

  Future<void> _carregarAtivos() async {
    setState(() {
      _carregando = _ativos.isEmpty;
      _erro = null;
    });

    try {
      final resultado = await context.read<SessaoProvider>().comToken(
        (token) => _ativosService.buscarAtivos(accessToken: token),
      );

      if (!mounted) return;

      resultado.sort(
        (a, b) => a.descricao.toLowerCase().compareTo(
          b.descricao.toLowerCase(),
        ),
      );

      setState(() {
        _ativos = resultado;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      // Token vencido e sem renovação: a sessão foi encerrada.
      if (!context.read<SessaoProvider>().logado) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (_) => false,
        );
        return;
      }

      setState(() {
        _erro = 'Verifique a conexão com o servidor e tente novamente.';
        _carregando = false;
      });
    }
  }

  // ------------------------------------------------------------------
  // Filtros
  // ------------------------------------------------------------------

  bool _correspondeStatus(Ativo ativo, String filtro) {
    final status = StatusAtivo.normalizar(ativo.status);

    switch (filtro) {
      case _filtroTodos:
        return true;
      case _filtroEmUso:
        return status != StatusAtivo.inativo;
      default:
        return status == filtro;
    }
  }

  List<Ativo> get _ativosFiltrados {
    final termo = _busca.trim().toLowerCase();

    return _ativos.where((ativo) {
      final correspondeBusca =
          termo.isEmpty ||
          ativo.descricao.toLowerCase().contains(termo) ||
          (ativo.numeroPatrimonio ?? '').toLowerCase().contains(termo) ||
          StatusAtivo.rotuloTipo(ativo.tipo).toLowerCase().contains(termo) ||
          ativo.sala.toLowerCase().contains(termo) ||
          ativo.codigoQr.toLowerCase().contains(termo);

      return correspondeBusca && _correspondeStatus(ativo, _filtroStatus);
    }).toList();
  }

  int _contar(String filtro) {
    return _ativos.where((ativo) => _correspondeStatus(ativo, filtro)).length;
  }

  void _limparFiltros() {
    _buscaController.clear();

    setState(() {
      _busca = '';
      _filtroStatus = _filtroEmUso;
    });
  }

  // ------------------------------------------------------------------
  // Detalhe do ativo (folha inferior)
  // ------------------------------------------------------------------

  void _abrirDetalhe(Ativo ativo) {
    final podeAbrirChamado =
        context.read<SessaoProvider>().podeAlterar &&
        StatusAtivo.normalizar(ativo.status) != StatusAtivo.inativo;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconeTipo(tipo: ativo.tipo, tamanho: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ativo.descricao.isEmpty
                                ? 'Sem descrição'
                                : ativo.descricao,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusBadge(status: ativo.status),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LinhaDetalhe(
                  icone: Icons.category_outlined,
                  rotulo: 'Tipo',
                  valor: StatusAtivo.rotuloTipo(ativo.tipo),
                ),
                LinhaDetalhe(
                  icone: Icons.confirmation_number_outlined,
                  rotulo: 'Patrimônio',
                  valor: (ativo.numeroPatrimonio ?? '').isEmpty
                      ? 'Não informado'
                      : ativo.numeroPatrimonio!,
                ),
                LinhaDetalhe(
                  icone: Icons.place_outlined,
                  rotulo: 'Local (sala)',
                  valor: ativo.sala.isEmpty ? 'Não informado' : ativo.sala,
                ),
                LinhaDetalhe(
                  icone: Icons.qr_code_2_rounded,
                  rotulo: 'Código QR',
                  valor: ativo.codigoQr.isEmpty ? '—' : ativo.codigoQr,
                  selecionavel: true,
                ),
                LinhaDetalhe(
                  icone: Icons.event_outlined,
                  rotulo: 'Cadastrado em',
                  valor: dataHoraFormatada(ativo.dataCadastro),
                ),
                LinhaDetalhe(
                  icone: Icons.update_outlined,
                  rotulo: 'Atualizado em',
                  valor: dataHoraFormatada(ativo.atualizadoEm),
                  ultima: true,
                ),
                // Abrir chamado: só professor e suporte, e não para inativos.
                if (podeAbrirChamado) ...[
                  const SizedBox(height: 20),
                  BotaoApp(
                    texto: 'Abrir chamado',
                    icone: Icons.report_problem_outlined,
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).pushNamed(
                        AppRoutes.ordemServico,
                        arguments: ativo.id,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

  InputDecoration _decoracaoBusca() {
    // Mesmo visual dos campos do login (FormData).
    return InputDecoration(
      hintText: 'Buscar por nome, patrimônio, sala ou código',
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: const Icon(Icons.search, color: AppColors.mainColor),
      suffixIcon: _busca.isNotEmpty
          ? IconButton(
              tooltip: 'Limpar busca',
              onPressed: () {
                _buscaController.clear();
                setState(() => _busca = '');
              },
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
            )
          : null,
      filled: true,
      fillColor: AppColors.lightBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }

  Widget _buildFiltros() {
    final filtros = <(String, String, Color)>[
      (_filtroEmUso, 'Em uso', AppColors.mainColor),
      for (final status in StatusAtivo.todos)
        (status, StatusAtivo.rotulo(status), StatusAtivo.cor(status)),
      (_filtroTodos, 'Todos', AppColors.textSecondary),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filtros.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (valor, rotulo, cor) = filtros[index];
          final selecionado = _filtroStatus == valor;

          return ChoiceChip(
            label: Text('$rotulo (${_contar(valor)})'),
            selected: selecionado,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filtroStatus = valor),
            labelStyle: TextStyle(
              color: selecionado ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedColor: cor,
            backgroundColor: AppColors.backgroundCards,
            side: BorderSide(
              color: selecionado ? cor : AppColors.borderColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEstado({
    required IconData icone,
    required String titulo,
    required String descricao,
    Widget? acao,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icone, size: 32, color: AppColors.mainColor),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (acao != null) ...[const SizedBox(height: 16), acao],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ativos = _ativosFiltrados;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ativos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregarAtivos,
            tooltip: 'Atualizar ativos',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.mainColor,
              onRefresh: _carregarAtivos,
              child: ListView(
                // Permite puxar para atualizar mesmo com a lista curta.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const Text(
                    'Gestão de patrimônio',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Consulte os ativos do laboratório. Toque em um ativo '
                    'para ver os detalhes.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_erro != null)
                    _buildEstado(
                      icone: Icons.cloud_off_outlined,
                      titulo: 'Não foi possível carregar os ativos',
                      descricao: _erro!,
                      acao: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                        ),
                        onPressed: _carregarAtivos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _buscaController,
                      textInputAction: TextInputAction.search,
                      onChanged: (valor) => setState(() => _busca = valor),
                      decoration: _decoracaoBusca(),
                    ),

                    const SizedBox(height: 12),

                    _buildFiltros(),

                    const SizedBox(height: 16),

                    Text(
                      ativos.length == 1
                          ? '1 ativo encontrado'
                          : '${ativos.length} ativos encontrados',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (_ativos.isEmpty)
                      _buildEstado(
                        icone: Icons.inventory_2_outlined,
                        titulo: 'Nenhum ativo cadastrado',
                        descricao:
                            'Os ativos cadastrados no painel web aparecem aqui.',
                      )
                    else if (ativos.isEmpty)
                      _buildEstado(
                        icone: Icons.search_off_rounded,
                        titulo: 'Nenhum ativo encontrado',
                        descricao:
                            'Nenhum ativo corresponde à busca ou ao filtro.',
                        acao: TextButton(
                          onPressed: _limparFiltros,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.mainColor,
                          ),
                          child: const Text(
                            'Limpar busca e filtros',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    else
                      for (final ativo in ativos) ...[
                        _CardAtivo(
                          ativo: ativo,
                          onTap: () => _abrirDetalhe(ativo),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ],
              ),
            ),
    );
  }
}

// ================================================================
// CARD DE UM ATIVO NA LISTA
// ================================================================

class _CardAtivo extends StatelessWidget {
  final Ativo ativo;
  final VoidCallback onTap;

  const _CardAtivo({required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final patrimonio = (ativo.numeroPatrimonio ?? '').isEmpty
        ? 'Sem patrimônio'
        : 'Pat. ${ativo.numeroPatrimonio}';

    return Material(
      color: AppColors.backgroundCards,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _IconeTipo(tipo: ativo.tipo, tamanho: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ativo.descricao.isEmpty
                          ? 'Sem descrição'
                          : ativo.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${StatusAtivo.rotuloTipo(ativo.tipo)} · $patrimonio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: ativo.status),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.place_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            ativo.sala.isEmpty ? '—' : ativo.sala,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ÍCONE DO TIPO (padrão do app: quadrado verde-claro)
// ================================================================

class _IconeTipo extends StatelessWidget {
  final String tipo;
  final double tamanho;

  const _IconeTipo({required this.tipo, required this.tamanho});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: AppColors.mainColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        StatusAtivo.iconeTipo(tipo),
        color: AppColors.mainColor,
        size: tamanho * 0.5,
      ),
    );
  }
}
