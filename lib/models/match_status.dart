enum MatchStatus { upcoming, live, completed, unknown }

extension MatchStatusX on MatchStatus {
  String get value {
    switch (this) {
      case MatchStatus.upcoming:
        return 'upcoming';
      case MatchStatus.live:
        return 'live';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.unknown:
        return '';
    }
  }

  static MatchStatus fromString(String? value) {
    switch (value) {
      case 'upcoming':
        return MatchStatus.upcoming;
      case 'live':
        return MatchStatus.live;
      case 'completed':
        return MatchStatus.completed;
      default:
        return MatchStatus.unknown;
    }
  }
}