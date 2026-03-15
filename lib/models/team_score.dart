class TeamScore {
  final int runs;
  final int wickets;
  final int overs;
  final int balls;

  const TeamScore({
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
  });

  factory TeamScore.fromMap(Map<String, dynamic> map) {
    return TeamScore(
      runs: map['runs'] as int? ?? 0,
      wickets: map['wickets'] as int? ?? 0,
      overs: map['overs'] as int? ?? 0,
      balls: map['balls'] as int? ?? 0,
    );
  }

  /// e.g. "142/4 (16.3 ov)"
  String get display => '$runs/$wickets ($overs.$balls ov)';

  Map<String, dynamic> toMap() => {
    'runs': runs,
    'wickets': wickets,
    'overs': overs,
    'balls': balls,
  };

  @override
  String toString() => 'TeamScore($display)';
}
