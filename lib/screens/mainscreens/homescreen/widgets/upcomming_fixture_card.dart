import 'package:ballbyball/screens/mainscreens/homescreen/widgets/upcoming_fixture_detiled_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ballbyball/models/upcoming_fixture_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class UpcomingFixtureCard extends StatelessWidget {
  final UpcomingFixtureModel fixture;

  const UpcomingFixtureCard({super.key, required this.fixture});

  bool get isCompleted => fixture.winningTeam.isNotEmpty;

  bool get isOngoing =>
      !isCompleted && DateTime.now().isAfter(fixture.dateTime);

  bool _isWinner(String teamName) {
    if (!isCompleted) return false;
    return fixture.winningTeam.toLowerCase().startsWith(teamName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final matchDate = fixture.dateTime;
    final dateLabel = DateFormat('dd MMM').format(matchDate);
    final timeLabel = DateFormat('hh:mm a').format(matchDate);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpcomingFixtureDetailScreen(fixture: fixture),
          ),
        );
      },
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(18)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(dateLabel, timeLabel),
            _buildTeams(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dateLabel, String timeLabel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border:
        Border(bottom: BorderSide(color: Colors.white.withAlpha(15))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Status chip ──────────────────────────────
          if (isCompleted)
            _StaticChip(
              label: 'ENDED',
              color: Colors.white60,
              bg: const Color(0xFF37474F),
              border: Colors.white.withAlpha(30),
            )
          else if (isOngoing)
            const _PulsingChip(
              label: 'ONGOING',
              dotColor: Color(0xFF4CAF50),
              textColor: Color(0xFF4CAF50),
              borderColor: Color(0xFF4CAF50),
              bgColor: Color(0xFF4CAF50),
            )
          else
            const _PulsingChip(
              label: 'UPCOMING',
              dotColor: Color(0xFFCC0000),
              textColor: Color(0xFFCC0000),
              borderColor: Color(0xFFCC0000),
              bgColor: Color(0xFFCC0000),
            ),

          // ── Date/time ────────────────────────────────
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 10, color: Colors.white38),
              const SizedBox(width: 3),
              Text(
                '$dateLabel • $timeLabel',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeams() {
    final team1Won = _isWinner(fixture.team1);
    final team2Won = _isWinner(fixture.team2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
              child: _teamBlock(fixture.team1, fixture.team1Logo,
                  isWinner: team1Won)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                    width: 1, height: 18, color: Colors.white.withAlpha(18)),
                const SizedBox(height: 5),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOngoing
                        ? const Color(0xFF4CAF50).withOpacity(0.08)
                        : Colors.white.withAlpha(8),
                    border: Border.all(
                        color: isOngoing
                            ? const Color(0xFF4CAF50).withOpacity(0.3)
                            : Colors.white.withAlpha(20)),
                  ),
                  child: Center(
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: isOngoing
                            ? const Color(0xFF4CAF50)
                            : Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                    width: 1, height: 18, color: Colors.white.withAlpha(18)),
              ],
            ),
          ),
          Expanded(
              child: _teamBlock(fixture.team2, fixture.team2Logo,
                  isWinner: team2Won)),
        ],
      ),
    );
  }

  Widget _teamBlock(String name, String logo, {bool isWinner = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1C1C1C),
            border: Border.all(
              color: isWinner
                  ? Colors.white.withAlpha(60)
                  : Colors.white.withAlpha(18),
              width: isWinner ? 2 : 1,
            ),
            boxShadow: isWinner
                ? [
              BoxShadow(
                  color: Colors.white.withAlpha(20),
                  blurRadius: 8,
                  spreadRadius: 1)
            ]
                : [],
          ),
          child: ClipOval(
            child: logo.isNotEmpty
                ? CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                color: const Color(0xFF1C1C1C),
                child: const Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFFCC0000)),
                  ),
                ),
              ),
              errorWidget: (_, _, _) => _logoFallback(name),
            )
                : _logoFallback(name),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWinner
                ? Colors.white.withAlpha(220)
                : Colors.white.withAlpha(80),
            fontSize: 10,
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius:
        const BorderRadius.vertical(bottom: Radius.circular(16)),
        border:
        Border(top: BorderSide(color: Colors.white.withAlpha(12))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined,
                  size: 10, color: Colors.white30),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  fixture.tournament,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          if (isCompleted) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.military_tech_rounded,
                    size: 10, color: Color(0xFF757575)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    fixture.resultSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isOngoing) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Match in progress',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _logoFallback(String name) {
    return Container(
      color: Colors.white.withAlpha(10),
      child: Center(
        child: Text(
          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name,
          style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ── Static chip (ENDED) ────────────────────────────────────────
class _StaticChip extends StatelessWidget {
  final String label;
  final Color color, bg, border;
  const _StaticChip({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Pulsing chip (UPCOMING / ONGOING) ─────────────────────────
class _PulsingChip extends StatefulWidget {
  final String label;
  final Color dotColor, textColor, borderColor, bgColor;

  const _PulsingChip({
    required this.label,
    required this.dotColor,
    required this.textColor,
    required this.borderColor,
    required this.bgColor,
  });

  @override
  State<_PulsingChip> createState() => _PulsingChipState();
}

class _PulsingChipState extends State<_PulsingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: widget.bgColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: widget.borderColor.withOpacity(_pulse.value * 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.dotColor.withOpacity(_pulse.value),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}