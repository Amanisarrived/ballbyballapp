import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppReactionService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference get _doc =>
      _db.collection('featured_match').doc('admin_current');

  // ── Stream reaction counts ───────────────────────────────
  static Stream<Map<String, int>> stream() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return _empty();
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
      return {
        'fire': reactions['fire'] as int? ?? 0,
        'shocked': reactions['shocked'] as int? ?? 0,
        'celebrate': reactions['celebrate'] as int? ?? 0,
        'heartbreak': reactions['heartbreak'] as int? ?? 0,
      };
    });
  }


  static Future<void> react(String type) async {
    await _doc.update({
      'reactions.$type': FieldValue.increment(1),
    });
  }


  static Future<bool> hasReacted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reacted_current_match') ?? false;
  }


  static Future<void> saveReaction(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reacted_current_match', true);
    await prefs.setString('reaction_type_current_match', type);
  }


  static Future<String?> getUserReaction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('reaction_type_current_match');
  }

  static Map<String, int> _empty() => {
    'fire': 0,
    'shocked': 0,
    'celebrate': 0,
    'heartbreak': 0,
  };
}