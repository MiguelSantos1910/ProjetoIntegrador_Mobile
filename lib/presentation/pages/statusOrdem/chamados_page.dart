import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/models/ordem_manutencao.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/data/repositories/ordens_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/cardChamado/card_chamado.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/routes/routes.dart';

/// Lista de chamados (ordens de manutenção) para acompanhar o andamento.
/// Toque em um chamado para abrir o detalhe.
class ChamadosPage extends StatefulWidget {
  const ChamadosPage({super.key});

  @override
  State<ChamadosPage> createState() => _ChamadosPageState();
}

class _ChamadosPageState extends State<ChamadosPage> {
  /// Filtro padrão: só os que ainda precisam de atendimento.
  static const String _filtroAbertos = 'ABERTOS';
  static const String _filtroTodos = 'TODOS';

  final OrdensService _ordensService = OrdensService();
  final AtivosService _ativosService = AtivosService();
  final TextEditingController _buscaController = TextEditingController();

  List<OrdemManutencao> _ordens = [];
  Map<int, Ativo> _ativosPorId = {};

  bool _carregando = true;
  String? _erro;

  String _filtro = _filtroAbertos;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _ordensService.dispose();
    _ativosService.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _ordens.isEmpty;
      _erro = null;
    });

    final sessao = context.read<SessaoProvider>();

    try {
      final resultados = await Future.wait<Object>([
        sessao.comToken(
          (token) => _ordensService.listarOrdens(accessToken: token),
        ),
        // Só para mostrar o nome do ativo em cada chamado.
        sessao.comToken(
          (token) => _ativosService.buscarAtivos(accessToken: token),
        ),
      ]);

      if (!mounted) return;

      final ordens = resultados[0] as List<OrdemManutencao>;
      final ativos = resultados[1] as List<Ativo>;

      // Mais recentes primeiro.
      ordens.sort(
        (a, b) => (b.dataAbertura ?? DateTime(0)).compareTo(
          a.dataAbertura ?? DateTime(0),
        ),
      );

      setState(() {
        _ordens = ordens;
        _ativosPorId = {
          for (final ativo in ativos)
            if (int.tryParse(ativo.id) != null) int.parse(ativo.id): ativo,
        };
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      if (!sessao.logado) {
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

  bool _correspondeFiltro(OrdemManutencao ordem, String filtro) {
    switch (filtro) {
      case _filtroTodos:
        return true;
      case _filtroAbertos:
        return StatusOrdem.aberta(ordem.status);
      default:
        return ordem.status == filtro;
    }
  }

  List<OrdemManutencao> get _ordensFiltradas {
    final termo = _busca.trim().toLowerCase().replaceAll('#', '');

    return _ordens.where((ordem) {
      final ativo = _ativosPorId[ordem.ativoId];

      final correspondeBusca =
          termo.isEmpty ||
          ordem.id.toString() == termo ||
          ordem.descricao.toLowerCase().contains(termo) ||
          ordem.responsavel.toLowerCase().contains(termo) ||
          (ativo?.descricao.toLowerCase().contains(termo) ?? false) ||
          (ativo?.numeroPatrimonio?.toLowerCase().contains(termo) ?? false);

      return correspondeBusca && _correspondeFiltro(ordem, _filtro);
    }).toList();
  }

  int _contar(String filtro) =>
      _ordens.where((ordem) => _correspondeFiltro(ordem, filtro)).length;

  // ------------------------------------------------------------------
  // Navegação
  // ------------------------------------------------------------------

  Future<void> _abrirDetalhe(OrdemManutencao ordem) async {
    final alterado = await Navigator.of(context).pushNamed(
      AppRoutes.detalheChamado,
      arguments: ordem.id,
    );

    if (alterado == true && mounted) _carregar();
  }

  Future<void> _abrirNovoChamado() async {
    await Navigator.of(context).pushNamed(AppRoutes.ordemServico);
    if (mounted) _carregar();
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

  Widget _buildFiltros() {
    final filtros = <(String, String, Color)>[
      (_filtroAbertos, 'Abertos', AppColors.mainColor),
      for (final status in StatusOrdem.todos)
        (status, status, StatusOrdem.cor(status)),
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
          final selecionado = _filtro == valor;

          return ChoiceChip(
            label: Text('$rotulo (${_contar(valor)})'),
            selected: selecionado,
            showCheckmark: false,
            onSelected: (_) => setState(() => _filtro = valor),
            labelStyle: TextStyle(
              color: selecionado ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedColor: cor,
            backgroundColor: AppColors.backgroundCards,
            side: BorderSide(color: selecionado ? cor : AppColors.borderColor),
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
    final ordens = _ordensFiltradas;
    final podeAbrir = context.watch<SessaoProvider>().podeAlterar;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Chamados',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregar,
            tooltip: 'Atualizar chamados',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: podeAbrir
          ? FloatingActionButton.extended(
              onPressed: _abrirNovoChamado,
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Abrir chamado',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.mainColor,
              onRefresh: _carregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Espaço no fim para o botão flutuante não cobrir o último.
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  const Text(
                    'Acompanhar chamados',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Ordens de manutenção dos ativos. Toque em um chamado '
                    'para ver os detalhes e o histórico.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (_erro != null)
                    _buildEstado(
                      icone: Icons.cloud_off_outlined,
                      titulo: 'Não foi possível carregar os chamados',
                      descricao: _erro!,
                      acao: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                        ),
                        onPressed: _carregar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _buscaController,
                      textInputAction: TextInputAction.search,
                      onChanged: (valor) => setState(() => _busca = valor),
                      decoration: FormData.decoracaoPadrao(
                        hintText: 'Buscar por nº, ativo, descrição ou responsável',
                        prefixIcon: Icons.search,
                        suffixIcon: _busca.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _buscaController.clear();
                                  setState(() => _busca = '');
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFiltros(),
                    const SizedBox(height: 16),
                    Text(
                      ordens.length == 1
                          ? '1 chamado'
                          : '${ordens.length} chamados',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_ordens.isEmpty)
                      _buildEstado(
                        icone: Icons.assignment_outlined,
                        titulo: 'Nenhum chamado registrado',
                        descricao: podeAbrir
                            ? 'Use "Abrir chamado" para registrar um problema.'
                            : 'Os chamados abertos aparecem aqui.',
                      )
                    else if (ordens.isEmpty)
                      _buildEstado(
                        icone: Icons.search_off_rounded,
                        titulo: 'Nenhum chamado encontrado',
                        descricao:
                            'Nenhum chamado corresponde à busca ou ao filtro.',
                        acao: TextButton(
                          onPressed: () {
                            _buscaController.clear();
                            setState(() {
                              _busca = '';
                              _filtro = _filtroTodos;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.mainColor,
                          ),
                          child: const Text(
                            'Mostrar todos',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      )
                    else
                      for (final ordem in ordens) ...[
                        CardChamado(
                          ordem: ordem,
                          ativo: _ativosPorId[ordem.ativoId],
                          onTap: () => _abrirDetalhe(ordem),
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
