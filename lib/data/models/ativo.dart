class Ativos {
  final String id;
  final String nome;
  final String responsavel;
  final List<String> categoria;
  final String codigoPatrimonio;
  final String codigoQr;
  final int localizacao;
  final DateTime dataUtilizacao;

  const Ativos({
    required this.id,
    required this.nome,
    required this.responsavel,
    required this.categoria,
    required this.codigoPatrimonio,
    required this.codigoQr,
    required this.localizacao,
    required this.dataUtilizacao,
  });

  factory Ativos.fromMap(Map<String, dynamic> map) {
    final categoriaJson = map['categoria'];

    return Ativos(
      id: map['id'].toString(),
      nome: map['nome']?.toString() ?? '',
      responsavel: map['responsavel']?.toString() ?? '',
      categoria: categoriaJson is List
          ? categoriaJson.map((item) => item.toString()).toList()
          : categoriaJson == null
          ? <String>[]
          : <String>[categoriaJson.toString()],
      codigoPatrimonio: map['codigo_patrimonio']?.toString() ?? '',
      codigoQr: map['codigo_qr']?.toString() ?? '',
      localizacao: int.parse(map['localizacao'].toString()),
      dataUtilizacao: DateTime.parse(map['data_utilizacao'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'responsavel': responsavel,
      'categoria': categoria,
      'codigo_patrimonio': codigoPatrimonio,
      'codigo_qr': codigoQr,
      'localizacao': localizacao,
      'data_utilizacao': dataUtilizacao.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Ativos('
        'id: $id, '
        'nome: $nome, '
        'responsavel: $responsavel, '
        'categoria: $categoria, '
        'codigoPatrimonio: $codigoPatrimonio, '
        'codigoQr: $codigoQr, '
        'localizacao: $localizacao, '
        'dataUtilizacao: $dataUtilizacao'
        ')';
  }
}
