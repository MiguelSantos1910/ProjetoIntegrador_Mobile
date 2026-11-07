import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/api/api_config.dart';
import '../../core/api/api_exception.dart';
import '../models/log_ordem.dart';
import '../models/ordem_manutencao.dart';

/// Ordens de manutenção (chamados): /api/ordens_manutencao/
///
/// Abrir ordem é permitido para professor e suporte; o aluno recebe 403.
class OrdensService {
  final http.Client _client;

  OrdensService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String accessToken) => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  // ABRIR ORDEM (o back grava o log "Criada" e começa como "Pendente")
  Future<OrdemManutencao> criarOrdem({
    required String accessToken,
    required String ativoId,
    required String descricao,
    required String responsavel,
    String? custoEstimado,
  }) async {
    final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/ordens_manutencao/'),
        headers: _headers(accessToken),
        body: jsonEncode({
          'ativo': int.tryParse(ativoId) ?? ativoId,
          'descricao': descricao,
          'responsavel': responsavel,
          'custo_estimado': ?custoEstimado,
        }),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode == 403) {
      throw const ApiException(
        'Somente professor e suporte técnico podem abrir chamados.',
        statusCode: 403,
      );
    }

    if (response.statusCode != 201) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível abrir o chamado.',
      );
    }

    return OrdemManutencao.fromMap(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
  }

  // Decodifica o JSON em UTF-8 (o back não envia o charset).
  dynamic _json(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes));

  Future<http.Response> _get(String caminho, String accessToken) async {
    try {
      return await _client.get(
        Uri.parse('${ApiConfig.baseUrl}$caminho'),
        headers: _headers(accessToken),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }
  }

  // LISTAR ORDENS (qualquer usuário autenticado pode consultar)
  Future<List<OrdemManutencao>> listarOrdens({
    required String accessToken,
  }) async {
    final response = await _get('/ordens_manutencao/', accessToken);

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível carregar os chamados.',
      );
    }

    final dados = _json(response);
    final itens = dados is Map<String, dynamic> && dados['results'] is List
        ? dados['results'] as List<dynamic>
        : dados as List<dynamic>;

    return itens
        .whereType<Map<String, dynamic>>()
        .map(OrdemManutencao.fromMap)
        .toList();
  }

  // CONSULTAR UMA ORDEM
  Future<OrdemManutencao> buscarOrdem({
    required String accessToken,
    required int id,
  }) async {
    final response = await _get('/ordens_manutencao/$id/', accessToken);

    if (response.statusCode == 404) {
      throw const ApiException('Chamado não encontrado.', statusCode: 404);
    }

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível carregar o chamado.',
      );
    }

    return OrdemManutencao.fromMap(_json(response) as Map<String, dynamic>);
  }

  // HISTÓRICO DA ORDEM (logs, somente leitura)
  Future<List<LogOrdem>> buscarLogs({
    required String accessToken,
    required int id,
  }) async {
    final response = await _get('/ordens_manutencao/$id/logs/', accessToken);

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível carregar o histórico do chamado.',
      );
    }

    final logs = (_json(response) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(LogOrdem.fromMap)
        .toList();

    // Mais recente primeiro.
    logs.sort(
      (a, b) => (b.data ?? DateTime(0)).compareTo(a.data ?? DateTime(0)),
    );
    return logs;
  }

  // MUDAR O STATUS (professor e suporte). O back grava o log
  // "Status alterado" e preenche a data de conclusão ao concluir.
  // Não há exclusão: para encerrar sem atender, o status é "Cancelada".
  Future<OrdemManutencao> atualizarStatus({
    required String accessToken,
    required int id,
    required String status,
  }) async {
    final http.Response response;

    try {
      response = await _client.patch(
        Uri.parse('${ApiConfig.baseUrl}/ordens_manutencao/$id/'),
        headers: _headers(accessToken),
        body: jsonEncode({'status': status}),
      );
    } catch (_) {
      throw ApiException.semConexao();
    }

    if (response.statusCode == 403) {
      throw const ApiException(
        'Somente professor e suporte técnico podem alterar chamados.',
        statusCode: 403,
      );
    }

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(
        response,
        mensagemPadrao: 'Não foi possível atualizar o chamado.',
      );
    }

    return OrdemManutencao.fromMap(_json(response) as Map<String, dynamic>);
  }

  void dispose() {
    _client.close();
  }
}
