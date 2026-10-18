import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';

class UsuariosService {
  final http.Client _client;

  UsuariosService({http.Client? client}) : _client = client ?? http.Client();

  static const String _usuariosPath = '/usuarios/';
  static const String _tokenPath = '/token/';
  static const String _refreshPath = '/token/refresh/';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // LOGIN
  Future<Map<String, dynamic>> authToken(
    String username,
    String password,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$_tokenPath'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Erro ao autenticar: ${response.statusCode} ${response.body}',
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

  // CRIAR USUÁRIO
  Future<void> criarUsuario({
    required String nome,
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$_usuariosPath'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Erro ao criar usuário: '
        '${response.statusCode} ${response.body}',
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
}
