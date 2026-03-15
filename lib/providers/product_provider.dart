import 'dart:async';
import 'package:ballbyball/models/product_model.dart';
import 'package:flutter/foundation.dart';

class ShopProvider with ChangeNotifier {
  List<ProductModel> _all = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  String _selectedCategory = 'all';
  String _sortBy = 'newest';
  bool _trendingOnly = false;

  StreamSubscription<List<ProductModel>>? _sub;

  // ── Getters ──────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  bool get trendingOnly => _trendingOnly;

  List<ProductModel> get products {
    var list = List<ProductModel>.from(_all);

    // Category filter
    if (_selectedCategory != 'all') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }

    // Trending filter
    if (_trendingOnly) {
      list = list.where((p) => p.isTrending).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'discount':
        list.sort((a, b) => b.discount.compareTo(a.discount));
        break;
      default:
        break;
    }

    return list;
  }

  List<ProductModel> get trendingProducts =>
      _all.where((p) => p.isTrending).toList();

  void init() {
    _isLoading = true;
    notifyListeners();

    _sub = ShopService.streamAll().listen(
      (list) {
        _all = list;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load products. Please try again.';
        _isLoading = false;
        if (kDebugMode) print('ShopProvider error: $e');
        notifyListeners();
      },
    );
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    if (_sortBy == sort) return;
    _sortBy = sort;
    notifyListeners();
  }

  void toggleTrending() {
    _trendingOnly = !_trendingOnly;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'all';
    _sortBy = 'newest';
    _trendingOnly = false;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _selectedCategory != 'all' || _sortBy != 'newest' || _trendingOnly;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
