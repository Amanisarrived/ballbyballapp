import 'package:ballbyball/models/live_score_match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMatchService {
  LiveMatchService._();
  static final LiveMatchService instance = LiveMatchService._();

  static const _collection = 'featured_match';
  static const _docId = 'admin_current';

  FeaturedMatch? cachedMatch;

  late final _docRef = FirebaseFirestore.instance
      .collection(_collection)
      .doc(_docId);

  Stream<FeaturedMatch?> streamFeaturedMatch() {
    return _docRef.snapshots().map((doc) {
      print('📡 ${DateTime.now()} — cache: ${doc.metadata.isFromCache} — runs: ${doc.data()?['scores']?['teamA']?['runs']}');
      if (!doc.exists || doc.data() == null) return null;
      final match = FeaturedMatch.fromDoc(doc);
      cachedMatch = match;
      return match;
    });
  }
  Future<void> warmCache() async {
    try {
      final doc = await _docRef.get(const GetOptions(source: Source.cache));
      if (doc.exists && doc.data() != null) {
        cachedMatch = FeaturedMatch.fromDoc(doc);
      }
    } catch (_) {} // no cache yet, ignore
  }


  Future<FeaturedMatch?> fetchMatch() async {
    final doc = await _docRef.get();
    if (!doc.exists || doc.data() == null) return null;
    final match = FeaturedMatch.fromDoc(doc);
    cachedMatch = match; // ← cache fetch too
    return match;
  }
}