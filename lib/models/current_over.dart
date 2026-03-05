class CurrentOver {
  final String type;      // 'run', 'wides', 'noBalls', 'wicket'
  final int value;        // runs scored on that ball
  final String dismissal; // only set if type == 'wicket'

  const CurrentOver({
    required this.type,
    required this.value,
    this.dismissal = '',
  });

  factory CurrentOver.fromMap(Map<String, dynamic> map) {
    return CurrentOver(
      type: map['type'] as String? ?? 'run',
      value: map['value'] as int? ?? 0,
      dismissal: map['dismissal'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CurrentOver &&
              runtimeType == other.runtimeType &&
              type == other.type &&
              value == other.value &&
              dismissal == other.dismissal;

  @override
  int get hashCode => Object.hash(type, value, dismissal);

  bool get isWicket  => type == 'wicket';
  bool get isWide    => type == 'wides';
  bool get isNoBall  => type == 'noBalls';
  bool get isLegal   => type == 'run' || type == 'wicket';
  bool get isBoundary => value == 4 || value == 6;

  String get label {
    switch (type) {
      case 'wicket':  return 'W';
      case 'wides':   return 'Wd';
      case 'noBalls': return 'Nb';
      default:        return value == 0 ? '·' : '$value';
    }
  }
}