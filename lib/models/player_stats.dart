class PlayerStat {
  // Batting
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final String dismissal;

  // Bowling
  final int overs;
  final int ballsBowled;
  final int runsConceded;
  final int wickets;
  final int wides;
  final int noBalls;

  const PlayerStat({
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.isOut = false,
    this.dismissal = '',
    this.overs = 0,
    this.ballsBowled = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.wides = 0,
    this.noBalls = 0,
  });

  factory PlayerStat.fromMap(Map<String, dynamic> map) {
    return PlayerStat(
      runs: map['runs'] as int? ?? 0,
      balls: map['balls'] as int? ?? 0,
      fours: map['fours'] as int? ?? 0,
      sixes: map['sixes'] as int? ?? 0,
      isOut: map['isOut'] as bool? ?? false,
      dismissal: map['dismissal'] as String? ?? '',
      overs: map['overs'] as int? ?? 0,
      ballsBowled: map['ballsBowled'] as int? ?? 0,
      runsConceded: map['runsConceded'] as int? ?? 0,
      wickets: map['wickets'] as int? ?? 0,
      wides: map['wides'] as int? ?? 0,
      noBalls: map['noBalls'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlayerStat &&
              runtimeType == other.runtimeType &&
              runs == other.runs &&
              balls == other.balls &&
              fours == other.fours &&
              sixes == other.sixes &&
              isOut == other.isOut &&
              dismissal == other.dismissal &&
              overs == other.overs &&
              ballsBowled == other.ballsBowled &&
              runsConceded == other.runsConceded &&
              wickets == other.wickets &&
              wides == other.wides &&
              noBalls == other.noBalls;

  @override
  int get hashCode => Object.hash(
    runs, balls, fours, sixes, isOut, dismissal,
    overs, ballsBowled, runsConceded, wickets, wides, noBalls,
  );

  double get strikeRate => balls > 0 ? (runs / balls * 100) : 0.0;

  double get economy {
    final totalBalls = overs * 6 + ballsBowled;
    return totalBalls > 0 ? (runsConceded / totalBalls * 6) : 0.0;
  }

  String get bowlingFigures => '$wickets/$runsConceded';

  Map<String, dynamic> toMap() => {
    'runs': runs,
    'balls': balls,
    'fours': fours,
    'sixes': sixes,
    'isOut': isOut,
    'dismissal': dismissal,
    'overs': overs,
    'ballsBowled': ballsBowled,
    'runsConceded': runsConceded,
    'wickets': wickets,
    'wides': wides,
    'noBalls': noBalls,
  };

  @override
  String toString() =>
      'PlayerStat(runs: $runs($balls), wickets: $wickets/$runsConceded)';
}