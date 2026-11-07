import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_integrador/presentation/providers/sessao_provider.dart';

import 'package:mobile_integrador/presentation/widgets/layout/main_layout.dart';
import 'package:mobile_integrador/presentation/pages/homePage/home.dart';
import 'package:mobile_integrador/presentation/pages/qrCode/qrcode_page.dart';
import 'package:mobile_integrador/presentation/pages/ativos/ativos_page.dart';
import 'package:mobile_integrador/presentation/pages/login/login_page.dart';
import 'package:mobile_integrador/presentation/pages/cadastro/cadastro_page.dart';
import 'package:mobile_integrador/presentation/pages/ordemServico/ordem_servico_page.dart';
import 'package:mobile_integrador/presentation/pages/ordemServico/detalhe_chamado_page.dart';
import 'package:mobile_integrador/presentation/pages/statusOrdem/chamados_page.dart';
import 'package:mobile_integrador/presentation/pages/configuracoes/configuracoes_page.dart';
import 'package:mobile_integrador/presentation/pages/localizador/localizar_page.dart';

class AppRoutes {
  static const String login = '/';
  static const String cadastro = '/cadastro-usuario';

  static const String home = '/home';
  static const String qrCode = '/abrir-qrcode';
  static const String ordemServico = '/abrir-ordem';
  static const String ativos = '/ativos';
  static const String localizarAtivo = '/localizar-ativo';
  static const String statusOrdem = '/status';
  static const String detalheChamado = '/chamado';
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

      // Argumento opcional: id do ativo já selecionado.
      case ordemServico:
        final ativoId = settings.arguments;
        return _rotaProtegida(
          settings,
          OrdemServicoPage(ativoIdInicial: ativoId is String ? ativoId : null),
        );

      case statusOrdem:
        return _rotaProtegida(settings, const ChamadosPage());

      case configuracoes:
        return _rotaProtegida(settings, const ConfiguracoesPage());

      case localizarAtivo:
        return _rotaProtegida(settings, const LocalizarPage());

      // Argumento obrigatório: id da ordem. Tela de segundo nível, sem menu.
      case detalheChamado:
        final ordemId = settings.arguments;
        if (ordemId is! int) {
          return _rotaProtegida(settings, const ChamadosPage());
        }
        return _rotaProtegida(
          settings,
          DetalheChamadoPage(ordemId: ordemId),
          comMenu: false,
        );

      // Rotas sem tela ainda (ex.: itens do menu em construção).
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
    }
  }

  /// Só abre a página se houver sessão; senão, mostra o login.
  /// [comMenu] coloca a barra de navegação inferior (MainLayout).
  static MaterialPageRoute<dynamic> _rotaProtegida(
    RouteSettings settings,
    Widget pagina, {
    bool comMenu = true,
  }) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) {
        final logado = context.read<SessaoProvider>().logado;
        if (!logado) return const LoginPage();
        return comMenu ? MainLayout(child: pagina) : pagina;
      },
    );
  }
}
