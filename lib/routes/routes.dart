import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/layout/main_layout.dart';
import 'package:mobile_integrador/presentation/pages/homePage/home.dart';
import 'package:mobile_integrador/presentation/pages/qrCode/qrcode_page.dart';

class AppRoutes {
  static const String login = '/';
  static const String cadastro = '/cadastro-usuario';

  static const String home = '/home';
  static const String qrCode = '/abrir-qrcode';

  static const String ordemServico = '/abrir-ordem';
  static const String exibirAtivos = '/ativos';
  static const String localizarAtivo = '/localizar-ativo';
  static const String statusOrdem = '/status';
  static const String configuracoes = '/configuracao';

  static Route<dynamic> generatedRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainLayout(child: HomePage()),
          settings: settings,
        );

      case qrCode:
        return MaterialPageRoute(
          builder: (_) => const MainLayout(child: QrCodePage()),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const MainLayout(child: HomePage()),
          settings: settings,
        );
    }
  }
}
