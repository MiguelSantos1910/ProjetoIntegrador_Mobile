/// Ordem de manutenção (chamado), espelhando o OrdemManutencao do back.
class OrdemManutencao {
  final int id;
  final int ativoId;
  final String descricao;
  final String responsavel;
  final String status;
  final String? custoEstimado;
  final DateTime? dataAbertura;
  final DateTime? dataConclusao;

  const OrdemManutencao({
    required this.id,
    required this.ativoId,
    required this.descricao,
    required this.responsavel,
    required this.status,
    this.custoEstimado,
    this.dataAbertura,
    this.dataConclusao,
  });

  factory OrdemManutencao.fromMap(Map<String, dynamic> map) {
    return OrdemManutencao(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      ativoId: int.tryParse(map['ativo']?.toString() ?? '') ?? 0,
      descricao: map['descricao']?.toString() ?? '',
      responsavel: map['responsavel']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      custoEstimado: map['custo_estimado']?.toString(),
      dataAbertura: DateTime.tryParse(map['data_abertura']?.toString() ?? ''),
      dataConclusao: DateTime.tryParse(
        map['data_conclusao']?.toString() ?? '',
      ),
    );
  }
}
