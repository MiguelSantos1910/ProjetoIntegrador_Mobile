import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';

class AtivosService {
  final http.Client _client;

  AtivosService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Authorization': 'Bearer $accessToken',
  };

  /// Busca os ativos na API Django usando o token JWT.
  Future<List<dynamic>> buscarAtivos({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/ativos/'),
      headers: _headers(accessToken),
    );

    if (response.statusCode == 200) {
      final dados = jsonDecode(response.body);

      // Resposta em lista simples.
      if (dados is List) {
        return dados;
      }

      // Resposta paginada do Django REST Framework.
      if (dados is Map<String, dynamic> && dados['results'] is List) {
        return dados['results'] as List<dynamic>;
      }

      throw Exception('Formato inesperado na resposta da API.');
    }

    throw Exception(
      'Erro ao carregar ativos: '
      '${response.statusCode} ${response.body}',
    );
  }

  /// Atualiza um ativo existente usando o token JWT.
  Future<void> atualizarAtivo({
    required int id,
    required String ativo,
    required String status,
    required String sala,
    required int localizacao,
    required String codigoQr,
    required String accessToken,
  }) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/ativos/$id/'),
      headers: _headers(accessToken),
      body: jsonEncode({
        'Ativo': ativo,
        'Status': status,
        'Sala': sala,
        'Localizacao': localizacao,
        'QR Code': codigoQr,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erro ao atualizar ativo: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Fecha o cliente HTTP quando o serviço não for mais utilizado.
  void dispose() {
    _client.close();
  }
}
