import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/routes/routes.dart';

/// Leitura do QR Code do ativo pela câmera.
///
/// O QR gerado pelo painel web contém só o código do ativo (UUID). O app
/// valida o formato, consulta `GET /api/ativos/?codigo_qr=<código>` e mostra
/// os dados do ativo sobre a câmera, no painel inferior (RA). Se a câmera
/// não funcionar, o código pode ser digitado (consulta convencional).
class QrCodePage extends StatefulWidget {
  const QrCodePage({super.key});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

enum _Estado { lendo, consultando, encontrado, naoEncontrado, invalido, erro }

class _QrCodePageState extends State<QrCodePage>
    with SingleTickerProviderStateMixin {
  // UUID com ou sem hífens (formato do codigo_qr do back).
  static final _padraoCodigo = RegExp(
    r'^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?'
    r'[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$',
  );

  final MobileScannerController _camera = MobileScannerController(
    // normal (e não noDuplicates): permite ler de novo o mesmo QR depois de
    // "Ler outro". Leituras repetidas são ignoradas pelo _estado.
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );
  final AtivosService _ativosService = AtivosService();

  /// Linha de leitura que sobe e desce dentro da moldura.
  late final AnimationController _linha = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  _Estado _estado = _Estado.lendo;
  Ativo? _ativo;
  String? _codigoLido;
  String? _mensagemErro;
  bool _lanterna = false;

  @override
  void dispose() {
    _linha.dispose();
    _camera.dispose();
    _ativosService.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Leitura e consulta
  // ------------------------------------------------------------------

  void _aoDetectar(BarcodeCapture captura) {
    // Enquanto um resultado está na tela, novas leituras são ignoradas.
    if (_estado != _Estado.lendo) return;

    for (final barcode in captura.barcodes) {
      final valor = barcode.rawValue?.trim();
      if (valor != null && valor.isNotEmpty) {
        _consultar(valor);
        return;
      }
    }
  }

  Future<void> _consultar(String codigo) async {
    HapticFeedback.mediumImpact();

    setState(() {
      _codigoLido = codigo;
      _ativo = null;
      _mensagemErro = null;
      _estado = _Estado.consultando;
    });

    // QR de outro sistema (texto, link, etc.): nem consulta a API.
    if (!_padraoCodigo.hasMatch(codigo)) {
      setState(() => _estado = _Estado.invalido);
      return;
    }

    final sessao = context.read<SessaoProvider>();

    try {
      final ativo = await sessao.comToken(
        (token) => _ativosService.buscarPorCodigo(
          accessToken: token,
          codigo: codigo.toLowerCase(),
        ),
      );

      if (!mounted) return;

      setState(() {
        _ativo = ativo;
        _estado = ativo == null ? _Estado.naoEncontrado : _Estado.encontrado;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      if (!sessao.logado) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        return;
      }

      setState(() {
        _mensagemErro = e.mensagem;
        _estado = _Estado.erro;
      });
    }
  }

  void _lerOutro() {
    setState(() {
      _estado = _Estado.lendo;
      _ativo = null;
      _codigoLido = null;
      _mensagemErro = null;
    });
  }

  Future<void> _alternarLanterna() async {
    try {
      await _camera.toggleTorch();
      setState(() => _lanterna = !_lanterna);
    } catch (_) {
      _avisar('Este aparelho não tem lanterna disponível.');
    }
  }

  Future<void> _trocarCamera() async {
    try {
      await _camera.switchCamera();
      setState(() => _lanterna = false);
    } catch (_) {
      _avisar('Não foi possível trocar de câmera.');
    }
  }

  void _avisar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  /// Consulta convencional: digitar o código (alternativa à câmera).
  Future<void> _digitarCodigo() async {
    final codigo = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FolhaDigitarCodigo(codigoInicial: _codigoLido ?? ''),
    );

    if (codigo != null && mounted) await _consultar(codigo);
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

  /// Altura aproximada do painel inferior em cada estado. Serve para
  /// centralizar a moldura no espaço livre da câmera, acima do painel.
  double get _alturaPainel {
    switch (_estado) {
      case _Estado.lendo:
        return 196;
      case _Estado.consultando:
        return 124;
      case _Estado.encontrado:
        return 304;
      case _Estado.naoEncontrado:
      case _Estado.invalido:
      case _Estado.erro:
        return 200;
    }
  }

  String get _subtitulo {
    switch (_estado) {
      case _Estado.lendo:
        return 'Procurando QR Code...';
      case _Estado.consultando:
        return 'Consultando o ativo...';
      case _Estado.encontrado:
        return 'Ativo identificado';
      case _Estado.naoEncontrado:
        return 'Código sem ativo cadastrado';
      case _Estado.invalido:
        return 'QR Code não reconhecido';
      case _Estado.erro:
        return 'Falha na consulta';
    }
  }

  Color get _corMoldura {
    switch (_estado) {
      case _Estado.encontrado:
        return AppColors.success;
      case _Estado.naoEncontrado:
      case _Estado.invalido:
        return AppColors.warning;
      case _Estado.erro:
        return AppColors.error;
      case _Estado.lendo:
      case _Estado.consultando:
        return Colors.white;
    }
  }

  Widget _botaoCircular({
    required IconData icone,
    required String dica,
    required VoidCallback onPressed,
    bool ativo = false,
  }) {
    return Tooltip(
      message: dica,
      child: Material(
        color: ativo
            ? AppColors.mainColor
            : Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icone, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  /// Fundo quando a câmera não abre. A mensagem é desenhada pela tela
  /// (centralizada no espaço livre), e a moldura deixa de aparecer.
  Widget _buildErroCamera(BuildContext context, MobileScannerException erro) {
    return const ColoredBox(color: AppColors.textPrimary);
  }

  Widget _buildMensagemSemCamera(MobileScannerException erro, Rect area) {
    final semPermissao =
        erro.errorCode == MobileScannerErrorCode.permissionDenied;

    return Positioned.fromRect(
      rect: area,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              semPermissao
                  ? 'Permissão da câmera negada'
                  : 'Não foi possível abrir a câmera',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              semPermissao
                  ? 'Libere a câmera nas configurações do Android ou digite '
                        'o código do ativo abaixo.'
                  : 'Digite o código do ativo abaixo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Moldura centralizada no espaço livre entre a barra superior e o
          // painel inferior; anima quando o painel muda de altura.
          final inicioLivre = topo + 76;
          final fimLivre = constraints.maxHeight - _alturaPainel;
          final alturaLivre = (fimLivre - inicioLivre).clamp(120.0, 2000.0);

          final lado = [
            constraints.maxWidth * 0.68,
            alturaLivre * 0.82,
            300.0,
          ].reduce((a, b) => a < b ? a : b).clamp(140.0, 300.0);

          final areaLivre = Rect.fromLTWH(
            32,
            inicioLivre,
            constraints.maxWidth - 64,
            alturaLivre,
          );

          final alvo = Rect.fromCenter(
            center: Offset(
              constraints.maxWidth / 2,
              inicioLivre + alturaLivre / 2,
            ),
            width: lado,
            height: lado,
          );

          return TweenAnimationBuilder<Rect?>(
            tween: RectTween(end: alvo),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, moldura, _) {
              final rect = moldura ?? alvo;

              return Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _camera,
                    scanWindow: rect,
                    onDetect: _aoDetectar,
                    errorBuilder: _buildErroCamera,
                  ),

                  // Com câmera: moldura, cantos e linha de leitura.
                  // Sem câmera: só a mensagem, centralizada no espaço livre.
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _camera,
                    builder: (context, camera, _) {
                      final erro = camera.error;

                      if (erro != null) {
                        return Stack(
                          children: [_buildMensagemSemCamera(erro, areaLivre)],
                        );
                      }

                      return IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _linha,
                          builder: (context, _) => CustomPaint(
                            size: Size.infinite,
                            painter: _MolduraPainter(
                              moldura: rect,
                              cor: _corMoldura,
                              progressoLinha: _estado == _Estado.lendo
                                  ? _linha.value
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Barra superior com degradê para o texto ficar legível.
                  Align(
                    alignment: Alignment.topCenter,
                    child: _buildBarraSuperior(),
                  ),

                  // Painel inferior: instruções, resultado e ações.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildPainel(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBarraSuperior() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  // min: a barra fica da altura do título (com max, ela
                  // ocupava a tela e os botões iam para o meio).
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Escanear QR Code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _subtitulo,
                        key: ValueKey(_subtitulo),
                        style: TextStyle(
                          color: _estado == _Estado.lendo
                              ? Colors.white70
                              : _corMoldura,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _botaoCircular(
                icone: _lanterna
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                dica: 'Lanterna',
                ativo: _lanterna,
                onPressed: _alternarLanterna,
              ),
              const SizedBox(width: 10),
              _botaoCircular(
                icone: Icons.cameraswitch_outlined,
                dica: 'Trocar câmera',
                onPressed: _trocarCamera,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPainel() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.backgroundCards,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alça visual do painel.
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(_estado),
                    child: _buildConteudoPainel(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoDigitar() {
    final estilo = OutlinedButton.styleFrom(
      foregroundColor: AppColors.mainColor,
      side: const BorderSide(color: AppColors.mainColor),
      minimumSize: const Size.fromHeight(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    return OutlinedButton.icon(
      onPressed: _digitarCodigo,
      style: estilo,
      icon: const Icon(Icons.keyboard_outlined, size: 20),
      label: const Text(
        'Digitar código',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _botaoLerDeNovo(String texto) {
    return FilledButton.icon(
      onPressed: _lerOutro,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.mainColor,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
      label: Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildConteudoPainel() {
    switch (_estado) {
      case _Estado.lendo:
        return Column(
          children: [
            const _CabecalhoPainel(
              icone: Icons.qr_code_scanner_rounded,
              titulo: 'Aponte para o QR Code do ativo',
              descricao:
                  'A leitura é automática. O QR fica no detalhe do ativo, '
                  'no painel web.',
            ),
            const SizedBox(height: 18),
            _botaoDigitar(),
          ],
        );

      case _Estado.consultando:
        return const _CabecalhoPainel(
          icone: Icons.search,
          titulo: 'Consultando o ativo...',
          descricao: 'Buscando os dados no sistema.',
          carregando: true,
        );

      case _Estado.encontrado:
        final ativo = _ativo!;
        final podeAbrirChamado =
            context.watch<SessaoProvider>().podeAlterar &&
            StatusAtivo.normalizar(ativo.status) != StatusAtivo.inativo;

        return Column(
          children: [
            _ConteudoAtivo(ativo: ativo),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _lerOutro,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mainColor,
                      side: const BorderSide(color: AppColors.mainColor),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Ler outro',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                if (podeAbrirChamado) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.ordemServico, arguments: ativo.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.report_problem_outlined, size: 20),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Abrir chamado',
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

      case _Estado.naoEncontrado:
        return Column(
          children: [
            const _CabecalhoPainel(
              icone: Icons.search_off_rounded,
              cor: AppColors.warning,
              titulo: 'Ativo não encontrado',
              descricao: 'Nenhum ativo cadastrado tem este código.',
            ),
            const SizedBox(height: 18),
            _botaoLerDeNovo('Ler de novo'),
            const SizedBox(height: 8),
            _botaoDigitar(),
          ],
        );

      case _Estado.invalido:
        return Column(
          children: [
            const _CabecalhoPainel(
              icone: Icons.qr_code_2_rounded,
              cor: AppColors.warning,
              titulo: 'QR Code não reconhecido',
              descricao: 'Este QR não é de um ativo do Easy Asset.',
            ),
            const SizedBox(height: 18),
            _botaoLerDeNovo('Ler de novo'),
            const SizedBox(height: 8),
            _botaoDigitar(),
          ],
        );

      case _Estado.erro:
        return Column(
          children: [
            _CabecalhoPainel(
              icone: Icons.cloud_off_outlined,
              cor: AppColors.error,
              titulo: 'Não foi possível consultar',
              descricao:
                  _mensagemErro ?? 'Verifique a conexão e tente novamente.',
            ),
            const SizedBox(height: 18),
            _botaoLerDeNovo('Tentar de novo'),
          ],
        );
    }
  }
}

// ================================================================
// CABEÇALHO DO PAINEL: ícone, título e descrição de cada estado
// ================================================================

class _CabecalhoPainel extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;
  final bool carregando;

  const _CabecalhoPainel({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.cor = AppColors.mainColor,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: carregando
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: cor,
                  ),
                )
              : Icon(icone, color: cor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                descricao,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// CONTEÚDO DE RA: dados do ativo identificado (sobre a câmera)
// ================================================================

class _ConteudoAtivo extends StatelessWidget {
  final Ativo ativo;

  const _ConteudoAtivo({required this.ativo});

  Widget _dado(IconData icone, String rotulo, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lightBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 15, color: AppColors.mainColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patrimonio = (ativo.numeroPatrimonio ?? '').isEmpty
        ? 'Não informado'
        : ativo.numeroPatrimonio!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                StatusAtivo.iconeTipo(ativo.tipo),
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ativo.descricao.isEmpty ? 'Sem descrição' : ativo.descricao,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
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
        const SizedBox(height: 14),
        Row(
          children: [
            _dado(
              Icons.category_outlined,
              'Tipo',
              StatusAtivo.rotuloTipo(ativo.tipo),
            ),
            const SizedBox(width: 8),
            _dado(Icons.confirmation_number_outlined, 'Patrimônio', patrimonio),
            const SizedBox(width: 8),
            _dado(
              Icons.place_outlined,
              'Local',
              ativo.sala.isEmpty ? '—' : ativo.sala,
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// MOLDURA: escurece fora da área de leitura, cantos e linha de leitura
// ================================================================

class _MolduraPainter extends CustomPainter {
  final Rect moldura;
  final Color cor;

  /// 0 a 1: posição da linha de leitura; null esconde a linha.
  final double? progressoLinha;

  const _MolduraPainter({
    required this.moldura,
    required this.cor,
    this.progressoLinha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final recorte = RRect.fromRectAndRadius(moldura, const Radius.circular(22));

    final fundo = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(recorte)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      fundo,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    // Borda fina em volta do recorte.
    canvas.drawRRect(
      recorte,
      Paint()
        ..color = cor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Quatro cantos em "L" arredondados.
    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const tamanho = 30.0;
    const raio = 22.0;
    final r = moldura;

    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + tamanho)
        ..lineTo(r.left, r.top + raio)
        ..arcToPoint(
          Offset(r.left + raio, r.top),
          radius: const Radius.circular(raio),
        )
        ..lineTo(r.left + tamanho, r.top)
        ..moveTo(r.right - tamanho, r.top)
        ..lineTo(r.right - raio, r.top)
        ..arcToPoint(
          Offset(r.right, r.top + raio),
          radius: const Radius.circular(raio),
        )
        ..lineTo(r.right, r.top + tamanho)
        ..moveTo(r.right, r.bottom - tamanho)
        ..lineTo(r.right, r.bottom - raio)
        ..arcToPoint(
          Offset(r.right - raio, r.bottom),
          radius: const Radius.circular(raio),
        )
        ..lineTo(r.right - tamanho, r.bottom)
        ..moveTo(r.left + tamanho, r.bottom)
        ..lineTo(r.left + raio, r.bottom)
        ..arcToPoint(
          Offset(r.left, r.bottom - raio),
          radius: const Radius.circular(raio),
        )
        ..lineTo(r.left, r.bottom - tamanho),
      traco,
    );

    // Linha de leitura (só enquanto procura).
    final progresso = progressoLinha;
    if (progresso != null) {
      final y = r.top + 18 + (r.height - 36) * progresso;
      final linha = Rect.fromLTWH(r.left + 18, y - 1.5, r.width - 36, 3);

      canvas.drawRRect(
        RRect.fromRectAndRadius(linha, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.mainColor.withValues(alpha: 0),
              AppColors.mainColor,
              AppColors.mainColor.withValues(alpha: 0),
            ],
          ).createShader(linha),
      );
    }
  }

  @override
  bool shouldRepaint(_MolduraPainter antigo) =>
      antigo.moldura != moldura ||
      antigo.cor != cor ||
      antigo.progressoLinha != progressoLinha;
}

// ================================================================
// FOLHA "DIGITAR CÓDIGO"
// Widget próprio para o controlador do campo viver até a folha sair da
// tela (descartá-lo antes quebra a animação de fechamento).
// ================================================================

class _FolhaDigitarCodigo extends StatefulWidget {
  final String codigoInicial;

  const _FolhaDigitarCodigo({required this.codigoInicial});

  @override
  State<_FolhaDigitarCodigo> createState() => _FolhaDigitarCodigoState();
}

class _FolhaDigitarCodigoState extends State<_FolhaDigitarCodigo> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.codigoInicial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enviar() {
    final valor = _controller.text.trim();
    if (valor.isNotEmpty) Navigator.of(context).pop(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Digitar código',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use quando a câmera não conseguir ler o QR. O código '
            'aparece no detalhe do ativo, no painel web.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _enviar(),
            decoration: FormData.decoracaoPadrao(
              hintText: 'Código do ativo',
              prefixIcon: Icons.qr_code_2_rounded,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.search),
              label: const Text(
                'Consultar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
