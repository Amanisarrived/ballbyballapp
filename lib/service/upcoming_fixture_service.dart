import 'package:ballbyball/models/upcoming_fixture_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpcomingFixtureService {
  UpcomingFixtureService._();                                    // ✅ singleton
  static final UpcomingFixtureService instance = UpcomingFixtureService._();

  // ✅ cached reference
  late final _collection = FirebaseFirestore.instance.collection('upcoming_fixtures');

  Stream<List<UpcomingFixtureModel>> streamUpcomingFixtures() {
    return _collection
        .orderBy('time')                                         // descending: false is default
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UpcomingFixtureModel.fromDoc(doc))
        .toList());
  }
}
