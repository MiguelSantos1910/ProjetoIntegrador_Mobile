import 'package:flutter/foundation.dart';

import 'package:mobile_integrador/core/api/api_exception.dart';
import 'package:mobile_integrador/data/models/usuario.dart';
import 'package:mobile_integrador/data/repositories/usuario_service.dart';

class SessaoProvider extends ChangeNotifier {
  SessaoProvider({UsuariosService? service})
    : _service = service ?? UsuariosService();

  final UsuariosService _service;

  String? _accessToken;
  String? _refreshToken;
  Usuario? _usuario;
  bool _carregando = false;

  String? get accessToken => _accessToken;
  Usuario? get usuario => _usuario;
  bool get carregando => _carregando;
  bool get logado => _accessToken != null && _usuario != null;

  String get papel => (_usuario?.papel ?? '').toUpperCase();

  bool get podeAlterar => papel == 'PROFESSOR' || papel == 'SUPORTE';

  /// Nome e e-mail só o professor altera (regra do back, contas/views.py).
  bool get podeEditarPerfil => papel == 'PROFESSOR';

  /// Busca de novo o usuário (GET /contas/me/), ex.: depois de editar o
  /// perfil, para o nome atualizado aparecer em todo o app.
  Future<void> recarregarUsuario() async {
    final usuario = await comToken((token) => _service.buscarMe(token));
    _usuario = usuario;
    notifyListeners();
  }

  String get nomeExibicao {
    final nome = _usuario?.nomeCompleto ?? '';
    if (nome.isNotEmpty) return nome;
    return _usuario?.username ?? 'Usuário';
  }

  Future<void> login(String username, String senha) async {
    _carregando = true;
    notifyListeners();

    try {
      final tokens = await _service.authToken(username, senha);

      final access = tokens['access']?.toString();
      final refresh = tokens['refresh']?.toString();

      if (access == null || access.isEmpty) {
        throw const ApiException('Token de acesso inválido');
      }

      final usuario = await _service.buscarMe(access);

      _accessToken = access;
      _refreshToken = refresh;
      _usuario = usuario;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> renovarToken() async {
    final refresh = _refreshToken;
    if (refresh == null) return false;

    try {
      final tokens = await _service.authTokenRefresh(refresh);
      _accessToken = tokens['access']?.toString();
      _refreshToken = tokens['refresh']?.toString() ?? refresh;
      notifyListeners();
      return _accessToken != null;
    } catch (_) {
      return false;
    }
  }

  /// Executa uma chamada à API com o token da sessão. Se a API responder
  /// 401 (token vencido), renova o token e tenta de novo uma vez; se não
  /// der, encerra a sessão.
  Future<T> comToken<T>(Future<T> Function(String token) chamada) async {
    final token = _accessToken;

    if (token == null) {
      throw const ApiException(
        'Sessão encerrada. Faça login novamente.',
        statusCode: 401,
      );
    }

    try {
      return await chamada(token);
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;

      if (await renovarToken()) {
        return chamada(_accessToken!);
      }

      _limpar();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    final access = _accessToken;
    final refresh = _refreshToken;

    try {
      if (access != null && refresh != null) {
        await _service.logout(accessToken: access, refreshToken: refresh);
      }
    } catch (_) {
      // Mesmo sem resposta da API, a sessão local é encerrada.
    } finally {
      _limpar();
      notifyListeners();
    }
  }

  void _limpar() {
    _accessToken = null;
    _refreshToken = null;
    _usuario = null;
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}