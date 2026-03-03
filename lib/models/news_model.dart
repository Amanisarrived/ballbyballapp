class NewsModel {
  final String id;
  final String title;
  final String imageUrl;
  final String description;
  final String credits;
  final String url;
  final DateTime createdAt;

  NewsModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.credits,
    required this.url,
    required this.createdAt,
  });

  // API → Model
  factory NewsModel.fromJson(
      Map<String, dynamic> json, {
        required String id,
      }) {
    return NewsModel(
      id: id,
      title: json['title'] ?? '',
      imageUrl: json['image'] ?? '',
      description: json['description'] ?? '',
      credits: json['credit'] ?? '',
      url: json['url'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(), // safety fallback
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': imageUrl,
      'description': description,
      'credit': credits,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
