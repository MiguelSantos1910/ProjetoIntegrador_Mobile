import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:mobile_integrador/routes/routes.dart';
import 'package:mobile_integrador/presentation/widgets/shared/appColors/app_colors.dart';

class SideBar extends StatelessWidget {
  final bool aberta;
  final VoidCallback onToggle;

  const SideBar({super.key, required this.aberta, required this.onToggle});

  static const double _larguraAberta = 180;
  static const double _larguraFechada = 64;
  static const double _alturaCabecalho = 120;

  static const List<_SidebarItemData> _itens = [
    _SidebarItemData(Icons.home_outlined, 'Início', AppRoutes.home),
    _SidebarItemData(
      Icons.report_problem_outlined,
      'Abrir Chamado',
      AppRoutes.ordemServico,
    ),
    _SidebarItemData(
      Icons.qr_code_scanner,
      'Escanear QR Code',
      AppRoutes.qrCode,
    ),
    _SidebarItemData(
      Icons.list_alt_outlined,
      'Lista de Ativos',
      AppRoutes.exibirAtivos,
    ),
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

  void _navigate(BuildContext context, String route, bool jaSelecionado) {
    if (jaSelecionado) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    // A rota atual é a única fonte de verdade sobre qual item está
    // selecionado — nada de estado externo que possa ficar desincronizado
    // depois de um pushReplacementNamed, um botão "voltar" ou um deep link.
    final rotaAtual = ModalRoute.of(context)?.settings.name;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: aberta ? _larguraAberta : _larguraFechada,
      color: AppColors.backgroundCards,
      child: Column(
        children: [
          _Cabecalho(aberta: aberta, onToggle: onToggle),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _itens.length,
              itemBuilder: (context, index) {
                final item = _itens[index];
                final selecionado = item.route == rotaAtual;
                return _MenuItem(
                  icon: item.icon,
                  title: item.title,
                  selected: selecionado,
                  aberta: aberta,
                  onTap: () => _navigate(context, item.route, selecionado),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// DADOS DE UM ITEM DO MENU
// ==================================================================

class _SidebarItemData {
  final IconData icon;
  final String title;
  final String route;

  const _SidebarItemData(this.icon, this.title, this.route);
}

// ==================================================================
// CABEÇALHO
// ==================================================================

class _Cabecalho extends StatelessWidget {
  final bool aberta;
  final VoidCallback onToggle;

  const _Cabecalho({required this.aberta, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SideBar._alturaCabecalho,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: aberta ? 20 : 12, vertical: 14),
      decoration: const BoxDecoration(color: AppColors.mainColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aberta)
            SvgPicture.asset(
              'lib/assets/easy-asset-logo-verde.svg',
              height: 28,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            )
          else
            Center(
              child: SvgPicture.asset(
                'lib/assets/easy-asset-logo-verde.svg',
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onToggle,
              tooltip: aberta ? 'Fechar menu' : 'Abrir menu',
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  aberta ? Icons.menu_open : Icons.menu,
                  key: ValueKey(aberta),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// ITEM DO MENU
// ==================================================================

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool aberta;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.aberta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.mainColorLight : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.mainColor : AppColors.textSecondary,
        ),
        title: aberta
            ? Text(
                title,
                style: TextStyle(
                  color: selected
                      ? AppColors.mainColorDark
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              )
            : null,
        selected: selected,
        onTap: onTap,
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: aberta ? 12 : 13),
      ),
    );

    return aberta ? item : Tooltip(message: title, child: item);
  }
}
