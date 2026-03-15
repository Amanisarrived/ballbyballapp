import 'package:cached_network_image/cached_network_image.dart';
import 'package:ballbyball/models/upcoming_fixture_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingFixtureCardScreen extends StatelessWidget {
  final UpcomingFixtureModel fixture;

  const UpcomingFixtureCardScreen({super.key, required this.fixture});

  bool get isCompleted => fixture.winningTeam.isNotEmpty;
  bool get isOngoing => !isCompleted && DateTime.now().isAfter(fixture.dateTime);

  bool _isWinner(String teamName) {
    if (!isCompleted) return false;
    return fixture.winningTeam.toLowerCase().startsWith(teamName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final matchDate = fixture.dateTime;
    final team1Won = _isWinner(fixture.team1);
    final team2Won = _isWinner(fixture.team2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128), // 0.5
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopBar(matchDate),
            _buildTeamsSection(team1Won, team2Won),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DateTime matchDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 11, color: Color(0xFF666666)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fixture.tournament,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(isCompleted: isCompleted, isOngoing: isOngoing),
        ],
      ),
    );
  }

  Widget _buildTeamsSection(bool team1Won, bool team2Won) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _TeamSide(
              name: fixture.team1,
              logo: fixture.team1Logo,
              isWinner: team1Won,
              isLoser: isCompleted && !team1Won,
              align: CrossAxisAlignment.start,
            ),
          ),
          _CenterDivider(
            dateTime: fixture.dateTime,
            isCompleted: isCompleted,
            isOngoing: isOngoing,
          ),
          Expanded(
            child: _TeamSide(
              name: fixture.team2,
              logo: fixture.team2Logo,
              isWinner: team2Won,
              isLoser: isCompleted && !team2Won,
              align: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final dateLabel = DateFormat('EEE, dd MMM • hh:mm a').format(fixture.dateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(4),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(10))),
      ),
      child: isCompleted
          ? Row(children: [
        Container(
          width: 4, height: 4,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF555555)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(fixture.resultSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 11, fontWeight: FontWeight.w500)),
        ),
      ])
          : isOngoing
          ? Row(children: [
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
        ),
        const SizedBox(width: 7),
        const Text('Match is currently ongoing',
            style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w600)),
      ])
          : Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 11, color: Color(0xFF555555)),
        const SizedBox(width: 6),
        Text(dateLabel,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  STATUS PILL
// ════════════════════════════════════════════════════════════
class _StatusPill extends StatefulWidget {
  final bool isCompleted, isOngoing;
  const _StatusPill({required this.isCompleted, required this.isOngoing});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (!widget.isCompleted) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _a(double val) => (val * 255).round().clamp(0, 255);

  @override
  Widget build(BuildContext context) {
    // ── ENDED ──
    if (widget.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: const Text('ENDED',
            style: TextStyle(color: Color(0xFF666666), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      );
    }

    // ── ONGOING ──
    if (widget.isOngoing) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withAlpha(20),   // 0.08
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4CAF50).withAlpha(_a(_pulse.value * 0.6))),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withAlpha(_a(_pulse.value)),
                ),
              ),
              const SizedBox(width: 5),
              const Text('ONGOING',
                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            ],
          ),
        ),
      );
    }

    // ── UPCOMING ──
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFCC0000).withAlpha(20),   // 0.08
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCC0000).withAlpha(_a(_pulse.value * 0.5))),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFCC0000).withAlpha(_a(_pulse.value)),
              ),
            ),
            const SizedBox(width: 5),
            const Text('UPCOMING',
                style: TextStyle(color: Color(0xFFCC0000), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  TEAM SIDE
// ════════════════════════════════════════════════════════════
class _TeamSide extends StatelessWidget {
  final String name, logo;
  final bool isWinner, isLoser;
  final CrossAxisAlignment align;

  const _TeamSide({
    required this.name,
    required this.logo,
    required this.isWinner,
    required this.isLoser,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(
                  color: isWinner ? Colors.white.withAlpha(80) : Colors.white.withAlpha(15),
                  width: isWinner ? 2 : 1,
                ),
                boxShadow: isWinner
                    ? [BoxShadow(color: Colors.white.withAlpha(15), blurRadius: 16, spreadRadius: 2)]
                    : [],
              ),
              child: ClipOval(
                child: Opacity(
                  opacity: isLoser ? 0.35 : 1.0,
                  child: logo.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: logo,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Center(
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF333333)),
                      ),
                    ),
                    errorWidget: (_, _, _) => _fallback(name),
                  )
                      : _fallback(name),
                ),
              ),
            ),
            if (isWinner)
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(30)),
                  ),
                  child: const Icon(Icons.military_tech_rounded, size: 10, color: Color(0xFFAAAAAA)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: isLoser ? Colors.white.withAlpha(45) : Colors.white.withAlpha(isWinner ? 230 : 160),
            fontSize: 12,
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _fallback(String name) {
    return Container(
      color: Colors.white.withAlpha(8),
      child: Center(
        child: Text(
          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name,
          style: const TextStyle(color: Color(0xFF555555), fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  CENTER DIVIDER
// ════════════════════════════════════════════════════════════
class _CenterDivider extends StatelessWidget {
  final DateTime dateTime;
  final bool isCompleted, isOngoing;

  const _CenterDivider({
    required this.dateTime,
    required this.isCompleted,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('hh:mm').format(dateTime);
    final amPm = DateFormat('a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Container(width: 1, height: 14, color: Colors.white.withAlpha(12)),
          const SizedBox(height: 8),
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF181818),
              border: Border.all(
                color: isOngoing
                    ? const Color(0xFF4CAF50).withAlpha(77) // 0.3
                    : Colors.white.withAlpha(15),
              ),
            ),
            child: isCompleted
                ? const Center(
              child: Text('FT',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            )
                : isOngoing
                ? const Center(
              child: Text('VS',
                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(timeLabel,
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontWeight: FontWeight.w700, height: 1)),
                Text(amPm,
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 1, height: 14, color: Colors.white.withAlpha(12)),
        ],
      ),
    );
  }
}