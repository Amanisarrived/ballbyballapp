class MatchMeta {
  final String title;
  final String status;
  final String matchTime;
  final String format;
  final String venue;
  final String matchDate;
  final String series;

  const MatchMeta({
    required this.title,
    required this.status,
    required this.matchTime,
    required this.format,
    required this.venue,
    required this.matchDate,
    required this.series,
  });

  factory MatchMeta.fromMap(Map<String, dynamic> map) {
    return MatchMeta(
      title: map['title'] as String? ?? '',
      status: map["status"] as String,
      matchTime: map['matchTime'] as String? ?? '',
      format: map['format'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      matchDate: map['matchDate'] as String? ?? '',
      series: map['series'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'title': title, 'status': status};

  @override
  String toString() => 'MatchMeta(title: $title, status: $status)';
}
