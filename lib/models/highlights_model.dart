class CategoryModel {
  final String name;
  final String thumbnail;

  CategoryModel({required this.name, required this.thumbnail});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      // id: json['id'],
      name: json['name'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      // createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'id': id,
      'name': name,
      'thumbnail': thumbnail,
      // 'created_at': createdAt.toIso8601String(),
    };
  }
}

class MovieModel {
  final int id;
  final String name;
  String url;
  final bool isTrending;
  final DateTime createdAt;
  final List<int>? categoryIds;

  MovieModel({
    required this.id,
    required this.name,
    required this.url,
    required this.isTrending,
    required this.createdAt,
    this.categoryIds,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['id'],
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      isTrending: json['is_trending'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      categoryIds: (json['categories'] as List?)
          ?.map((c) => c['id'] as int)
          .toList(), // 👈 null-safe
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'is_trending': isTrending,
      'created_at': createdAt.toIso8601String(),
      "categories": categoryIds,
    };
  }

  String? getYoutubeThumbnail() {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // handles: youtube.com/watch?v=ID
    String? videoId = uri.queryParameters['v'];

    // handles: youtu.be/ID
    if (videoId == null && uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    if (videoId == null) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
