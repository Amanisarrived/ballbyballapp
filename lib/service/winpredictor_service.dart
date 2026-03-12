import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WinPredictorService {
  static final _doc = FirebaseFirestore.instance
      .collection('app_data')
      .doc('current_poll');


  static Stream<DocumentSnapshot> pollStream() => _doc.snapshots();


  static Future<DocumentSnapshot> fetchPoll() => _doc.get();


  static Future<void> castVote({
    required String pollId,
    required String team,
  }) async {

    final field = team == 'team1' ? 'team1Votes' : 'team2Votes';
    await _doc.update({field: FieldValue.increment(1)});


    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voted_poll_$pollId', team);
  }


  static Future<String?> getLocalVote(String pollId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('voted_poll_$pollId');
  }
}