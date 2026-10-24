import 'package:flutter/material.dart';

import 'package:mobile_integrador/data/models/ativo.dart';
import 'package:mobile_integrador/data/repositories/ativos_service.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/tabela/table.dart';

class AtivosPage extends StatefulWidget {
  final String acessToken;

  const AtivosPage({super.key, required this.acessToken});

  @override
  State<AtivosPage> createState() => _AtivosPageState();
}

class _AtivosPageState extends State<AtivosPage> {
  final AtivosService _ativosService = AtivosService();
  final TextEditingController _buscaController = TextEditingController();

  bool _carregando = true;
  String? _erro;

  String _filtroStatus = 'Todos';
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
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _ativosService.buscarAtivos(
        accessToken: widget.acessToken,
      );

      if (!mounted) return;

      setState(() {
        _ativos = resultado;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar os ativos.';
        _carregando = false;
      });
    }
  }

  List<Ativo> get _ativosFiltrados {
    return _ativos.where((ativo) {
      final termo = _busca.trim().toLowerCase();

      final correspondeBusca =
          termo.isEmpty ||
          ativo.descricao.toLowerCase().contains(termo) ||
          (ativo.numeroPatrimonio ?? '').toLowerCase().contains(termo) ||
          ativo.tipo.toLowerCase().contains(termo) ||
          ativo.sala.toLowerCase().contains(termo);

      final status = ativo.status.trim().toUpperCase();
      final correspondeStatus =
          _filtroStatus == 'Todos' || status == _filtroStatus.toUpperCase();

      return correspondeBusca && correspondeStatus;
    }).toList();
  }

  int _contarStatus(String status) {
    return _ativos
        .where((ativo) => ativo.status.trim().toUpperCase() == status)
        .length;
  }

  String _formatarStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'ATIVO':
        return 'Ativo';
      case 'EM_MANUTENCAO':
      case 'EM MANUTENÇÃO':
        return 'Em manutenção';
      case 'DEVOLVIDO':
        return 'Devolvido';
      case 'INATIVO':
        return 'Inativo';
      default:
        return status.isEmpty ? 'Não informado' : status;
    }
  }

  Widget _buildIndicador({
    required String titulo,
    required int quantidade,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCards,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantidade',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstado({
    required IconData icone,
    required String titulo,
    required String descricao,
    Widget? acao,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 52, color: AppColors.textSecondary),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ativos = _ativosFiltrados;

    return Scaffold(
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
          : _erro != null
          ? _buildEstado(
              icone: Icons.cloud_off_outlined,
              titulo: 'Não foi possível carregar',
              descricao: _erro!,
              acao: ElevatedButton.icon(
                onPressed: _carregarAtivos,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregarAtivos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Gestão de patrimônio',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Consulte e acompanhe os ativos cadastrados.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final indicadores = [
                        _buildIndicador(
                          titulo: 'Total de ativos',
                          quantidade: _ativos.length,
                          icone: Icons.inventory_2_outlined,
                          cor: AppColors.mainColor,
                        ),
                        _buildIndicador(
                          titulo: 'Disponíveis',
                          quantidade: _contarStatus('ATIVO'),
                          icone: Icons.check_circle_outline,
                          cor: Colors.green,
                        ),
                        _buildIndicador(
                          titulo: 'Em manutenção',
                          quantidade:
                              _contarStatus('EM_MANUTENCAO') +
                              _contarStatus('EM MANUTENÇÃO'),
                          icone: Icons.build_outlined,
                          cor: Colors.orange,
                        ),
                      ];

                      if (constraints.maxWidth < 440) {
                        return Column(
                          children: [
                            for (int i = 0; i < indicadores.length; i++) ...[
                              indicadores[i],
                              if (i < indicadores.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < indicadores.length; i++) ...[
                            Expanded(child: indicadores[i]),
                            if (i < indicadores.length - 1)
                              const SizedBox(width: 12),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _buscaController,
                    onChanged: (valor) {
                      setState(() => _busca = valor);
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar descrição, patrimônio ou sala',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busca.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _buscaController.clear();
                                setState(() => _busca = '');
                              },
                              icon: const Icon(Icons.close),
                            )
                          : null,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: _filtroStatus,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por status',
                      prefixIcon: const Icon(Icons.filter_list),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Todos',
                        child: Text('Todos os status'),
                      ),
                      DropdownMenuItem(value: 'ATIVO', child: Text('Ativo')),
                      DropdownMenuItem(
                        value: 'EM_MANUTENCAO',
                        child: Text('Em manutenção'),
                      ),
                      DropdownMenuItem(
                        value: 'DEVOLVIDO',
                        child: Text('Devolvido'),
                      ),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setState(() => _filtroStatus = valor);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  Tabela(
                    titulo: 'Lista de ativos (${ativos.length})',
                    colunas: const [
                      'ID',
                      'Descrição',
                      'Tipo',
                      'Patrimônio',
                      'Status',
                      'Sala',
                    ],
                    dados: ativos.map((ativo) {
                      return [
                        ativo.id,
                        ativo.descricao,
                        ativo.tipo,
                        ativo.numeroPatrimonio ?? '—',
                        _formatarStatus(ativo.status),
                        ativo.sala,
                      ];
                    }).toList(),
                  ),

                  if (ativos.isEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhum ativo corresponde à busca ou ao filtro.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
