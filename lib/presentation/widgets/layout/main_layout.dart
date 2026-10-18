import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/shared/sideBar/sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child, bottomNavigationBar: const SideBar());
  }
}
