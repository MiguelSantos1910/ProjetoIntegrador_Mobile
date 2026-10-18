import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/cardsManutencao/maintence_card.dart';
import 'package:mobile_integrador/presentation/widgets/shared/notificacao/notification.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/card/card.dart';

class HomePage extends StatefulWidget {
  final String accessToken;
  final String username;

  const HomePage({
    super.key,
    required this.accessToken,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AtivosService _ativosService = AtivosService();

  bool _carregando = true;
  String? _erro;
  List<dynamic> _ativos = [];

  static const List<_StatusInfo> _statusInfo = [
    _StatusInfo(chave: 'ATIVO', titulo: 'Disponíveis', cor: Color(0xFF16A34A)),
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
    _StatusInfo(chave: 'INATIVO', titulo: 'Inativos', cor: Color(0xFFDC2626)),
  ];

  @override
  void initState() {
    super.initState();
    _carregarAtivos();
  }

  @override
  void dispose() {
    _ativosService.dispose();
    super.dispose();
  }

  Future<void> _carregarAtivos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _ativosService.buscarAtivos(
        accessToken: widget.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _ativos = resultado;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar os ativos.';
        _carregando = false;
      });
    }
  }

  String _obterStatus(dynamic ativo) {
    if (ativo is! Map) return '';

    final status = ativo['Status'] ?? ativo['status'];

    return status
            ?.toString()
            .trim()
            .toUpperCase()
            .replaceAll(' ', '_')
            .replaceAll('-', '_') ??
        '';
  }

  int _contarStatus(String status) {
    return _ativos.where((ativo) {
      return _obterStatus(ativo) == status;
    }).length;
  }

  int get _totalAtivos => _ativos.length;

  int get _ativosDisponiveis => _contarStatus('ATIVO');

  int get _ativosEmManutencao => _contarStatus('EM_MANUTENCAO');

  int get _ativosAtencao => _contarStatus('INATIVO');

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

                    _buildTituloSecao('Notificações Recentes'),

                    const SizedBox(height: 14),

                    _buildNotificacoes(context),

                    const SizedBox(height: 32),

                    _buildTituloSecao('Próximas Manutenções'),

                    const SizedBox(height: 14),

                    _buildManutencoes(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaudacao() {
    final username = widget.username.trim();
    final nomeExibido = username.isEmpty ? 'Usuário' : username;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, $nomeExibido!',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Bem-vindo ao Easy Asset.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
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
      _ResumoData('Atenção', '$_ativosAtencao', Icons.warning_amber_outlined),
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

  Widget _buildNotificacoes(BuildContext context) {
    return Column(
      children: [
        NotificationWidget(
          type: NotificationType.warning,
          title: 'Manutenção próxima',
          description: 'Existe uma manutenção próxima do vencimento.',
          name: 'Notebook Lenovo',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.ordemServico);
          },
        ),
        const SizedBox(height: 12),
        NotificationWidget(
          type: NotificationType.success,
          title: 'Manutenção concluída',
          description: 'A manutenção foi concluída com sucesso.',
          name: 'Projetor Epson',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.ordemServico);
          },
        ),
      ],
    );
  }

  Widget _buildManutencoes() {
    return const Column(
      children: [
        MaintenanceCard(
          asset: 'Notebook Dell Latitude 5520',
          date: '20/09/2026',
          type: 'Manutenção preventiva',
        ),
        SizedBox(height: 12),
        MaintenanceCard(
          asset: 'Projetor Epson',
          date: '25/09/2026',
          type: 'Limpeza',
        ),
      ],
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
