import 'package:ballbyball/models/player_model.dart';


class Team {
  final String teamId;
  final String name;
  final String logo;
  final List<Player> players;

  const Team({
    required this.teamId,
    required this.name,
    required this.logo,
    required this.players,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    final rawPlayers = map['players'] as List<dynamic>? ?? [];
    return Team(
      teamId: map['teamId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      logo: map['logo'] as String? ?? '',
      players: rawPlayers
          .map((p) => Player.fromMap(Map<String, dynamic>.from(p as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'teamId': teamId,
    'name': name,
    'logo': logo,
    'players': players.map((p) => p.toMap()).toList(),
  };

  @override
  String toString() => 'Team(teamId: $teamId, name: $name, players: ${players.length})';
}