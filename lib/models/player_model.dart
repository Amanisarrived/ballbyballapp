class Player {
  final String id;
  final String name;
  final String role;

  const Player({
    required this.id,
    required this.name,
    required this.role,
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'role': role,
  };

  @override
  String toString() => 'Player(id: $id, name: $name, role: $role)';
}