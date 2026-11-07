import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/form/form.dart';
import 'package:mobile_integrador/presentation/widgets/shared/linhaDetalhe/linha_detalhe.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/routes/routes.dart';

/// Localizar ativo pela sala (o local cadastrado no back).
///
/// - Busca: mostra direto em que sala o ativo está.
/// - Salas: quantidade de ativos e resumo por status; tocar lista os ativos.
/// - Professor e suporte podem mover o ativo de sala.
class LocalizarPage extends StatefulWidget {
  const LocalizarPage({super.key});

  @override
  State<LocalizarPage> createState() => _LocalizarPageState();
}

class _LocalizarPageState extends State<LocalizarPage> {
  static const String _semSala = 'Sem sala';

  final AtivosService _ativosService = AtivosService();
  final TextEditingController _buscaController = TextEditingController();

  List<Ativo> _ativos = [];
  bool _carregando = true;
  String? _erro;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _ativosService.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _ativos.isEmpty;
      _erro = null;
    });

    final sessao = context.read<SessaoProvider>();

    try {
      final ativos = await sessao.comToken(
        (token) => _ativosService.buscarAtivos(accessToken: token),
      );

      if (!mounted) return;

      ativos.sort(
        (a, b) =>
            a.descricao.toLowerCase().compareTo(b.descricao.toLowerCase()),
      );

      setState(() {
        _ativos = ativos;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      if (!sessao.logado) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
        return;
      }

      setState(() {
        _erro = 'Verifique a conexão com o servidor e tente novamente.';
        _carregando = false;
      });
    }
  }

  // ------------------------------------------------------------------
  // Dados
  // ------------------------------------------------------------------

  String _salaDe(Ativo ativo) =>
      ativo.sala.trim().isEmpty ? _semSala : ativo.sala.trim();

  /// Salas em ordem alfabética, cada uma com seus ativos.
  Map<String, List<Ativo>> get _porSala {
    final mapa = <String, List<Ativo>>{};

    for (final ativo in _ativos) {
      mapa.putIfAbsent(_salaDe(ativo), () => []).add(ativo);
    }

    final salas = mapa.keys.toList()..sort();
    return {for (final sala in salas) sala: mapa[sala]!};
  }

  List<Ativo> get _resultadosBusca {
    final termo = _busca.trim().toLowerCase();
    if (termo.isEmpty) return [];

    return _ativos.where((ativo) {
      return ativo.descricao.toLowerCase().contains(termo) ||
          (ativo.numeroPatrimonio ?? '').toLowerCase().contains(termo) ||
          ativo.codigoQr.toLowerCase().contains(termo) ||
          StatusAtivo.rotuloTipo(ativo.tipo).toLowerCase().contains(termo);
    }).toList();
  }

  // ------------------------------------------------------------------
  // Ações
  // ------------------------------------------------------------------

  void _abrirSala(String sala, List<Ativo> ativos) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (contextoFolha) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(contextoFolha).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      const _QuadradoIcone(icone: Icons.meeting_room_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sala,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              ativos.length == 1
                                  ? '1 ativo nesta sala'
                                  : '${ativos.length} ativos nesta sala',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderColor),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: ativos.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: AppColors.borderColor,
                    ),
                    itemBuilder: (_, index) => _ItemAtivo(
                      ativo: ativos[index],
                      onTap: () {
                        Navigator.of(contextoFolha).pop();
                        _abrirAtivo(ativos[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirAtivo(Ativo ativo) {
    final podeMover = context.read<SessaoProvider>().podeAlterar;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (contextoFolha) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _QuadradoIcone(icone: StatusAtivo.iconeTipo(ativo.tipo)),
                    const SizedBox(width: 12),
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
                              fontSize: 17,
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
                const SizedBox(height: 18),

                // Destaque do local: a resposta principal da tela.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.mainColor.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        color: AppColors.mainColor,
                        size: 30,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Está em',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _salaDe(ativo),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                  ultima: true,
                ),
                if (podeMover) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(contextoFolha).pop();
                        _moverDeSala(ativo);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.move_down_rounded),
                      label: const Text(
                        'Mover de sala',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _moverDeSala(Ativo ativo) async {
    final salasExistentes = _porSala.keys
        .where((sala) => sala != _semSala && sala != _salaDe(ativo))
        .toList();

    final novaSala = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.backgroundCards,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FolhaMoverSala(
        ativo: ativo,
        salaAtual: _salaDe(ativo),
        sugestoes: salasExistentes,
      ),
    );

    if (novaSala == null || !mounted) return;

    final sessao = context.read<SessaoProvider>();

    try {
      final atualizado = await sessao.comToken(
        (token) => _ativosService.atualizarSala(
          accessToken: token,
          id: ativo.id,
          sala: novaSala,
        ),
      );

      if (!mounted) return;

      setState(() {
        _ativos = [
          for (final item in _ativos)
            item.id == atualizado.id ? atualizado : item,
        ];
      });

      _mostrar('${ativo.descricao} agora está em $novaSala.');
    } on ApiException catch (e) {
      if (!mounted) return;
      _mostrar(e.errosPorCampo['sala'] ?? e.mensagem, erro: true);
    }
  }

  void _mostrar(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

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
          _QuadradoIcone(icone: icone, tamanho: 64),
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

  Widget _buildResultadosBusca() {
    final resultados = _resultadosBusca;

    if (resultados.isEmpty) {
      return _buildEstado(
        icone: Icons.search_off_rounded,
        titulo: 'Nenhum ativo encontrado',
        descricao: 'Tente o nome, o patrimônio ou o código do ativo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resultados.length == 1
              ? '1 ativo encontrado'
              : '${resultados.length} ativos encontrados',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (final ativo in resultados) ...[
          _CardResultado(
            ativo: ativo,
            sala: _salaDe(ativo),
            onTap: () => _abrirAtivo(ativo),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildSalas() {
    final salas = _porSala;

    if (salas.isEmpty) {
      return _buildEstado(
        icone: Icons.meeting_room_outlined,
        titulo: 'Nenhum ativo cadastrado',
        descricao: 'Os ativos cadastrados no painel web aparecem aqui.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          salas.length == 1 ? '1 sala' : '${salas.length} salas',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (final entrada in salas.entries) ...[
          _CardSala(
            sala: entrada.key,
            ativos: entrada.value,
            onTap: () => _abrirSala(entrada.key, entrada.value),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Localizar Ativo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregar,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.mainColor,
              onRefresh: _carregar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const Text(
                    'Onde está o ativo?',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Busque um ativo para ver a sala em que ele está, ou '
                    'abra uma sala para ver os ativos dela.',
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
                        hintText: 'Buscar por nome, patrimônio ou código',
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
                    const SizedBox(height: 18),
                    if (_busca.trim().isNotEmpty)
                      _buildResultadosBusca()
                    else
                      _buildSalas(),
                  ],
                ],
              ),
            ),
    );
  }
}

// ================================================================
// COMPONENTES DA TELA
// ================================================================

class _QuadradoIcone extends StatelessWidget {
  final IconData icone;
  final double tamanho;

  const _QuadradoIcone({required this.icone, this.tamanho = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: AppColors.mainColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icone, color: AppColors.mainColor, size: tamanho * 0.5),
    );
  }
}

/// "2 ativos", "1 inativo", "3 em manutenção"...
String _resumoStatus(String status, int quantidade) {
  const plurais = {
    StatusAtivo.ativo: ('ativo', 'ativos'),
    StatusAtivo.inativo: ('inativo', 'inativos'),
    StatusAtivo.devolvido: ('devolvido', 'devolvidos'),
    StatusAtivo.emManutencao: ('em manutenção', 'em manutenção'),
  };
  final (singular, plural) =
      plurais[status] ?? (StatusAtivo.rotulo(status).toLowerCase(), '');
  return '$quantidade ${quantidade == 1 || plural.isEmpty ? singular : plural}';
}

/// Card de uma sala: nome, total e resumo por status.
class _CardSala extends StatelessWidget {
  final String sala;
  final List<Ativo> ativos;
  final VoidCallback onTap;

  const _CardSala({
    required this.sala,
    required this.ativos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contagem = <String, int>{};
    for (final ativo in ativos) {
      final status = StatusAtivo.normalizar(ativo.status);
      contagem[status] = (contagem[status] ?? 0) + 1;
    }

    return Material(
      color: AppColors.backgroundCards,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _QuadradoIcone(icone: Icons.meeting_room_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sala,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ativos.length == 1
                              ? '1 ativo'
                              : '${ativos.length} ativos',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in StatusAtivo.todos)
                    if ((contagem[status] ?? 0) > 0)
                      Etiqueta(
                        texto:
                            _resumoStatus(status, contagem[status]!),
                        cor: StatusAtivo.cor(status),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resultado da busca: o ativo e, em destaque, a sala onde está.
class _CardResultado extends StatelessWidget {
  final Ativo ativo;
  final String sala;
  final VoidCallback onTap;

  const _CardResultado({
    required this.ativo,
    required this.sala,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              _QuadradoIcone(icone: StatusAtivo.iconeTipo(ativo.tipo)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ativo.descricao.isEmpty
                          ? 'Sem descrição'
                          : ativo.descricao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Patrimônio: diferencia ativos com o mesmo nome.
                    Text(
                      [
                        StatusAtivo.rotuloTipo(ativo.tipo),
                        (ativo.numeroPatrimonio ?? '').isEmpty
                            ? 'sem patrimônio'
                            : 'Pat. ${ativo.numeroPatrimonio}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: ativo.status),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // A sala em destaque, à direita.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.place_rounded,
                    color: AppColors.mainColor,
                    size: 20,
                  ),
                  Text(
                    sala,
                    style: const TextStyle(
                      color: AppColors.mainColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha de um ativo dentro da lista de uma sala.
class _ItemAtivo extends StatelessWidget {
  final Ativo ativo;
  final VoidCallback onTap;

  const _ItemAtivo({required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
      leading: _QuadradoIcone(
        icone: StatusAtivo.iconeTipo(ativo.tipo),
        tamanho: 40,
      ),
      title: Text(
        ativo.descricao.isEmpty ? 'Sem descrição' : ativo.descricao,
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
        ].join(' · '),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: StatusBadge(status: ativo.status),
    );
  }
}

/// Folha "Mover de sala": campo da nova sala e salas já usadas.
/// Widget próprio para o controlador viver até a folha sair da tela.
class _FolhaMoverSala extends StatefulWidget {
  final Ativo ativo;
  final String salaAtual;
  final List<String> sugestoes;

  const _FolhaMoverSala({
    required this.ativo,
    required this.salaAtual,
    required this.sugestoes,
  });

  @override
  State<_FolhaMoverSala> createState() => _FolhaMoverSalaState();
}

class _FolhaMoverSalaState extends State<_FolhaMoverSala> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim().toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mover de sala',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.ativo.descricao} · hoje em ${widget.salaAtual}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            FormData(
              label: 'Nova sala',
              hintText: 'Ex.: B-112',
              prefixIcon: Icons.meeting_room_outlined,
              controller: _controller,
              maxLength: 20,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _confirmar(),
              validator: (valor) {
                final sala = valor?.trim() ?? '';
                if (sala.isEmpty) return 'Informe a sala.';
                if (sala.toUpperCase() == widget.salaAtual.toUpperCase()) {
                  return 'O ativo já está nesta sala.';
                }
                return null;
              },
            ),
            if (widget.sugestoes.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text(
                'Salas já cadastradas',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sala in widget.sugestoes)
                    ActionChip(
                      label: Text(sala),
                      onPressed: () => setState(() => _controller.text = sala),
                      backgroundColor: AppColors.lightBackgroundColor,
                      side: const BorderSide(color: AppColors.borderColor),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirmar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
