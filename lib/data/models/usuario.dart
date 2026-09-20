class Usuario {
  final String id;
  final String nome;
  final String email;
  List<String> setor;
  final String senha;

  Usuario ({
    required this.id,
    required this.nome,
    required this.email,
    required this.setor,
    required this.senha
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'setor': setor,
      'reponsavel': email,
      'senha': senha
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'],
      nome: map['nome'],
      setor: map['setor'],
      email: map['email'],
      senha: map['senha']
    );
  }

  @override
  String toString() {
    return '''Usuario(
      id: $id,
      nome: $nome,
      setor: $setor,
      email: $email,
      senha: $senha
    )''';
  }
}