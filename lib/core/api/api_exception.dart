import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erro de uma chamada à API, com mensagem pronta para mostrar ao usuário.
///
/// [errosPorCampo] traz os erros de validação do Django REST Framework
/// (ex.: {"password": "Esta senha é muito comum."}), para exibir embaixo
/// de cada campo do formulário.
class ApiException implements Exception {
  final int? statusCode;
  final String mensagem;
  final Map<String, String> errosPorCampo;

  const ApiException(
    this.mensagem, {
    this.statusCode,
    this.errosPorCampo = const {},
  });

  /// Monta o erro a partir de uma resposta HTTP sem sucesso.
  factory ApiException.fromResponse(
    http.Response response, {
    String mensagemPadrao = 'Não foi possível concluir a operação.',
  }) {
    final erros = <String, String>{};
    String? detalhe;

    try {
      final corpo = jsonDecode(utf8.decode(response.bodyBytes));

      if (corpo is Map<String, dynamic>) {
        corpo.forEach((campo, valor) {
          final texto = valor is List && valor.isNotEmpty
              ? valor.first.toString()
              : valor?.toString();

          if (texto == null || texto.isEmpty) return;

          if (campo == 'detail' || campo == 'non_field_errors') {
            detalhe ??= texto;
          } else {
            erros[campo] = texto;
          }
        });
      }
    } catch (_) {
      // Corpo vazio ou que não é JSON: fica a mensagem padrão.
    }

    return ApiException(
      detalhe ?? mensagemPadrao,
      statusCode: response.statusCode,
      errosPorCampo: erros,
    );
  }

  /// Falha de rede (servidor fora do ar, sem internet, endereço errado).
  factory ApiException.semConexao() {
    return const ApiException(
      'Sem conexão com o servidor. Verifique a internet e tente novamente.',
    );
  }

  @override
  String toString() => mensagem;
}
