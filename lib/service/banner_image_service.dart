import 'package:cloud_firestore/cloud_firestore.dart';

class BannerService {
  BannerService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collection = 'app_data';
  static const String _document = 'bannerImages';
  static const String _field = 'url';


  static Future<List<String>> fetchBanners() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_document).get();

      if (!doc.exists || doc.data() == null) {
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;

      return List<String>.from(data[_field] ?? []);
    } catch (e) {
      return [];
    }
  }   


  static Stream<List<String>> streamBanners() {
    return _firestore.collection(_collection).doc(_document).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) {
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data[_field] ?? []);
    });
  }
}
