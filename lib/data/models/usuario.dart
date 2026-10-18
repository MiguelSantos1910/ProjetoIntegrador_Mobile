class Usuario {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String papel;

  const Usuario({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.papel,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: int.parse(map['id'].toString()),
      username: map['username']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      papel: map['papel']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'papel': papel,
    };
  }

  String get nomeCompleto => '$firstName $lastName'.trim();

  @override
  String toString() {
    return 'Usuario('
        'id: $id, '
        'username: $username, '
        'nome: $nomeCompleto, '
        'email: $email, '
        'papel: $papel'
        ')';
  }
}
