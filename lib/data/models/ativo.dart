class Ativos {
  final String id;
  final String nome;
  final String responsavel;
  List<String> categoria;
  final String codigoPatrimonio;
  final String codigoQr;
  final int localizacao;
  final DateTime dataUtilizacao;

  Ativos ({
    required this.id,
    required this.nome,
    required this.responsavel,
    required this.categoria,
    required this.codigoPatrimonio,
    required this.codigoQr,
    required this.localizacao,
    required this.dataUtilizacao
    
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'reponsavel': responsavel,
      'codigoPatrimonio': codigoPatrimonio,
      'codigoQr': codigoQr,
      'localizacao': localizacao,
      'dataUtilizacao': dataUtilizacao
    };
  }

  factory Ativos.fromMap(Map<String, dynamic> map) {
    return Ativos(
      id: map['id'],
      nome: map['nome'],
      categoria: map['categoria'],
      responsavel: map['responsavel'],
      codigoPatrimonio: map['codigoPatrimonio'],
      codigoQr: map['codigoQr'],
      localizacao: map['localizacao'],
      dataUtilizacao: map['dataUtilizacao']
    );
  }

  @override
  String toString() {
    return '''Ativos(
      id: $id,
      nome: $nome,
      categoria: $categoria,
      responsavel: $responsavel,
      codigoPatrimonio: $codigoPatrimonio,
      codigoQr: $codigoQr,
      localizacao: $localizacao,
      dataUtilizacao: $dataUtilizacao
    )''';
  }
}