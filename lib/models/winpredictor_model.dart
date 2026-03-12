import 'package:cloud_firestore/cloud_firestore.dart';

// ── Model ─────────────────────────────────────────────────
class CurrentPoll {
  final String pollId;
  final bool showPoll;
  final bool showVotes;
  final String team1;
  final String team1Color;
  final String team1Logo;
  final int team1Votes;
  final String team2;
  final String team2Color;
  final String team2Logo;
  final int team2Votes;

  const CurrentPoll({
    required this.pollId,
    required this.showPoll,
    required this.showVotes,
    required this.team1,
    required this.team1Color,
    required this.team1Logo,
    required this.team1Votes,
    required this.team2,
    required this.team2Color,
    required this.team2Logo,
    required this.team2Votes,
  });

  factory CurrentPoll.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CurrentPoll(
      pollId:      d['pollId']      as String? ?? '',
      showPoll:    d['showPoll']    as bool?   ?? false,
      showVotes:   d['showVotes']   as bool?   ?? false,
      team1:       d['team1']       as String? ?? '',
      team1Color:  d['team1Color']  as String? ?? '#CC0000',
      team1Logo:   d['team1Logo']   as String? ?? '',
      team1Votes:  (d['team1Votes'] as num?)?.toInt() ?? 0,
      team2:       d['team2']       as String? ?? '',
      team2Color:  d['team2Color']  as String? ?? '#1A73E8',
      team2Logo:   d['team2Logo']   as String? ?? '',
      team2Votes:  (d['team2Votes'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalVotes => team1Votes + team2Votes;

  double get team1Percent =>
      totalVotes == 0 ? 50.0 : (team1Votes / totalVotes * 100);

  double get team2Percent =>
      totalVotes == 0 ? 50.0 : (team2Votes / totalVotes * 100);
}
