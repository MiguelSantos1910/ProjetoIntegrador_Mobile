/// Registro do histórico de uma ordem de manutenção (somente leitura).
/// `GET /api/ordens_manutencao/<id>/logs/`
class LogOrdem {
  final int id;
  final String acao;
  final String descricao;
  final String statusAnterior;
  final String statusNovo;
  final DateTime? data;

  const LogOrdem({
    required this.id,
    required this.acao,
    required this.descricao,
    required this.statusAnterior,
    required this.statusNovo,
    this.data,
  });

  factory LogOrdem.fromMap(Map<String, dynamic> map) {
    return LogOrdem(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      acao: map['acao']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      statusAnterior: map['status_anterior']?.toString() ?? '',
      statusNovo: map['status_novo']?.toString() ?? '',
      data: DateTime.tryParse(map['data']?.toString() ?? ''),
    );
  }
}
