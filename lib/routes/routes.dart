import 'package:flutter/material.dart';

import 'package:mobile_integrador/presentation/widgets/layout/main_layout.dart';
import 'package:mobile_integrador/presentation/pages/homePage/home.dart';
import 'package:mobile_integrador/presentation/pages/qrCode/qrcode_page.dart';
import 'package:mobile_integrador/presentation/pages/login/login_page.dart';

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
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case home:
        final argumentos = settings.arguments;

        if (argumentos is! Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        final accessToken = argumentos['accessToken'];
        final username = argumentos['username'];

        if (accessToken is! String ||
            accessToken.isEmpty ||
            username is! String ||
            username.trim().isEmpty) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => MainLayout(
            child: HomePage(
              accessToken: accessToken,
              username: username.trim(),
            ),
          ),
          settings: settings,
        );

      case qrCode:
        return MaterialPageRoute(
          builder: (_) => const MainLayout(child: QrCodePage()),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }
}
