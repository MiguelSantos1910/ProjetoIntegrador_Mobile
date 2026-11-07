import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/core/utils/formatar_data.dart';
import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/models/log_ordem.dart';
import 'package:mobile_integrador/data/models/ordem_manutencao.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/data/repositories/ordens_service.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/botaoApp/custom_button.dart';
import 'package:mobile_integrador/presentation/widgets/shared/linhaDetalhe/linha_detalhe.dart';
import 'package:mobile_integrador/presentation/widgets/shared/statusBadge/status_badge.dart';
import 'package:mobile_integrador/routes/routes.dart';

/// Detalhe de um chamado (ordem de manutenção), no mesmo conteúdo da tela
/// "Detalhes da Manutenção" do painel web, mais o histórico da ordem.
///
/// Professor e suporte podem mudar o status (iniciar, concluir ou
/// cancelar). Ao sair, devolve true se o chamado foi alterado, para a
/// lista recarregar.
class DetalheChamadoPage extends StatefulWidget {
  final int ordemId;

  const DetalheChamadoPage({super.key, required this.ordemId});

  @override
  State<DetalheChamadoPage> createState() => _DetalheChamadoPageState();
}

class _DetalheChamadoPageState extends State<DetalheChamadoPage> {
  final OrdensService _ordensService = OrdensService();
  final AtivosService _ativosService = AtivosService();

  OrdemManutencao? _ordem;
  Ativo? _ativo;
  List<LogOrdem> _logs = [];

  bool _carregando = true;
  String? _erro;
  bool _alterando = false;
  bool _foiAlterado = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _ordensService.dispose();
    _ativosService.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Dados
  // ------------------------------------------------------------------

  Future<void> _carregar() async {
    setState(() {
      _carregando = _ordem == null;
      _erro = null;
    });

    final sessao = context.read<SessaoProvider>();

    try {
      final ordem = await sessao.comToken(
        (token) =>
            _ordensService.buscarOrdem(accessToken: token, id: widget.ordemId),
      );

      // Ativo e histórico em paralelo; se um falhar, a tela continua.
      final resultados = await Future.wait<Object?>([
        sessao
            .comToken(
              (token) => _ativosService.buscarAtivo(
                accessToken: token,
                id: ordem.ativoId.toString(),
              ),
            )
            .then<Object?>((ativo) => ativo, onError: (_) => null),
        sessao
            .comToken(
              (token) =>
                  _ordensService.buscarLogs(accessToken: token, id: ordem.id),
            )
            .then<Object?>((logs) => logs, onError: (_) => <LogOrdem>[]),
      ]);

      if (!mounted) return;

      setState(() {
        _ordem = ordem;
        _ativo = resultados[0] as Ativo?;
        _logs = resultados[1] as List<LogOrdem>;
        _carregando = false;
      });
    } on ApiException catch (e) {
      if (!mounted || !_sessaoAtiva()) return;

      setState(() {
        _erro = e.mensagem;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o chamado.';
        _carregando = false;
      });
    }
  }

  bool _sessaoAtiva() {
    if (context.read<SessaoProvider>().logado) return true;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
    return false;
  }

  // ------------------------------------------------------------------
  // Ações de status
  // ------------------------------------------------------------------

  Future<void> _mudarStatus(
    String novoStatus, {
    bool devolverAtivo = false,
  }) async {
    final ordem = _ordem;
    if (ordem == null || _alterando) return;

    final sessao = context.read<SessaoProvider>();
    setState(() => _alterando = true);

    try {
      await sessao.comToken(
        (token) => _ordensService.atualizarStatus(
          accessToken: token,
          id: ordem.id,
          status: novoStatus,
        ),
      );

      // Concluído: o ativo volta ao uso (o back grava RETORNO).
      String? aviso;
      final ativo = _ativo;

      if (devolverAtivo && ativo != null) {
        try {
          await sessao.comToken(
            (token) => _ativosService.atualizarStatus(
              accessToken: token,
              id: ativo.id,
              status: StatusAtivo.ativo,
            ),
          );
        } catch (_) {
          aviso =
              'Chamado atualizado, mas não foi possível mudar o status do '
              'ativo.';
        }
      }

      _foiAlterado = true;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(aviso ?? 'Chamado atualizado para "$novoStatus".'),
          backgroundColor: aviso == null ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _carregar();
    } on ApiException catch (e) {
      if (!mounted || !_sessaoAtiva()) return;
      _mostrarErro(e.mensagem);
    } catch (_) {
      if (!mounted) return;
      _mostrarErro('Não foi possível atualizar o chamado.');
    } finally {
      if (mounted) setState(() => _alterando = false);
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

  Future<void> _confirmarCancelamento() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar chamado?'),
        content: const Text(
          'O chamado continua no histórico com o status "Cancelada". '
          'Esta ação fica registrada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar chamado'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _mudarStatus(StatusOrdem.cancelada);
    }
  }

  Future<void> _confirmarConclusao() async {
    final ativoEmManutencao =
        _ativo != null &&
        StatusAtivo.normalizar(_ativo!.status) == StatusAtivo.emManutencao;

    var devolverAtivo = ativoEmManutencao;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialogo) => AlertDialog(
          title: const Text('Concluir chamado?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O chamado será marcado como "Concluída" e a data de '
                'conclusão será registrada.',
              ),
              if (ativoEmManutencao) ...[
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: devolverAtivo,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.mainColor,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (valor) =>
                      setStateDialogo(() => devolverAtivo = valor ?? false),
                  title: const Text(
                    'Voltar o ativo para "Ativo" (retorno ao uso)',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Voltar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mainColor,
              ),
              child: const Text('Concluir'),
            ),
          ],
        ),
      ),
    );

    if (confirmado == true) {
      await _mudarStatus(StatusOrdem.concluida, devolverAtivo: devolverAtivo);
    }
  }

  // ------------------------------------------------------------------
  // Interface
  // ------------------------------------------------------------------

  String _formatarCusto(String? valor) {
    final numero = double.tryParse(valor ?? '');
    if (numero == null) return 'Não informado';

    return 'R\$ ${numero.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Widget _cartao({String? titulo, required Widget child}) {
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
          if (titulo != null) ...[
            Text(
              titulo,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }

  Widget _quadradoIcone(IconData icone, Color cor, {double tamanho = 52}) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icone, color: cor, size: tamanho * 0.5),
    );
  }

  Widget _buildCabecalho(OrdemManutencao ordem) {
    final cor = StatusOrdem.cor(ordem.status);

    return _cartao(
      child: Row(
        children: [
          _quadradoIcone(StatusOrdem.icone(ordem.status), cor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chamado #${ordem.id}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aberto em ${dataHoraFormatada(ordem.dataAbertura)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                StatusOrdemBadge(status: ordem.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtivo(OrdemManutencao ordem) {
    final ativo = _ativo;

    if (ativo == null) {
      return _cartao(
        titulo: 'Ativo',
        child: Text(
          'Ativo #${ordem.ativoId} (não foi possível carregar os dados).',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return _cartao(
      titulo: 'Ativo',
      child: Column(
        children: [
          Row(
            children: [
              _quadradoIcone(
                StatusAtivo.iconeTipo(ativo.tipo),
                AppColors.mainColor,
                tamanho: 44,
              ),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: ativo.status),
                  ],
                ),
              ),
            ],
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
          ),
          LinhaDetalhe(
            icone: Icons.place_outlined,
            rotulo: 'Local (sala)',
            valor: ativo.sala.isEmpty ? 'Não informado' : ativo.sala,
            ultima: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInformacoes(OrdemManutencao ordem) {
    return _cartao(
      titulo: 'Informações',
      child: Column(
        children: [
          LinhaDetalhe(
            icone: Icons.engineering_outlined,
            rotulo: 'Responsável',
            valor: ordem.responsavel.isEmpty
                ? 'Não informado'
                : ordem.responsavel,
          ),
          LinhaDetalhe(
            icone: Icons.event_outlined,
            rotulo: 'Abertura',
            valor: dataHoraFormatada(ordem.dataAbertura),
          ),
          LinhaDetalhe(
            icone: Icons.event_available_outlined,
            rotulo: 'Conclusão',
            valor: ordem.dataConclusao == null
                ? 'Não concluído'
                : dataHoraFormatada(ordem.dataConclusao),
          ),
          LinhaDetalhe(
            icone: Icons.payments_outlined,
            rotulo: 'Custo estimado',
            valor: _formatarCusto(ordem.custoEstimado),
            ultima: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDescricao(OrdemManutencao ordem) {
    return _cartao(
      titulo: 'Descrição',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.lightBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          ordem.descricao.isEmpty
              ? 'Nenhuma descrição informada.'
              : ordem.descricao,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Widget _buildHistorico() {
    if (_logs.isEmpty) {
      return _cartao(
        titulo: 'Histórico',
        child: const Text(
          'Nenhum registro no histórico.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return _cartao(
      titulo: 'Histórico',
      child: Column(
        children: [
          for (int i = 0; i < _logs.length; i++)
            _ItemHistorico(log: _logs[i], ultimo: i == _logs.length - 1),
        ],
      ),
    );
  }

  Widget _buildAcoes(OrdemManutencao ordem) {
    if (!StatusOrdem.aberta(ordem.status)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ordem.status == StatusOrdem.pendente) ...[
          BotaoApp(
            texto: 'Iniciar atendimento',
            icone: Icons.play_arrow_rounded,
            carregando: _alterando,
            onPressed: () => _mudarStatus(StatusOrdem.emAndamento),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _alterando ? null : _confirmarConclusao,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: const BorderSide(color: AppColors.success),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text(
            'Concluir chamado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _alterando ? null : _confirmarCancelamento,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text(
            'Cancelar chamado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final ordem = _ordem;

    if (_erro != null || ordem == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _quadradoIcone(
                Icons.cloud_off_outlined,
                AppColors.mainColor,
                tamanho: 64,
              ),
              const SizedBox(height: 14),
              Text(
                _erro ?? 'Chamado não encontrado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mainColor,
                ),
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final podeAlterar = context.watch<SessaoProvider>().podeAlterar;

    return RefreshIndicator(
      color: AppColors.mainColor,
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildCabecalho(ordem),
          const SizedBox(height: 12),
          _buildAtivo(ordem),
          const SizedBox(height: 12),
          _buildInformacoes(ordem),
          const SizedBox(height: 12),
          _buildDescricao(ordem),
          const SizedBox(height: 12),
          _buildHistorico(),
          if (podeAlterar) ...[
            const SizedBox(height: 20),
            _buildAcoes(ordem),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Devolve se houve alteração, para a lista recarregar.
        if (!didPop) Navigator.of(context).pop(_foiAlterado);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Detalhe do chamado',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: _buildConteudo(),
      ),
    );
  }
}

// ================================================================
// ITEM DO HISTÓRICO (linha do tempo)
// ================================================================

class _ItemHistorico extends StatelessWidget {
  final LogOrdem log;
  final bool ultimo;

  const _ItemHistorico({required this.log, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final cor = log.statusNovo.isEmpty
        ? AppColors.mainColor
        : StatusOrdem.cor(log.statusNovo);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              if (!ultimo)
                Expanded(
                  child: Container(width: 2, color: AppColors.borderColor),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.acao.isEmpty ? 'Registro' : log.acao,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (log.descricao.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      log.descricao,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    dataHoraFormatada(log.data),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
