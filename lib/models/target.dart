class Target {
  final int ballsRemaining;
  final int ballsUsed;
  final int runs;
  final int runsNeeded;
  final int totalBalls;

  const Target({
    required this.ballsRemaining,
    required this.ballsUsed,
    required this.runs,
    required this.runsNeeded,
    required this.totalBalls,
  });

  factory Target.fromMap(Map<String, dynamic> map) {
    return Target(
      ballsRemaining: map['ballsRemaining'] as int? ?? 0,
      ballsUsed: map['ballsUsed'] as int? ?? 0,
      runs: map['runs'] as int? ?? 0,
      runsNeeded: map['runsNeeded'] as int? ?? 0,
      totalBalls: map['totalBalls'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'ballsRemaining': ballsRemaining,
    'ballsUsed': ballsUsed,
    'runs': runs,
    'runsNeeded': runsNeeded,
    'totalBalls': totalBalls,
  };

  @override
  String toString() =>
      'Target(runs: $runs, runsNeeded: $runsNeeded, ballsRemaining: $ballsRemaining)';
}