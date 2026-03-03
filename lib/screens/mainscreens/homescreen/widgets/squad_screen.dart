import 'package:ballbyball/models/live_score_match.dart';
import 'package:ballbyball/models/player_model.dart';
import 'package:flutter/material.dart';

class SquadsScreen extends StatelessWidget {
  final FeaturedMatch match;
  const SquadsScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final maxLen = match.teamA.players.length > match.teamB.players.length
        ? match.teamA.players.length
        : match.teamB.players.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
      child: Column(
        children: [
          // ── Team headers ─────────────────────────────
          Row(
            children: [
              Expanded(child: _TeamHeader(team: match.teamA, align: CrossAxisAlignment.start)),
              const SizedBox(width: 10),
              Expanded(child: _TeamHeader(team: match.teamB, align: CrossAxisAlignment.end)),
            ],
          ),
          const SizedBox(height: 10),

          // ── Player rows ──────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: List.generate(maxLen, (i) {
                final p1 = i < match.teamA.players.length
                    ? match.teamA.players[i] : null;
                final p2 = i < match.teamB.players.length
                    ? match.teamB.players[i] : null;
                final isLast = i == maxLen - 1;

                return Column(
                  children: [
                    _DualPlayerRow(left: p1, right: p2, index: i),
                    if (!isLast)
                      const Divider(
                          color: Color(0xFF1A1A1A), height: 1, indent: 0),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team header ───────────────────────────────────────────
class _TeamHeader extends StatelessWidget {
  final team;
  final CrossAxisAlignment align;
  const _TeamHeader({required this.team, required this.align});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),  // was 12
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${team.players.length} players',
            style: TextStyle(
              color: Colors.white.withAlpha(40),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dual player row ───────────────────────────────────────
class _DualPlayerRow extends StatelessWidget {
  final Player? left;
  final Player? right;
  final int index;
  const _DualPlayerRow({this.left, this.right, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: index.isEven
          ? const Color(0xFF0E0E0E)
          : const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Row(
        children: [
          // Left player
          Expanded(
            child: left != null
                ? _PlayerCell(player: left!, isLeft: true)
                : const SizedBox.shrink(),
          ),

          // Center index number
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.white.withAlpha(15),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Right player
          Expanded(
            child: right != null
                ? _PlayerCell(player: right!, isLeft: false)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Single player cell ────────────────────────────────────
class _PlayerCell extends StatelessWidget {
  final Player player;
  final bool isLeft;
  const _PlayerCell({required this.player, required this.isLeft});

  Color get _roleColor {
    switch (player.role.toLowerCase()) {
      case 'batsman':
      case 'batter':        return const Color(0xFF4A4A4A);
      case 'bowler':        return const Color(0xFF3E3E3E);
      case 'all-rounder':
      case 'allrounder':    return const Color(0xFF484848);
      case 'wicket-keeper':
      case 'keeper':        return const Color(0xFF424242);
      default:              return const Color(0xFF3A3A3A);
    }
  }

  String get _roleShort {
    switch (player.role.toLowerCase()) {
      case 'batsman':
      case 'batter':        return 'BAT';
      case 'bowler':        return 'BOWL';
      case 'all-rounder':
      case 'allrounder':    return 'AR';
      case 'wicket-keeper':
      case 'keeper':        return 'WK';
      default:              return player.role.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _roleColor.withAlpha(18),
        border: Border.all(color: _roleColor.withAlpha(50), width: 1),
      ),
      child: Center(
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: _roleColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    final nameCol = Expanded(
      child: Column(
        crossAxisAlignment:
        isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: _roleColor.withAlpha(15),
              borderRadius: BorderRadius.circular(6),  // was 3
            ),
            child: Text(
              _roleShort,
              style: TextStyle(
                color: _roleColor,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      mainAxisAlignment:
      isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: isLeft
          ? [avatar, const SizedBox(width: 7), nameCol]
          : [nameCol, const SizedBox(width: 7), avatar],
    );
  }
}