import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingFixtureModel {
  final String id;
  final String team1;
  final String team1Logo;
  final String team2;
  final String team2Logo;
  final DateTime dateTime;
  final String tournament;
  final String venue;
  final String winningTeam;
  // ── Result fields ──
  final String team1Score;
  final String team2Score;
  final String playerOfMatch;
  final String playerOfMatchPhoto;
  final String resultSummary;

  const UpcomingFixtureModel({
    required this.id,
    required this.team1,
    required this.team1Logo,
    required this.team2,
    required this.team2Logo,
    required this.dateTime,
    required this.tournament,
    required this.venue,
    required this.winningTeam,
    this.team1Score = '',
    this.team2Score = '',
    this.playerOfMatch = '',
    this.playerOfMatchPhoto = '',
    this.resultSummary = '',
  });

  factory UpcomingFixtureModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UpcomingFixtureModel(
      id: doc.id,
      team1: d['team1'] as String? ?? '',
      team1Logo: d['team1Logo'] as String? ?? '',
      team2: d['team2'] as String? ?? '',
      team2Logo: d['team2Logo'] as String? ?? '',
      dateTime: (d['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tournament: d['tournament'] as String? ?? '',
      venue: d['venue'] as String? ?? '',
      winningTeam: d['winningTeam'] as String? ?? '',
      team1Score: d['team1Score'] as String? ?? '',
      team2Score: d['team2Score'] as String? ?? '',
      playerOfMatch: d['playerOfMatch'] as String? ?? '',
      playerOfMatchPhoto: d['playerOfMatchPhoto'] as String? ?? '',
      resultSummary: d['resultSummary'] as String? ?? '',
    );
  }
}
