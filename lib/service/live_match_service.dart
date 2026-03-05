import 'package:ballbyball/models/live_score_match.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMatchService {
  LiveMatchService._();
  static final LiveMatchService instance = LiveMatchService._();

  static const _collection = 'featured_match';
  static const _docId      = 'admin_current';

  late final _docRef = FirebaseFirestore.instance
      .collection(_collection)
      .doc(_docId);


  FeaturedMatch? _cached;
  int?           _cachedHash;


  Stream<FeaturedMatch?> streamFeaturedMatch() {
    return _docRef
        .snapshots()
        .map(_parseSnapshotSync);
  }


  Future<FeaturedMatch?> fetchMatch() async {
    final doc = await _docRef.get();
    if (!doc.exists || doc.data() == null) return null;
    return _parseSnapshotSync(doc);
  }


  FeaturedMatch? _parseSnapshotSync(DocumentSnapshot doc) {
    if (!doc.exists || doc.data() == null) return null;

    final raw = doc.data() as Map<String, dynamic>;


    final hash = raw.hashCode;
    if (hash == _cachedHash && _cached != null) return _cached;

    final match = FeaturedMatch.fromMap(raw);

    _cached     = match;
    _cachedHash = hash;
    return match;
  }
}