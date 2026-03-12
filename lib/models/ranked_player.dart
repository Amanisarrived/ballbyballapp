class RankedPlayer {
  final int rank;
  final String name;
  final String imageUrl;
  final String flagUrl;   // country flag image URL
  final int runs;         // batsmen
  final int wickets;      // bowlers

  // kept for backward compat with existing Firestore docs
  final String team;
  final String teamFlag;
  final int rating;
  final int points;

  const RankedPlayer({
    required this.rank,
    required this.name,
    this.imageUrl = '',
    this.flagUrl  = '',
    this.runs     = 0,
    this.wickets  = 0,
    this.team     = '',
    this.teamFlag = '',
    this.rating   = 0,
    this.points   = 0,
  });

  factory RankedPlayer.fromMap(Map<String, dynamic> m) {
    return RankedPlayer(
      rank:     (m['rank']     as num?)?.toInt() ?? 0,
      name:      m['name']     as String? ?? '',
      imageUrl:  m['imageUrl'] as String? ?? '',
      flagUrl:   m['flagUrl']  as String? ?? '',
      runs:     (m['runs']     as num?)?.toInt() ?? 0,
      wickets:  (m['wickets']  as num?)?.toInt() ?? 0,
      team:      m['team']     as String? ?? '',
      teamFlag:  m['teamFlag'] as String? ?? '',
      rating:   (m['rating']   as num?)?.toInt() ?? 0,
      points:   (m['points']   as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'rank':     rank,
    'name':     name,
    'imageUrl': imageUrl,
    'flagUrl':  flagUrl,
    'runs':     runs,
    'wickets':  wickets,
    'team':     team,
    'teamFlag': teamFlag,
    'rating':   rating,
    'points':   points,
  };

  RankedPlayer copyWith({
    int? rank, String? name, String? imageUrl, String? flagUrl,
    int? runs, int? wickets,
    String? team, String? teamFlag, int? rating, int? points,
  }) => RankedPlayer(
    rank:     rank     ?? this.rank,
    name:     name     ?? this.name,
    imageUrl: imageUrl ?? this.imageUrl,
    flagUrl:  flagUrl  ?? this.flagUrl,
    runs:     runs     ?? this.runs,
    wickets:  wickets  ?? this.wickets,
    team:     team     ?? this.team,
    teamFlag: teamFlag ?? this.teamFlag,
    rating:   rating   ?? this.rating,
    points:   points   ?? this.points,
  );
}