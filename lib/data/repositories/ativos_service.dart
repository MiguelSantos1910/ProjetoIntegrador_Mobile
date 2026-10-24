import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../models/ativo.dart';

class AtivosService {
  final http.Client _client;

  AtivosService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $accessToken',
  };

  Future<List<Ativo>> buscarAtivos({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/ativos/'),
      headers: _headers(accessToken),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao carregar ativos: '
        '${response.statusCode} ${response.body}',
      );
    }

    final dados = jsonDecode(response.body);

    final List<dynamic> itens;

    if (dados is List) {
      itens = dados;
    } else if (dados is Map<String, dynamic> && dados['results'] is List) {
      itens = dados['results'] as List<dynamic>;
    } else {
      throw Exception('Formato inesperado na resposta da API.');
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
    final response = await _client.patch(
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao atualizar ativo: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}
