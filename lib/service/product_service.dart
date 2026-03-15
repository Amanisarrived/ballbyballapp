import 'package:ballbyball/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopService {
  static final _col = FirebaseFirestore.instance.collection('products');

  static Stream<List<ProductModel>> streamAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  static Stream<List<ProductModel>> streamTrending() => _col
      .where('isTrending', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(ProductModel.fromDoc).toList());

  static const List<String> categories = [
    'all',
    'bat',
    'ball',
    'gloves',
    'pads',
    'shoes',
    'helmet',
    'kit',
    'accessories',
  ];
}
