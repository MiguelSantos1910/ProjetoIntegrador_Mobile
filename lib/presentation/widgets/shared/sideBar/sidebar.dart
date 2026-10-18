import 'package:flutter/material.dart';

import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

class SideBar extends StatelessWidget {
  // Mantidos opcionais para facilitar a migração do código existente.
  final bool aberta;
  final VoidCallback? onToggle;

  const SideBar({super.key, this.aberta = true, this.onToggle});

  static const List<_SidebarItemData> _itensPrincipais = [
    _SidebarItemData(Icons.home_outlined, 'Início', AppRoutes.home),
    _SidebarItemData(
      Icons.report_problem_outlined,
      'Chamado',
      AppRoutes.ordemServico,
    ),
    _SidebarItemData(Icons.qr_code_scanner, 'Escanear QR', AppRoutes.qrCode),
    _SidebarItemData(Icons.list_alt_outlined, 'Ativos', AppRoutes.exibirAtivos),
  ];

  static const List<_SidebarItemData> _itensExtras = [
    _SidebarItemData(
      Icons.info_outline,
      'Acompanhar Chamado',
      AppRoutes.statusOrdem,
    ),
    _SidebarItemData(
      Icons.map_outlined,
      'Localizar Ativo',
      AppRoutes.localizarAtivo,
    ),
    _SidebarItemData(
      Icons.settings_outlined,
      'Configurações',
      AppRoutes.configuracoes,
    ),
  ];

  void _navigate(BuildContext context, String route, String? rotaAtual) {
    if (route == rotaAtual) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final rotaAtual = ModalRoute.of(context)?.settings.name;

    final rotaNosExtras = _itensExtras.any((item) => item.route == rotaAtual);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCards,
          border: Border(
            top: BorderSide(
              color: AppColors.mainColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final larguraItem = constraints.maxWidth / 5;
            final mostrarRotulos = larguraItem >= 64;

            return Row(
              children: [
                ..._itensPrincipais.map((item) {
                  return Expanded(
                    child: _BottomBarItem(
                      item: item,
                      selecionado: item.route == rotaAtual,
                      mostrarRotulo: mostrarRotulos,
                      onTap: () => _navigate(context, item.route, rotaAtual),
                    ),
                  );
                }),

                Expanded(
                  child: PopupMenuButton<String>(
                    tooltip: 'Mais opções',
                    initialValue: null,
                    position: PopupMenuPosition.over,
                    onSelected: (route) {
                      _navigate(context, route, rotaAtual);
                    },
                    itemBuilder: (context) {
                      return _itensExtras.map((item) {
                        return PopupMenuItem<String>(
                          value: item.route,
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: item.route == rotaAtual
                                    ? AppColors.mainColor
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Flexible(child: Text(item.title)),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    child: _BottomBarMoreItem(
                      selecionado: rotaNosExtras,
                      mostrarRotulo: mostrarRotulos,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ================================================================
// ITEM DA BARRA INFERIOR
// ================================================================

class _BottomBarItem extends StatelessWidget {
  final _SidebarItemData item;
  final bool selecionado;
  final bool mostrarRotulo;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.item,
    required this.selecionado,
    required this.mostrarRotulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? AppColors.mainColor : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selecionado,
      label: item.title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 23, color: cor),
              if (mostrarRotulo) ...[
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: cor,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                width: selecionado ? 20 : 0,
                decoration: BoxDecoration(
                  color: AppColors.mainColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ITEM MAIS
// ================================================================

class _BottomBarMoreItem extends StatelessWidget {
  final bool selecionado;
  final bool mostrarRotulo;

  const _BottomBarMoreItem({
    required this.selecionado,
    required this.mostrarRotulo,
  });

  @override
  Widget build(BuildContext context) {
    final cor = selecionado ? AppColors.mainColor : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selecionado,
      label: 'Mais opções',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz, size: 23, color: cor),
            if (mostrarRotulo) ...[
              const SizedBox(height: 4),
              Text(
                'Mais',
                style: TextStyle(
                  fontSize: 10,
                  color: cor,
                  fontWeight: selecionado ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 3,
              width: selecionado ? 20 : 0,
              decoration: BoxDecoration(
                color: AppColors.mainColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DADOS DOS ITENS
// ================================================================

class _SidebarItemData {
  final IconData icon;
  final String title;
  final String route;

  const _SidebarItemData(this.icon, this.title, this.route);
}
