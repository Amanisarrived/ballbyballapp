enum RankFormat { t20, odi, test }

enum RankCategory { batsmen, bowlers, allrounders }

extension RankFormatExt on RankFormat {
  String get key {
    switch (this) {
      case RankFormat.t20:  return 't20';
      case RankFormat.odi:  return 'odi';
      case RankFormat.test: return 'test';
    }
  }
  String get label {
    switch (this) {
      case RankFormat.t20:  return 'T20';
      case RankFormat.odi:  return 'ODI';
      case RankFormat.test: return 'Test';
    }
  }
}

extension RankCategoryExt on RankCategory {
  String get key {
    switch (this) {
      case RankCategory.batsmen:     return 'batsmen';
      case RankCategory.bowlers:     return 'bowlers';
      case RankCategory.allrounders: return 'allrounders';
    }
  }
  String get label {
    switch (this) {
      case RankCategory.batsmen:     return 'Batsmen';
      case RankCategory.bowlers:     return 'Bowlers';
      case RankCategory.allrounders: return 'All-rounders';
    }
  }
}