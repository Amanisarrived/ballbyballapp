import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final double price;
  final double originalPrice;
  final String currency;
  final String category;
  final String source;
  final String affiliateUrl;
  final bool isTrending;
  final int discount;
  final bool inStock;
  final double rating;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.currency,
    required this.category,
    required this.source,
    required this.affiliateUrl,
    required this.isTrending,
    required this.discount,
    required this.inStock,
    required this.rating,
    required this.createdAt,
  });

  factory ProductModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id:            doc.id,
      name:          d['name'] ?? '',
      description:   d['description'] ?? '',
      image:         d['image'] ?? '',
      price:         (d['price'] ?? 0).toDouble(),
      originalPrice: (d['originalPrice'] ?? 0).toDouble(),
      currency:      d['currency'] ?? 'INR',
      category:      d['category'] ?? 'accessories',
      source:        d['source'] ?? 'amazon',
      affiliateUrl:  d['affiliateUrl'] ?? '',
      isTrending:    d['isTrending'] ?? false,
      discount:      (d['discount'] ?? 0).toInt(),
      inStock:       d['inStock'] ?? true,
      rating:        (d['rating'] ?? 0.0).toDouble(),
      createdAt:     (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ShopService {
  static final _col = FirebaseFirestore.instance.collection('products');

  static Stream<List<ProductModel>> streamAll() =>
      _col.orderBy('createdAt', descending: true).snapshots().map(
              (s) => s.docs.map(ProductModel.fromDoc).toList());

  static Stream<List<ProductModel>> streamTrending() =>
      _col.where('isTrending', isEqualTo: true).snapshots().map(
              (s) => s.docs.map(ProductModel.fromDoc).toList());

  static const List<String> categories = [
    'all', 'bat', 'ball', 'gloves', 'pads',
    'shoes', 'helmet', 'kit', 'accessories',
  ];
}