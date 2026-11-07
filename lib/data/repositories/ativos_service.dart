import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/api/api_exception.dart';
import '../models/ativo.dart';

class AtivosService {
  final http.Client _client;

  AtivosService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $accessToken',
  };

  Future<List<Ativo>> buscarAtivos({required String accessToken}) async {
    final http.Response response;

    try {
      response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/ativos/'),
        headers: _headers(accessToken),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    // Com statusCode, o SessaoProvider.comToken reconhece o 401 e renova.
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível carregar os ativos.',
      );
    }

    // utf8 explícito: sem charset na resposta, o http leria os acentos errado.
    final dados = jsonDecode(utf8.decode(response.bodyBytes));

    final List<dynamic> itens;

    if (dados is List) {
      itens = dados;
    } else if (dados is Map<String, dynamic> && dados['results'] is List) {
      itens = dados['results'] as List<dynamic>;
    } else {
      throw const ApiException('Formato inesperado na resposta da API.');
    }

    return itens.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Registro de ativo inválido.');
      }

      return Ativo.fromMap(item);
    }).toList();
  }

  Future<void> atualizarAtivo({
    required int id,
    required String descricao,
    required String tipo,
    required String status,
    required String sala,
    required String accessToken,
    String? numeroPatrimonio,
  }) async {
    final http.Response response;

    try {
      response = await _client.patch(
        Uri.parse('${ApiConfig.baseUrl}/ativos/$id/'),
        headers: _headers(accessToken),
        body: jsonEncode({
          'descricao': descricao,
          'tipo': tipo,
          'status': status,
          'sala': sala,
          'numero_patrimonio': numeroPatrimonio,
        }),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível atualizar o ativo.',
      );
    }
  }

  // CONSULTAR UM ATIVO
  Future<Ativo> buscarAtivo({
    required String accessToken,
    required String id,
  }) async {
    final http.Response response;

    try {
      response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/ativos/$id/'),
        headers: _headers(accessToken),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível carregar o ativo.',
      );
    }

    return Ativo.fromMap(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // MUDAR SÓ O STATUS (ex.: EM_MANUTENCAO). O back grava o evento
  // correspondente no histórico do ativo (movimentação).
  Future<void> atualizarStatus({
    required String accessToken,
    required String id,
    required String status,
  }) async {
    final http.Response response;

    try {
      response = await _client.patch(
        Uri.parse('${ApiConfig.baseUrl}/ativos/$id/'),
        headers: _headers(accessToken),
        body: jsonEncode({'status': status}),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível atualizar o status do ativo.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
