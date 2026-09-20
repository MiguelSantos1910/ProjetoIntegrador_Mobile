class Laboratorio {
  final String id;
  final String nome;
  final String responsavel;
  List<String> itens;
  final DateTime dataUpdate;
  final int quantidadeItens;

  Laboratorio ({
    required this.id,
    required this.nome,
    required this.responsavel,
    required this.itens,
    required this.dataUpdate,
    required this.quantidadeItens
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'itens': itens,
      'reponsavel': responsavel,
      'dataUpdate': dataUpdate,
      'quantidadeItens': quantidadeItens
    };
  }

  factory Laboratorio.fromMap(Map<String, dynamic> map) {
    return Laboratorio(
      id: map['id'],
      nome: map['nome'],
      itens: map['itens'],
      responsavel: map['responsavel'],
      dataUpdate: map['dataUpdate'],
      quantidadeItens: map['quantidadeItens']
    );
  }

  @override
  String toString() {
    return '''Laboratorio(
      id: $id,
      nome: $nome,
      itens: $itens,
      responsavel: $responsavel,
      dataUpdate: $dataUpdate,
      quantidadeItens: $quantidadeItens
    )''';
  }
}