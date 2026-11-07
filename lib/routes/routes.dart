import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';

import 'package:mobile_integrador/presentation/widgets/layout/main_layout.dart';
import 'package:mobile_integrador/presentation/pages/homePage/home.dart';
import 'package:mobile_integrador/presentation/pages/qrCode/qrcode_page.dart';
import 'package:mobile_integrador/presentation/pages/ativos/ativos_page.dart';
import 'package:mobile_integrador/presentation/pages/login/login_page.dart';
import 'package:mobile_integrador/presentation/pages/cadastro/cadastro_page.dart';

class AppRoutes {
  static const String login = '/';
  static const String cadastro = '/cadastro-usuario';

  static const String home = '/home';
  static const String qrCode = '/abrir-qrcode';
  static const String ordemServico = '/abrir-ordem';
  static const String ativos = '/ativos';
  static const String localizarAtivo = '/localizar-ativo';
  static const String statusOrdem = '/status';
  static const String configuracoes = '/configuracao';
  static const String sair = '/sair';

  static Route<dynamic> generatedRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );

      case cadastro:
        return MaterialPageRoute(
          builder: (_) => const CadastroPage(),
          settings: settings,
        );

      case home:
        return _rotaProtegida(settings, const HomePage());

      case ativos:
        return _rotaProtegida(settings, const AtivosPage());

      case qrCode:
        return _rotaProtegida(settings, const QrCodePage());

      // Rotas sem tela ainda (ex.: itens do menu em construção).
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _rotaProtegida(
    RouteSettings settings,
    Widget pagina,
  ) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final logado = context.read<SessaoProvider>().logado;
        return logado ? MainLayout(child: pagina) : const LoginPage();
      },
    );
  }
}
