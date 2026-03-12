

import 'package:ballbyball/models/target.dart';

class LiveMatch {
  final int innings;
  final String battingTeam;
  final String bowlingTeam;
  final String striker;
  final String nonStriker;
  final String currentBowler;
  final Target? target;

  const LiveMatch({
    required this.innings,
    required this.battingTeam,
    required this.bowlingTeam,
    required this.striker,
    required this.nonStriker,
    required this.currentBowler,
    this.target
  });

  factory LiveMatch.fromMap(Map<String, dynamic> map) {
    return LiveMatch(
      innings: map['innings'] as int? ?? 1,
      battingTeam: map['battingTeam'] as String? ?? '',
      bowlingTeam: map['bowlingTeam'] as String? ?? '',
      striker: map['striker'] as String? ?? '',
      nonStriker: map['nonStriker'] as String? ?? '',
      currentBowler: map['currentBowler'] as String? ?? '',
      target: map['target'] != null
          ? Target.fromMap(map['target'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'innings': innings,
    'battingTeam': battingTeam,
    'bowlingTeam': bowlingTeam,
    'striker': striker,
    'nonStriker': nonStriker,
    'currentBowler': currentBowler,
    if (target != null) 'target': target!.toMap(),
  };

  @override
  String toString() =>
      'LiveMatch(innings: $innings, battingTeam: $battingTeam, striker: $striker)';
}