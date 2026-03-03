import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WinPredictorService {
  static final _doc = FirebaseFirestore.instance
      .collection('app_data')
      .doc('current_poll');

  // ── Stream the poll ──────────────────────────────────────
  static Stream<DocumentSnapshot> pollStream() => _doc.snapshots();

  // ── Fetch once (used by sheet) ───────────────────────────
  static Future<DocumentSnapshot> fetchPoll() => _doc.get();

  // ── Cast vote (increments Firestore + saves locally) ─────
  static Future<void> castVote({
    required String pollId,
    required String team, // 'team1' or 'team2'
  }) async {
    // Increment the right field
    final field = team == 'team1' ? 'team1Votes' : 'team2Votes';
    await _doc.update({field: FieldValue.increment(1)});

    // Save locally so user can't vote again on this poll
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voted_poll_$pollId', team);
  }

  // ── Check local vote for this pollId ────────────────────
  static Future<String?> getLocalVote(String pollId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('voted_poll_$pollId');
  }
}