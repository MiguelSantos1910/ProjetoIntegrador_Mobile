class Ativo {
  final String id;
  final String tipo;
  final String descricao;
  final String? numeroPatrimonio;
  final String codigoQr;
  final String sala;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? dataCadastro;
  final DateTime? atualizadoEm;

  const Ativo({
    required this.id,
    required this.tipo,
    required this.descricao,
    required this.numeroPatrimonio,
    required this.codigoQr,
    required this.sala,
    required this.status,
    this.latitude,
    this.longitude,
    this.dataCadastro,
    this.atualizadoEm,
  });

  factory Ativo.fromMap(Map<String, dynamic> map) {
    return Ativo(
      id: map['id']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      descricao: map['descricao']?.toString() ?? '',
      numeroPatrimonio: map['numero_patrimonio']?.toString(),
      codigoQr: map['codigo_qr']?.toString() ?? '',
      sala: map['sala']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      latitude: double.tryParse(map['latitude']?.toString() ?? ''),
      longitude: double.tryParse(map['longitude']?.toString() ?? ''),
      dataCadastro: DateTime.tryParse(map['data_cadastro']?.toString() ?? ''),
      atualizadoEm: DateTime.tryParse(map['atualizado_em']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo': tipo,
      'descricao': descricao,
      'numero_patrimonio': numeroPatrimonio,
      'codigo_qr': codigoQr,
      'sala': sala,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'data_cadastro': dataCadastro?.toIso8601String(),
      'atualizado_em': atualizadoEm?.toIso8601String(),
    };
  }
}
