import 'package:ballbyball/models/news_model.dart';
import 'package:ballbyball/service/highlisghts_api_service.dart';
import 'package:flutter/foundation.dart';

class NewsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NewsModel> _news = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetched;

  static const _cacheDuration = Duration(minutes: 15);

  List<NewsModel> get news => _news;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get _isStale {
    if (_news.isEmpty || _lastFetched == null) return true;
    return DateTime.now().difference(_lastFetched!) > _cacheDuration;
  }

  Future<void> loadNews({bool forceRefresh = false}) async {
    if (!forceRefresh && !_isStale) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final all = await _apiService.fetchNews();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _news = all.take(50).toList();
      _lastFetched = DateTime.now();
    } catch (e) {
      _errorMessage = "Unable to load news. Please try again.";
      if (kDebugMode) print("NewsProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<NewsModel> get featuredNews => _news.isNotEmpty ? [_news.first] : [];
  List<NewsModel> get remainingNews => _news.length > 1 ? _news.sublist(1) : [];

  List<NewsModel> searchNews(String query) {
    if (query.isEmpty) return _news;
    final q = query.toLowerCase();
    return _news
        .where(
          (n) =>
              n.title.toLowerCase().contains(q) ||
              n.description.toLowerCase().contains(q),
        )
        .toList();
  }
}
