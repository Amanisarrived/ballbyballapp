import 'package:ballbyball/models/current_over.dart';
import 'package:ballbyball/models/live_match.dart';
import 'package:ballbyball/models/match_meta.dart';
import 'package:ballbyball/models/player_model.dart';
import 'package:ballbyball/models/player_stats.dart';
import 'package:ballbyball/models/team_model.dart';
import 'package:ballbyball/models/team_score.dart';
import 'package:ballbyball/models/toss_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FeaturedMatch {
  final MatchMeta meta;
  final Team teamA;
  final Team teamB;
  final Toss? toss;
  final LiveMatch? liveMatch;
  final Map<String, TeamScore> scores;
  final Map<String, PlayerStat> playerStats;
  final List<CurrentOver> currentOver; // ← list of balls this over

  const FeaturedMatch({
    required this.meta,
    required this.teamA,
    required this.teamB,
    required this.scores,
    required this.playerStats,
    this.toss,
    this.liveMatch,
    required this.currentOver,
  });

  // ── Convenience getters ──────────────────────────────────

  /// Score for the currently batting team
  TeamScore? get battingScore =>
      liveMatch != null ? scores[liveMatch!.battingTeam] : null;

  /// The batting Team object
  Team get battingTeam =>
      liveMatch?.battingTeam == 'teamA' ? teamA : teamB;

  /// The bowling Team object
  Team get bowlingTeam =>
      liveMatch?.bowlingTeam == 'teamA' ? teamA : teamB;

  /// Legal balls only (excludes wides & no-balls)
  int get legalBallsThisOver =>
      currentOver.where((b) => b.isLegal).length;

  /// Whether the over is complete
  bool get isOverComplete => legalBallsThisOver >= 6;

  /// Find any player across both teams by id
  Player? findPlayer(String id) {
    try {
      return [...teamA.players, ...teamB.players]
          .firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  PlayerStat statOf(String playerId) =>
      playerStats[playerId] ?? const PlayerStat();

  // ── fromDoc ──────────────────────────────────────────────
  factory FeaturedMatch.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final meta = MatchMeta.fromMap(
      Map<String, dynamic>.from(data['meta'] as Map? ?? {}),
    );

    final teamsRaw = data['teams'] as Map<String, dynamic>? ?? {};
    final teamA = Team.fromMap(
      Map<String, dynamic>.from(teamsRaw['teamA'] as Map? ?? {}),
    );
    final teamB = Team.fromMap(
      Map<String, dynamic>.from(teamsRaw['teamB'] as Map? ?? {}),
    );

    final tossRaw = data['toss'] as Map?;
    final toss = tossRaw != null
        ? Toss.fromMap(Map<String, dynamic>.from(tossRaw))
        : null;

    final liveRaw = data['liveMatch'] as Map?;
    final liveMatch = liveRaw != null
        ? LiveMatch.fromMap(Map<String, dynamic>.from(liveRaw))
        : null;

    final scoresRaw = data['scores'] as Map<String, dynamic>? ?? {};
    final scores = scoresRaw.map(
          (key, value) => MapEntry(
        key,
        TeamScore.fromMap(Map<String, dynamic>.from(value as Map? ?? {})),
      ),
    );

    final statsRaw = data['playerStats'] as Map<String, dynamic>? ?? {};
    final playerStats = statsRaw.map(
          (key, value) => MapEntry(
        key,
        PlayerStat.fromMap(Map<String, dynamic>.from(value as Map? ?? {})),
      ),
    );

    // ← parse array of balls, not a single map
    final overRaw = data['currentOver'] as List<dynamic>? ?? [];
    final currentOver = overRaw
        .map((b) => CurrentOver.fromMap(
      Map<String, dynamic>.from(b as Map? ?? {}),
    ))
        .toList();

    return FeaturedMatch(
      meta: meta,
      teamA: teamA,
      teamB: teamB,
      toss: toss,
      liveMatch: liveMatch,
      scores: scores,
      playerStats: playerStats,
      currentOver: currentOver,
    );
  }

  @override
  String toString() =>
      'FeaturedMatch(title: ${meta.title}, status: ${meta.status})';
}