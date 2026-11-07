import 'dart:convert';

import 'package:http/http.dart' as http;
import '../models/usuario.dart';
import '../../core/api/api_config.dart';
import '../../core/api/api_exception.dart';

class UsuariosService {
  final http.Client _client;

  UsuariosService({http.Client? client}) : _client = client ?? http.Client();

  static const String _usuariosPath = '/contas/usuarios/';
  static const String _tokenPath = '/token/';
  static const String _refreshPath = '/token/refresh/';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // LOGIN
  // Erros viram ApiException com mensagem pronta para a tela:
  // 401 = usuário ou senha errados; 429 = bloqueio por tentativas.
  Future<Map<String, dynamic>> authToken(
    String username,
    String password,
  ) async {
    final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}$_tokenPath'),
        headers: _headers,
        body: jsonEncode({'username': username, 'password': password}),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      throw const ApiException('Usuário ou senha inválidos.', statusCode: 401);
    }

    if (response.statusCode == 429) {
      // O back explica o bloqueio e o tempo de espera no "detail".
      throw ApiException.fromResponse(
        response,
        mensagemPadrao:
            'Muitas tentativas de login. Aguarde alguns minutos e tente novamente.',
      );
    }

    throw ApiException.fromResponse(
      response,
      mensagemPadrao: 'Não foi possível entrar. Tente novamente.',
    );
  }

  // RENOVAÇÃO DO TOKEN
  Future<Map<String, dynamic>> authTokenRefresh(String refreshToken) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$_refreshPath'),
      headers: _headers,
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Erro ao renovar token: ${response.statusCode} ${response.body}',
    );
  }

  // LISTAR USUÁRIOS
  Future<List<dynamic>> buscarUsuarios({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$_usuariosPath'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final dados = jsonDecode(response.body);

      if (dados is List) {
        return dados;
      }

      if (dados is Map<String, dynamic> && dados['results'] is List) {
        return dados['results'] as List<dynamic>;
      }

      throw Exception('Formato inesperado na resposta da API.');
    }

    throw Exception(
      'Erro ao carregar usuários: '
      '${response.statusCode} ${response.body}',
    );
  }

  // CRIAR USUÁRIO (cadastro público: o back sempre cria como ALUNO)
  // POST /api/contas/usuarios/ com os campos do UsuarioCreateSerializer.
  // Em erro 400, a ApiException traz os erros de cada campo.
  Future<void> criarUsuario({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}$_usuariosPath'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        }),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível criar a conta. Revise os dados.',
      );
    }
  }

  // ATUALIZAR USUÁRIO
  Future<void> atualizarUsuario({
    required int id,
    required String nome,
    required String username,
    required String email,
    required String accessToken,
    String? password,
  }) async {
    final dados = <String, dynamic>{
      'nome': nome,
      'username': username,
      'email': email,
    };

    if (password != null && password.isNotEmpty) {
      dados['password'] = password;
    }

    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}$_usuariosPath$id/'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode(dados),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao atualizar usuário: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  // DELETAR USUÁRIO
  Future<void> deletarUsuario({
    required int id,
    required String accessToken,
  }) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}$_usuariosPath$id/'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Erro ao deletar usuário: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }

  Future<Usuario> buscarMe(String accessToken) async {
    final http.Response response;

    try {
      response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/contas/me/'),
        headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível buscar os dados do usuário.',
      );
    }

    final dados = jsonDecode(utf8.decode(response.bodyBytes));
    return Usuario.fromMap(dados as Map<String, dynamic>);
  }

  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/contas/logout/'),
      headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'refresh': refreshToken}),
    );
  }
}
