import 'package:ballbyball/models/live_score_match.dart';
import 'package:ballbyball/models/player_model.dart';
import 'package:ballbyball/models/player_stats.dart';
import 'package:flutter/material.dart';

class ScoresScreen extends StatefulWidget {
  final FeaturedMatch match;
  const ScoresScreen({super.key, required this.match});

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  int _inningsTab = 0;

  FeaturedMatch get match => widget.match;

  String get battingTeamKey1st => match.toss?.battingFirst ?? 'teamA';
  String get bowlingTeamKey1st =>
      battingTeamKey1st == 'teamA' ? 'teamB' : 'teamA';
  String get battingTeamKey2nd => bowlingTeamKey1st;
  String get bowlingTeamKey2nd => battingTeamKey1st;

  String get currentBattingKey =>
      _inningsTab == 0 ? battingTeamKey1st : battingTeamKey2nd;
  String get currentBowlingKey =>
      _inningsTab == 0 ? bowlingTeamKey1st : bowlingTeamKey2nd;

  List<Player> _getBatters(String teamKey) {
    final team = teamKey == 'teamA' ? match.teamA : match.teamB;
    final striker = match.liveMatch?.striker ?? '';
    final nonStriker = match.liveMatch?.nonStriker ?? '';

    final batters = team.players.where((p) {
      final stat = match.playerStats[p.id];
      return stat != null && stat.balls > 0;
    }).toList();

    // ✅ Sort: striker first, non-striker second, out batters last
    batters.sort((a, b) {
      if (a.id == striker) return -1;
      if (b.id == striker) return 1;
      if (a.id == nonStriker) return -1;
      if (b.id == nonStriker) return 1;
      final aStat = match.playerStats[a.id];
      final bStat = match.playerStats[b.id];
      final aOut = aStat?.isOut ?? false;
      final bOut = bStat?.isOut ?? false;
      if (!aOut && bOut) return -1;
      if (aOut && !bOut) return 1;
      return 0;
    });

    return batters;
  }

  List<Player> _getBowlers(String teamKey) {
    final team = teamKey == 'teamA' ? match.teamA : match.teamB;
    final currentBowler = match.liveMatch?.currentBowler ?? '';

    final bowlers = team.players.where((p) {
      final stat = match.playerStats[p.id];
      return stat != null && (stat.overs > 0 || stat.ballsBowled > 0);
    }).toList();

    // ✅ Current bowler first
    bowlers.sort((a, b) {
      if (a.id == currentBowler) return -1;
      if (b.id == currentBowler) return 1;
      return 0;
    });

    return bowlers;
  }

  @override
  Widget build(BuildContext context) {
    final bool has2ndInnings =
        match.liveMatch != null && match.liveMatch!.innings == 2;

    // ✅ Wrap everything in SingleChildScrollView — fixes scroll issue
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // Innings toggle
            if (has2ndInnings)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _InningsToggle(
                  selected: _inningsTab,
                  team1Name:
                      (battingTeamKey1st == 'teamA' ? match.teamA : match.teamB)
                          .name,
                  team2Name:
                      (battingTeamKey2nd == 'teamA' ? match.teamA : match.teamB)
                          .name,
                  onChanged: (i) => setState(() => _inningsTab = i),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Batting ─────────────────────────────
                  _SectionHeader(title: 'BATTING'),
                  const SizedBox(height: 8),
                  _BattingTable(
                    batters: _getBatters(currentBattingKey),
                    stats: match.playerStats,
                    strikerId: match.liveMatch?.striker ?? '',
                    nonStrikerId: match.liveMatch?.nonStriker ?? '',
                  ),

                  const SizedBox(height: 24),

                  // ── Bowling ─────────────────────────────
                  _SectionHeader(title: 'BOWLING'),
                  const SizedBox(height: 8),
                  _BowlingTable(
                    bowlers: _getBowlers(currentBowlingKey),
                    stats: match.playerStats,
                    currentBowlerId: match.liveMatch?.currentBowler ?? '',
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InningsToggle extends StatelessWidget {
  final int selected;
  final String team1Name, team2Name;
  final ValueChanged<int> onChanged;

  const _InningsToggle({
    required this.selected,
    required this.team1Name,
    required this.team2Name,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          _tab(0, '1st Inn • $team1Name'),
          _tab(1, '2nd Inn • $team2Name'),
        ],
      ),
    );
  }

  Widget _tab(int index, String label) {
    final isSelected = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCC0000) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withAlpha(100),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFCC0000),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Batting Table ──────────────────────────────────────────────
class _BattingTable extends StatelessWidget {
  final List<Player> batters;
  final Map<String, PlayerStat> stats;
  final String strikerId;
  final String nonStrikerId;

  const _BattingTable({
    required this.batters,
    required this.stats,
    required this.strikerId,
    required this.nonStrikerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          _tableHeader(['BATTER', 'R', 'B', '4s', '6s', 'SR']),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          if (batters.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Match has not started',
                style: TextStyle(
                  color: Colors.white.withAlpha(60),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...batters.asMap().entries.map((e) {
              final player = e.value;
              final stat = stats[player.id] ?? const PlayerStat();
              final isStriker = player.id == strikerId;
              final isNonStriker = player.id == nonStrikerId;
              final isLast = e.key == batters.length - 1;

              return Column(
                children: [
                  _BattingRow(
                    player: player,
                    stat: stat,
                    isStriker: isStriker,
                    isNonStriker: isNonStriker,
                  ),
                  if (!isLast)
                    const Divider(color: Color(0xFF1E1E1E), height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _BattingRow extends StatelessWidget {
  final Player player;
  final PlayerStat stat;
  final bool isStriker;
  final bool isNonStriker;

  const _BattingRow({
    required this.player,
    required this.stat,
    required this.isStriker,
    required this.isNonStriker,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAtCrease = (isStriker || isNonStriker) && !stat.isOut;

    return Container(
      color: isAtCrease ? Colors.white.withAlpha(5) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // ✅ Striker = green dot, Non-striker = white dot
                    if (isStriker && !stat.isOut)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF66BB6A),
                          shape: BoxShape.circle,
                        ),
                      )
                    else if (isNonStriker && !stat.isOut)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(120),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: stat.isOut
                              ? Colors.white.withAlpha(100)
                              : isStriker
                              ? Colors.white
                              : Colors.white.withAlpha(200),
                          fontSize: 12,
                          fontWeight: isStriker
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    // ✅ Batting tag
                    if (isStriker && !stat.isOut)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF66BB6A).withAlpha(80),
                          ),
                        ),
                        child: const Text(
                          '*',
                          style: TextStyle(
                            color: Color(0xFF66BB6A),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                if (stat.dismissal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    stat.dismissal,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(55),
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _statCell(
            '${stat.runs}',
            bold: true,
            color: isStriker && !stat.isOut ? Colors.white : null,
          ),
          _statCell('${stat.balls}'),
          _statCell('${stat.fours}', color: const Color(0xFF4FC3F7)),
          _statCell('${stat.sixes}', color: const Color(0xFF66BB6A)),
          _statCell(
            stat.strikeRate.toStringAsFixed(1),
            color: stat.strikeRate >= 150
                ? const Color(0xFF66BB6A)
                : stat.strikeRate < 80
                ? Colors.red.shade300
                : null,
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, {bool bold = false, Color? color}) {
    return SizedBox(
      width: 36,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? Colors.white.withAlpha(180),
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Bowling Table ──────────────────────────────────────────────
class _BowlingTable extends StatelessWidget {
  final List<Player> bowlers;
  final Map<String, PlayerStat> stats;
  final String currentBowlerId;

  const _BowlingTable({
    required this.bowlers,
    required this.stats,
    required this.currentBowlerId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          _tableHeader(['BOWLER', 'O', 'R', 'W', 'WD', 'ECO']),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          if (bowlers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Match has not started',
                style: TextStyle(
                  color: Colors.white.withAlpha(60),
                  fontSize: 12,
                ),
              ),
            )
          else
            ...bowlers.asMap().entries.map((e) {
              final player = e.value;
              final stat = stats[player.id] ?? const PlayerStat();
              final isCurrent = player.id == currentBowlerId;
              final isLast = e.key == bowlers.length - 1;

              return Column(
                children: [
                  _BowlingRow(player: player, stat: stat, isCurrent: isCurrent),
                  if (!isLast)
                    const Divider(color: Color(0xFF1E1E1E), height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _BowlingRow extends StatelessWidget {
  final Player player;
  final PlayerStat stat;
  final bool isCurrent;

  const _BowlingRow({
    required this.player,
    required this.stat,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isCurrent ? Colors.white.withAlpha(5) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isCurrent)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFCC0000),
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha(isCurrent ? 255 : 200),
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000).withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFCC0000).withAlpha(80),
                      ),
                    ),
                    child: const Text(
                      'bowling',
                      style: TextStyle(
                        color: Color(0xFFCC0000),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _statCell('${stat.overs}.${stat.ballsBowled}'),
          _statCell('${stat.runsConceded}'),
          _statCell(
            '${stat.wickets}',
            color: stat.wickets >= 3
                ? const Color(0xFFCC0000)
                : stat.wickets > 0
                ? Colors.orange
                : null,
            bold: stat.wickets > 0,
          ),
          _statCell(
            '${stat.wides}',
            color: stat.wides > 0 ? Colors.orange.withAlpha(200) : null,
          ),
          _statCell(
            stat.economy.toStringAsFixed(1),
            color: stat.economy < 6
                ? const Color(0xFF66BB6A)
                : stat.economy > 10
                ? Colors.red.shade300
                : null,
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, {bool bold = false, Color? color}) {
    return SizedBox(
      width: 36,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? Colors.white.withAlpha(180),
          fontSize: 12,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Table Header ───────────────────────────────────────────────
Widget _tableHeader(List<String> labels) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text(labels[0], style: _headerStyle)),
        ...labels
            .skip(1)
            .map(
              (l) => SizedBox(
                width: 36,
                child: Text(
                  l,
                  textAlign: TextAlign.center,
                  style: _headerStyle,
                ),
              ),
            ),
      ],
    ),
  );
}

const _headerStyle = TextStyle(
  color: Color(0xFF666666),
  fontSize: 9,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.8,
);
