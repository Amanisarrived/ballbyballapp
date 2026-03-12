import 'package:ballbyball/models/rank_caegory.dart';
import 'package:ballbyball/models/ranked_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class TournamentConfig {
  final String id;
  final String name;
  final String logoUrl;
  final bool isActive;
  final List<RankCategory> categories;

  const TournamentConfig({
    required this.id,
    required this.name,
    this.logoUrl  = '',
    required this.isActive,
    this.categories = const [RankCategory.batsmen, RankCategory.bowlers],
  });

  factory TournamentConfig.fromMap(Map<String, dynamic> m) {
    final rawCats = m['categories'] as List<dynamic>?;
    final cats = rawCats != null
        ? rawCats
        .map((e) {
      try {
        return RankCategory.values.firstWhere((c) => c.key == e);
      } catch (_) {
        return null;
      }
    })
        .whereType<RankCategory>()
        .toList()
        : [RankCategory.batsmen, RankCategory.bowlers];

    return TournamentConfig(
      id:         m['id']       as String? ?? '',
      name:       m['name']     as String? ?? '',
      logoUrl:    m['logoUrl']  as String? ?? '',
      isActive:   m['isActive'] as bool?   ?? false,
      categories: cats.isEmpty
          ? [RankCategory.batsmen, RankCategory.bowlers]
          : cats,
    );
  }
}



class RankingsService {
  static final _col       = FirebaseFirestore.instance.collection('rankings');
  static final _configDoc =
  FirebaseFirestore.instance.collection('config').doc('tournaments');


  static String _iccId(RankFormat f, RankCategory c) => '${f.key}_${c.key}';
  static String _tId(String tournamentId, RankCategory c) =>
      '${tournamentId}_${c.key}';


  static Stream<List<RankedPlayer>> streamRankings(
      RankFormat format, RankCategory category) {
    return _col.doc(_iccId(format, category)).snapshots().map(_parse);
  }


  static Stream<List<RankedPlayer>> streamTournamentRankings(
      String tournamentId, RankCategory category) {
    return _col.doc(_tId(tournamentId, category)).snapshots().map(_parse);
  }


  static Stream<TournamentConfig?> streamCurrentTournament() {
    return _configDoc.snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() as Map<String, dynamic>;
      final list = (data['active'] as List<dynamic>? ?? [])
          .map((e) => TournamentConfig.fromMap(e as Map<String, dynamic>))
          .toList();

      try {
        return list.firstWhere((t) => t.isActive);
      } catch (_) {
        return null;
      }
    });
  }


  static Stream<List<TournamentConfig>> streamActiveTournaments() {
    return _configDoc.snapshots().map((snap) {
      if (!snap.exists) return <TournamentConfig>[];
      final data = snap.data() as Map<String, dynamic>;
      return (data['active'] as List<dynamic>? ?? [])
          .map((e) => TournamentConfig.fromMap(e as Map<String, dynamic>))
          .where((t) => t.isActive)
          .toList();
    });
  }


  static List<RankedPlayer> _parse(DocumentSnapshot snap) {
    if (!snap.exists) return [];
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return [];
    final list = data['players'] as List<dynamic>? ?? [];
    return list
        .map((e) => RankedPlayer.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
  }
}