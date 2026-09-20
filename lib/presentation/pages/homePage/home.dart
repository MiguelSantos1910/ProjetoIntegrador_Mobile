import 'package:flutter/material.dart';

import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/cardsManutencao/maintence_card.dart';
import 'package:mobile_integrador/presentation/widgets/shared/notificacao/notification.dart';
import 'package:mobile_integrador/presentation/pages/homePage/homeWidgets/acao_rapida.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';
import 'package:mobile_integrador/presentation/widgets/shared/card/card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const List<_ResumoData> _resumo = [
    _ResumoData('Total de Ativos', '128', Icons.inventory_2_outlined),
    _ResumoData('Disponíveis', '102', Icons.check_circle_outline),
    _ResumoData('Em Manutenção', '12', Icons.build_outlined),
    _ResumoData('Atenção', '14', Icons.warning_amber_outlined),
  ];

  static const List<_QuickActionData> _acoes = [
    _QuickActionData(
      Icons.report_problem_outlined,
      'Abrir Chamado',
      AppRoutes.ordemServico,
    ),
    _QuickActionData(Icons.qr_code_scanner, 'Escanear QR', AppRoutes.qrCode),
    _QuickActionData(
      Icons.list_alt_outlined,
      'Lista de Ativos',
      AppRoutes.exibirAtivos,
    ),
    _QuickActionData(
      Icons.map_outlined,
      'Localizar Ativo',
      AppRoutes.localizarAtivo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // SAUDAÇÃO
            // ======================================================
            const Text(
              'Olá, Usuário!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bem-vindo ao Easy Asset.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // ======================================================
            // RESUMO DOS ATIVOS
            // ======================================================
            const _SectionTitle('Resumo dos Ativos'),
            const SizedBox(height: 12),
            // Apenas 4 cards fixos, sem scroll próprio — um GridView aqui
            // pagaria o custo de layout de grade para algo que duas Rows
            // resolvem de forma mais simples e barata.
            Row(
              children: [
                Expanded(child: _resumoCard(_resumo[0])),
                const SizedBox(width: 12),
                Expanded(child: _resumoCard(_resumo[1])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _resumoCard(_resumo[2])),
                const SizedBox(width: 12),
                Expanded(child: _resumoCard(_resumo[3])),
              ],
            ),
            const SizedBox(height: 28),

            // ======================================================
            // AÇÕES RÁPIDAS
            // ======================================================
            const _SectionTitle('Ações Rápidas'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _quickAction(context, _acoes[0])),
                const SizedBox(width: 12),
                Expanded(child: _quickAction(context, _acoes[1])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _quickAction(context, _acoes[2])),
                const SizedBox(width: 12),
                Expanded(child: _quickAction(context, _acoes[3])),
              ],
            ),
            const SizedBox(height: 28),

            // ======================================================
            // NOTIFICAÇÕES
            // ======================================================
            const _SectionTitle('Notificações Recentes'),
            const SizedBox(height: 12),
            NotificationWidget(
              type: NotificationType.warning,
              title: 'Manutenção próxima',
              description: 'Existe uma manutenção próxima do vencimento.',
              name: 'Notebook Lenovo',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            NotificationWidget(
              type: NotificationType.success,
              title: 'Manutenção concluída',
              description: 'A manutenção foi concluída com sucesso.',
              name: 'Projetor Epson',
              onTap: () {},
            ),
            const SizedBox(height: 28),

            // ======================================================
            // PRÓXIMAS MANUTENÇÕES
            // ======================================================
            const _SectionTitle('Próximas Manutenções'),
            const SizedBox(height: 12),
            const MaintenanceCard(
              asset: 'Notebook Dell Latitude 5520',
              date: '20/09/2026',
              type: 'Manutenção preventiva',
            ),
            const SizedBox(height: 10),
            const MaintenanceCard(
              asset: 'Projetor Epson',
              date: '25/09/2026',
              type: 'Limpeza',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _resumoCard(_ResumoData d) {
    return CardApp(titulo: d.titulo, valor: d.valor, icone: d.icone);
  }

  Widget _quickAction(BuildContext context, _QuickActionData a) {
    return QuickAction(
      icon: a.icon,
      title: a.title,
      onTap: () => Navigator.pushNamed(context, a.route),
    );
  }
}

// ==================================================================
// TÍTULO DE SEÇÃO — evita repetir o mesmo TextStyle 4x na página
// ==================================================================

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ==================================================================
// DADOS DOS CARDS DE RESUMO E DAS AÇÕES RÁPIDAS
// ==================================================================

class _ResumoData {
  final String titulo;
  final String valor;
  final IconData icone;

  const _ResumoData(this.titulo, this.valor, this.icone);
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String route;

  const _QuickActionData(this.icon, this.title, this.route);
}
