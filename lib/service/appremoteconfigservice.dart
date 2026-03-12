import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rating_config_model.dart';



class AppRemoteConfigService {
  static final _db = FirebaseFirestore.instance;

  static DocumentReference get _doc =>
      _db.collection('app_data').doc('remoteconfig');


  static Future<Map<String, dynamic>> fetch() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) return {};
      return snap.data() as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }


  static Future<bool> shouldShowRating() async {
    try {
      final prefs = await SharedPreferences.getInstance();


      final sessions = (prefs.getInt('app_session_count') ?? 0) + 1;
      await prefs.setInt('app_session_count', sessions);


      final config = await fetch();


      final isEnabled = config['show_rating_prompt'] as bool? ?? false;
      if (!isEnabled) return false;


      final campaignId = config['rating_campaign_id'] as String? ?? '';
      if (campaignId.isEmpty) return false;


      final shownCampaign = prefs.getString('rating_shown_campaign') ?? '';
      if (shownCampaign == campaignId) return false;


      final minSessions = config['rating_min_sessions'] as int? ?? 3;
      if (sessions < minSessions) return false;

      return true;
    } catch (e) {
      return false;
    }
  }


  static Future<void> markRatingShown(String campaignId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rating_shown_campaign', campaignId);
  }

  static Future<RatingConfig> getRatingConfig() async {
    final config = await fetch();
    return RatingConfig(
      title: config['rating_title'] as String? ?? 'Enjoying BallByBall? ⭐',
      body: config['rating_body'] as String? ??
          'Rate us on Play Store!',
      buttonText:
      config['rating_button_text'] as String? ?? 'Rate Now',
      cancelText:
      config['rating_cancel_text'] as String? ?? 'Later',
      campaignId: config['rating_campaign_id'] as String? ?? '',
    );
  }
}