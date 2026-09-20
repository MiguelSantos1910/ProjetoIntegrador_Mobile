import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/sideBar/sidebar.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool sidebarAberta = true;

  void handleSidebar() {
    setState(() {
      sidebarAberta = !sidebarAberta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Não precisa mais receber/guardar qual item está selecionado:
          // a própria SideBar descobre isso olhando a rota atual, então o
          // destaque nunca fica desincronizado — mesmo quando o MainLayout
          // é recriado do zero a cada pushReplacementNamed.
          SideBar(aberta: sidebarAberta, onToggle: handleSidebar),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
