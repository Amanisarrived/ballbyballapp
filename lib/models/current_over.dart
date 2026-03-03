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


  bool get isWicket  => type == 'wicket';
  bool get isWide    => type == 'wides';
  bool get isNoBall  => type == 'noBalls';
  bool get isLegal   => type == 'run' || type == 'wicket';
  bool get isBoundary => value == 4 || value == 6;

  String get label {
    switch (type) {
      case 'wicket': return 'W';
      case 'wides':  return 'Wd';
      case 'noBalls': return 'Nb';
      default:       return value == 0 ? '·' : '$value';
    }
  }
}