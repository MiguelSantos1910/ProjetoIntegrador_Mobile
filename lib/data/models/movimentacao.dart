/// Evento do histórico de um ativo (movimentação), gravado pelo back.
/// `GET /api/historico/` (somente leitura).
class Movimentacao {
  final int id;
  final int ativoId;
  final String tipoEvento;
  final String descricao;
  final String? usuarioNome;
  final DateTime? data;

  const Movimentacao({
    required this.id,
    required this.ativoId,
    required this.tipoEvento,
    required this.descricao,
    this.usuarioNome,
    this.data,
  });

  factory Movimentacao.fromMap(Map<String, dynamic> map) {
    return Movimentacao(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      ativoId: int.tryParse(map['ativo']?.toString() ?? '') ?? 0,
      tipoEvento: map['tipo_evento']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      usuarioNome: map['usuario_nome']?.toString(),
      data: DateTime.tryParse(map['data']?.toString() ?? ''),
    );
  }
}
