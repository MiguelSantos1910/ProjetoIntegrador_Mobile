import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/models/ordem_manutencao.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/data/repositories/ordens_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/cardChamado/card_chamado.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/core/utils/formatar_data.dart';
import 'package:mobile_integrador/data/models/movimentacao.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/card/card.dart';

class HomePage extends StatefulWidget {
  // Token e usuário vêm do SessaoProvider, não mais dos argumentos da rota.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AtivosService _ativosService = AtivosService();

  bool _carregando = true;
  String? _erro;
  List<dynamic> _ativos = [];

  // Chamados em aberto (ordens Pendente e Em andamento), da API.
  static const int _limiteChamados = 5;
  final OrdensService _ordensService = OrdensService();
  List<OrdemManutencao> _chamadosAbertos = [];
  int _totalChamadosAbertos = 0;
  bool _carregandoChamados = true;
  String? _erroChamados;

  // Últimas movimentações dos ativos (GET /api/historico/).
  static const int _limiteMovimentacoes = 5;
  List<Movimentacao> _movimentacoes = [];
  bool _carregandoMovimentacoes = true;
  String? _erroMovimentacoes;

  static const List<_StatusInfo> _statusInfo = [
    _StatusInfo(chave: 'ATIVO', titulo: 'Ativos', cor: Color(0xFF16A34A)),
    _StatusInfo(
      chave: 'EM_MANUTENCAO',
      titulo: 'Em manutenção',
      cor: Color(0xFFF59E0B),
    ),
    _StatusInfo(
      chave: 'DEVOLVIDO',
      titulo: 'Devolvidos',
      cor: Color(0xFF64748B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _carregarAtivos();
    _carregarChamados();
    _carregarMovimentacoes();
  }

  @override
  void dispose() {
    _ativosService.dispose();
    _ordensService.dispose();
    super.dispose();
  }

  Future<void> _carregarAtivos() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final sessao = context.read<SessaoProvider>();

      final resultado = await sessao.comToken(
        (token) => _ativosService.buscarAtivos(accessToken: token),
      );

      // O AtivosService já retorna objetos do model Ativo.
      // Não acesse os registros como Map usando item['id'].
      if (!mounted) return;

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
        _erro =
            'Não foi possível carregar os ativos. Verifique a conexão e tente novamente.';
        _carregando = false;
      });
    }
  }

  String _obterStatus(dynamic ativo) {
    // A lista retornada pelo serviço contém instâncias do model Ativo.
    // Por isso, lemos a propriedade status em vez de usar ativo['status'].
    try {
      final status = ativo.status;
      return status
          .toString()
          .trim()
          .toUpperCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
    } catch (_) {
      // Se algum registro não tiver a propriedade esperada, não o contabiliza.
      return '';
    }
  }

  int _contarStatus(String status) {
    return _ativos.where((ativo) {
      return _obterStatus(ativo) == status;
    }).length;
  }

  int get _totalAtivos => _ativos.length;

  int get _ativosDisponiveis => _contarStatus('ATIVO');

  int get _ativosEmManutencao => _contarStatus('EM_MANUTENCAO');

  int get _ativosDevolvidos => _contarStatus('DEVOLVIDO');

  Map<String, int> get _quantidadesPorStatus {
    return {
      for (final status in _statusInfo)
        status.chave: _contarStatus(status.chave),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;
          final colunas = largura >= 900 ? 4 : 2;
          final paddingHorizontal = largura >= 900 ? 28.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              paddingHorizontal,
              24,
              paddingHorizontal,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSaudacao(),

                    const SizedBox(height: 28),

                    _buildTituloSecao('Resumo dos Ativos'),

                    const SizedBox(height: 14),

                    if (_carregando)
                      const _EstadoCarregamento()
                    else if (_erro != null)
                      _buildErro()
                    else
                      _buildGridResumo(colunas),

                    const SizedBox(height: 32),

                    _buildTituloSecao('Análise dos Ativos'),

                    const SizedBox(height: 14),

                    if (_carregando)
                      const _EstadoCarregamento()
                    else if (_erro != null)
                      const _MensagemGraficoIndisponivel()
                    else ...[
                      _buildGraficoDistribuicao(),
                      const SizedBox(height: 16),
                      _buildGraficoPorStatus(),
                    ],

                    const SizedBox(height: 32),

                    _buildTituloSecao('Movimentações Recentes'),

                    const SizedBox(height: 14),

                    _buildMovimentacoes(),

                    const SizedBox(height: 32),

                    _buildCabecalhoChamados(),

                    const SizedBox(height: 8),

                    _buildChamados(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _carregarChamados() async {
    if (!mounted) return;

    setState(() {
      _carregandoChamados = _chamadosAbertos.isEmpty;
      _erroChamados = null;
    });

    try {
      final ordens = await context.read<SessaoProvider>().comToken(
        (token) => _ordensService.listarOrdens(accessToken: token),
      );

      if (!mounted) return;

      final abertos = ordens
          .where((ordem) => StatusOrdem.aberta(ordem.status))
          .toList()
        ..sort(
          (a, b) => (b.dataAbertura ?? DateTime(0)).compareTo(
            a.dataAbertura ?? DateTime(0),
          ),
        );

      setState(() {
        _totalChamadosAbertos = abertos.length;
        _chamadosAbertos = abertos.take(_limiteChamados).toList();
        _carregandoChamados = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erroChamados = 'Não foi possível carregar os chamados.';
        _carregandoChamados = false;
      });
    }
  }

  Future<void> _carregarMovimentacoes() async {
    if (!mounted) return;

    setState(() {
      _carregandoMovimentacoes = _movimentacoes.isEmpty;
      _erroMovimentacoes = null;
    });

    try {
      final movimentacoes = await context.read<SessaoProvider>().comToken(
        (token) => _ativosService.listarHistorico(
          accessToken: token,
          limite: _limiteMovimentacoes,
        ),
      );

      if (!mounted) return;

      setState(() {
        _movimentacoes = movimentacoes;
        _carregandoMovimentacoes = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erroMovimentacoes = 'Não foi possível carregar as movimentações.';
        _carregandoMovimentacoes = false;
      });
    }
  }

  /// Nome do ativo pelo id, a partir da lista já carregada na Home.
  String _nomeDoAtivo(int ativoId) {
    for (final item in _ativos) {
      if (item is Ativo && item.id == ativoId.toString()) {
        return item.descricao;
      }
    }
    return 'Ativo #$ativoId';
  }

  Widget _buildMovimentacoes() {
    if (_carregandoMovimentacoes) return const _EstadoCarregamento();

    if (_erroMovimentacoes != null) {
      return _PainelGrafico(
        titulo: 'Movimentações indisponíveis',
        subtitulo: _erroMovimentacoes!,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _carregarMovimentacoes,
            style: TextButton.styleFrom(foregroundColor: AppColors.mainColor),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      );
    }

    if (_movimentacoes.isEmpty) {
      return const _PainelGrafico(
        titulo: 'Nenhuma movimentação registrada',
        subtitulo:
            'Cadastros, manutenções, devoluções e inativações aparecem aqui.',
        child: SizedBox.shrink(),
      );
    }

    return Column(
      children: [
        for (final movimentacao in _movimentacoes) ...[
          _CardMovimentacao(
            movimentacao: movimentacao,
            nomeAtivo: _nomeDoAtivo(movimentacao.ativoId),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  /// Ativo de cada chamado, a partir da lista já carregada na Home.
  Ativo? _ativoDoChamado(OrdemManutencao ordem) {
    for (final item in _ativos) {
      if (item is Ativo && item.id == ordem.ativoId.toString()) return item;
    }
    return null;
  }

  Future<void> _abrirChamado(OrdemManutencao ordem) async {
    final alterado = await Navigator.of(context).pushNamed(
      AppRoutes.detalheChamado,
      arguments: ordem.id,
    );

    if (alterado == true && mounted) {
      _carregarChamados();
      _carregarAtivos();
      _carregarMovimentacoes();
    }
  }

  Widget _buildCabecalhoChamados() {
    return Row(
      children: [
        Expanded(child: _buildTituloSecao('Chamados em Aberto')),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.statusOrdem),
          style: TextButton.styleFrom(foregroundColor: AppColors.mainColor),
          child: Text(
            _totalChamadosAbertos > _limiteChamados
                ? 'Ver todos ($_totalChamadosAbertos)'
                : 'Ver todos',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildChamados() {
    if (_carregandoChamados) return const _EstadoCarregamento();

    if (_erroChamados != null) {
      return _PainelGrafico(
        titulo: 'Chamados indisponíveis',
        subtitulo: _erroChamados!,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _carregarChamados,
            style: TextButton.styleFrom(foregroundColor: AppColors.mainColor),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ),
      );
    }

    if (_chamadosAbertos.isEmpty) {
      final podeAbrir = context.watch<SessaoProvider>().podeAlterar;

      return _PainelGrafico(
        titulo: 'Nenhum chamado em aberto',
        subtitulo: 'Todos os chamados foram concluídos ou cancelados.',
        child: podeAbrir
            ? Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.ordemServico),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mainColor,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Abrir chamado'),
                ),
              )
            : const SizedBox.shrink(),
      );
    }

    return Column(
      children: [
        for (final ordem in _chamadosAbertos) ...[
          CardChamado(
            ordem: ordem,
            ativo: _ativoDoChamado(ordem),
            onTap: () => _abrirChamado(ordem),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildSaudacao() {
    final nomeExibido = context.watch<SessaoProvider>().nomeExibicao;

    // Card no mesmo padrão dos painéis da Home (_PainelGrafico).
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.mainColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.waving_hand_outlined,
              color: AppColors.mainColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, $nomeExibido!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bem-vindo ao Easy Asset.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTituloSecao(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildGridResumo(int colunas) {
    final resumo = [
      _ResumoData(
        'Total de Ativos',
        '$_totalAtivos',
        Icons.inventory_2_outlined,
      ),
      _ResumoData(
        'Disponíveis',
        '$_ativosDisponiveis',
        Icons.check_circle_outline,
      ),
      _ResumoData(
        'Em Manutenção',
        '$_ativosEmManutencao',
        Icons.build_outlined,
      ),
      _ResumoData(
        'Devolvidos',
        '$_ativosDevolvidos',
        Icons.assignment_return_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: resumo.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colunas,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 120,
      ),
      itemBuilder: (context, index) {
        final item = resumo[index];

        return CardApp(
          titulo: item.titulo,
          valor: item.valor,
          icone: item.icone,
        );
      },
    );
  }

  Widget _buildGraficoDistribuicao() {
    final quantidades = _quantidadesPorStatus;

    return _PainelGrafico(
      titulo: 'Distribuição por status',
      subtitulo: 'Proporção de ativos cadastrados',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 420;

          final grafico = SizedBox(
            width: compacto ? 160 : 190,
            height: compacto ? 160 : 190,
            child: CustomPaint(
              painter: _DonutPainter(
                valores: _statusInfo
                    .map((status) => quantidades[status.chave] ?? 0)
                    .toList(),
                cores: _statusInfo.map((status) => status.cor).toList(),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_totalAtivos',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'ativos',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          final legenda = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _statusInfo.map((status) {
              final quantidade = quantidades[status.chave] ?? 0;
              final percentual = _totalAtivos == 0
                  ? 0
                  : (quantidade / _totalAtivos * 100).round();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.cor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        status.titulo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$quantidade ($percentual%)',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );

          if (compacto) {
            return Column(
              children: [grafico, const SizedBox(height: 12), legenda],
            );
          }

          return Row(
            children: [
              grafico,
              const SizedBox(width: 20),
              Expanded(child: legenda),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGraficoPorStatus() {
    final quantidades = _quantidadesPorStatus;

    final maiorQuantidade = _statusInfo.fold<int>(0, (maior, status) {
      final valor = quantidades[status.chave] ?? 0;
      return math.max(maior, valor);
    });

    return _PainelGrafico(
      titulo: 'Quantidade por status',
      subtitulo: 'Comparativo entre as categorias',
      child: Column(
        children: _statusInfo.map((status) {
          final quantidade = quantidades[status.chave] ?? 0;
          final proporcao = maiorQuantidade == 0
              ? 0.0
              : quantidade / maiorQuantidade;

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        status.titulo,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '$quantidade',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            height: 10,
                            color: AppColors.lightBackgroundColor,
                          ),
                          Container(
                            width: constraints.maxWidth * proporcao,
                            height: 10,
                            decoration: BoxDecoration(
                              color: status.cor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.backgroundCards,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: AppColors.error),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Erro ao carregar os ativos',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _erro!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _carregarAtivos,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelGrafico extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget child;

  const _PainelGrafico({
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            titulo,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<int> valores;
  final List<Color> cores;

  _DonutPainter({required this.valores, required this.cores});

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 22.0;
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = (math.min(size.width, size.height) - espessura) / 2;
    final retangulo = Rect.fromCircle(center: centro, radius: raio);
    final total = valores.fold<int>(0, (soma, valor) => soma + valor);

    final fundo = Paint()
      ..color = AppColors.lightBackgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = espessura;

    canvas.drawCircle(centro, raio, fundo);

    if (total == 0) return;

    var anguloInicial = -math.pi / 2;

    for (var i = 0; i < valores.length; i++) {
      if (valores[i] <= 0) continue;

      final angulo = valores[i] / total * 2 * math.pi;

      final pincel = Paint()
        ..color = cores[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(retangulo, anguloInicial, angulo, false, pincel);

      anguloInicial += angulo;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.valores != valores || oldDelegate.cores != cores;
  }
}

class _EstadoCarregamento extends StatelessWidget {
  const _EstadoCarregamento();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.mainColor),
      ),
    );
  }
}

class _MensagemGraficoIndisponivel extends StatelessWidget {
  const _MensagemGraficoIndisponivel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Os gráficos estarão disponíveis quando os ativos forem carregados.',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
    );
  }
}

class _ResumoData {
  final String titulo;
  final String valor;
  final IconData icone;

  const _ResumoData(this.titulo, this.valor, this.icone);
}

class _StatusInfo {
  final String chave;
  final String titulo;
  final Color cor;

  const _StatusInfo({
    required this.chave,
    required this.titulo,
    required this.cor,
  });
}

// ================================================================
// CARD DE UMA MOVIMENTAÇÃO (evento do histórico de um ativo)
// ================================================================

class _CardMovimentacao extends StatelessWidget {
  final Movimentacao movimentacao;
  final String nomeAtivo;

  const _CardMovimentacao({
    required this.movimentacao,
    required this.nomeAtivo,
  });

  @override
  Widget build(BuildContext context) {
    final evento = movimentacao.tipoEvento;
    final cor = EventoAtivo.cor(evento);
    final usuario = movimentacao.usuarioNome;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCards,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(EventoAtivo.icone(evento), color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EventoAtivo.rotulo(evento),
                  style: TextStyle(
                    color: cor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nomeAtivo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (movimentacao.descricao.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movimentacao.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    if (usuario != null && usuario.isNotEmpty) usuario,
                    dataHoraFormatada(movimentacao.data),
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
