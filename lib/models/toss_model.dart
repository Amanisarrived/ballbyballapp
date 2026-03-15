class Toss {
  final String wonBy; // "teamA" or "teamB"
  final String decision; // "bat" or "bowl"
  final String battingFirst; // "teamA" or "teamB"

  const Toss({
    required this.wonBy,
    required this.decision,
    required this.battingFirst,
  });

  factory Toss.fromMap(Map<String, dynamic> map) {
    return Toss(
      wonBy: map['wonBy'] as String? ?? '',
      decision: map['decision'] as String? ?? '',
      battingFirst: map['battingFirst'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'wonBy': wonBy,
    'decision': decision,
    'battingFirst': battingFirst,
  };

  @override
  String toString() =>
      'Toss(wonBy: $wonBy, decision: $decision, battingFirst: $battingFirst)';
}
