import 'dart:async';
import 'dart:math';
import 'package:ballbyball/models/live_score_match.dart';
import 'package:ballbyball/models/target.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/score_card_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class LiveMatchCard extends StatefulWidget {
  final FeaturedMatch match;

  const LiveMatchCard({super.key, required this.match});

  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _countdownTimer;
  Duration? _remaining;
  bool _isPressed = false;

  FeaturedMatch get match => widget.match;

  String get team1Name => match.teamA.name;
  String get team2Name => match.teamB.name;
  String get team1Logo => match.teamA.logo;
  String get team2Logo => match.teamB.logo;
  String get matchStatus => match.meta.status;
  String get series => match.meta.series;
  String get format => match.meta.format;
  String get venue => match.meta.venue;
  String get matchDate => match.meta.matchDate;
  String get matchTime => match.meta.matchTime;
  String get normalizedStatus => matchStatus.toLowerCase().trim();

  int get team1Runs => match.scores['teamA']?.runs ?? 0;
  int get team1Wickets => min(match.scores['teamA']?.wickets ?? 0, 10);
  int get team1Overs => match.scores['teamA']?.overs ?? 0;
  int get team1Balls => match.scores['teamA']?.balls ?? 0;
  int get team2Runs => match.scores['teamB']?.runs ?? 0;
  int get team2Wickets => min(match.scores['teamB']?.wickets ?? 0, 10);
  int get team2Overs => match.scores['teamB']?.overs ?? 0;
  int get team2Balls => match.scores['teamB']?.balls ?? 0;

  String get team1OversDisplay => '$team1Overs.$team1Balls ov';
  String get team2OversDisplay => '$team2Overs.$team2Balls ov';

  int get innings => match.liveMatch?.innings ?? 1;
  String get battingTeamKey => match.liveMatch?.battingTeam ?? '';
  Target? get target => match.liveMatch?.target;

  bool get team1Leading => team1Runs > team2Runs;
  bool get scoresEqual => team1Runs == team2Runs;
  bool get isLive => normalizedStatus == 'live';
  bool get isUpcoming => normalizedStatus == 'upcoming';

  // Toss — only show in 1st innings
  String get tossDisplay {
    if (innings == 2) return '';
    final toss = match.toss;
    if (toss == null || toss.wonBy.isEmpty || toss.decision.isEmpty) return '';
    final wonTeam = toss.wonBy == 'teamA' ? match.teamA : match.teamB;
    return '${wonTeam.name} won the toss & elected to ${toss.decision}';
  }

  String _runRate(String teamKey) {
    final score = match.scores[teamKey];
    if (score == null) return '0.00';
    final totalBalls = (score.overs * 6) + score.balls;
    if (totalBalls == 0) return '0.00';
    return (score.runs / totalBalls * 6).toStringAsFixed(2);
  }

  String _calculateRequiredRR(int runsNeeded, int ballsRemaining) {
    if (ballsRemaining == 0) return '0.00';
    return (runsNeeded / ballsRemaining * 6).toStringAsFixed(2);
  }

  DateTime? _parseMatchTime() {
    if (matchDate.isEmpty || matchTime.isEmpty) return null;
    try {
      return DateTime.parse('$matchDate $matchTime');
    } catch (_) {
      return null;
    }
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative || d == Duration.zero) return 'Starting soon';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (days >= 1) return '${days}d ${hours}h ${minutes}m';
    if (hours >= 1) return '${hours}h ${minutes}m ${seconds}s';
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final t = _parseMatchTime();
    if (t == null) return;
    void tick() {
      final diff = t.difference(DateTime.now());
      if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
      if (diff.isNegative) _countdownTimer?.cancel();
    }
    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    if (isUpcoming) _startCountdown();
  }

  @override
  void didUpdateWidget(LiveMatchCard old) {
    super.didUpdateWidget(old);
    if (old.match.meta.matchTime != matchTime) _startCountdown();
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, _, _) => const ScoreCardScreen(),
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
            barrierColor: Colors.black,
            opaque: true,
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.972 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF161616),
            border: Border.all(color: Colors.white.withAlpha(20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4)),
              if (isLive)
                BoxShadow(color: const Color(0xFFCC0000).withAlpha(25), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildScoreBody(),
              if (target != null && innings == 2) _buildTargetSection(),
              if (tossDisplay.isNotEmpty) _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.white.withAlpha(18))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusChip(),
              const SizedBox(width: 6),
              if (format.isNotEmpty) _formatChip(),
              const Spacer(),
              _buildTimeWidget(),
            ],
          ),
          if (series.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(series, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          if (venue.isNotEmpty) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 10, color: Colors.white30),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(venue, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeWidget() {
    if (matchDate.isEmpty || matchTime.isEmpty) return const SizedBox.shrink();
    final parsedTarget = _parseMatchTime();
    if (parsedTarget == null) return const SizedBox.shrink();
    final diff = parsedTarget.difference(DateTime.now());

    if (!diff.isNegative) {
      if (_remaining == null) { _startCountdown(); return const SizedBox.shrink(); }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.withAlpha(64)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 10, color: Colors.orange),
            const SizedBox(width: 3),
            Text(_formatCountdown(_remaining!),
                style: const TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time_rounded, size: 10, color: Colors.white38),
        const SizedBox(width: 3),
        Text('${matchDate.split('-').reversed.join('-')} • $matchTime',
            style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildScoreBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _teamColumn(
              teamKey: 'teamA', name: team1Name, logo: team1Logo,
              runs: team1Runs, wickets: team1Wickets, oversDisplay: team1OversDisplay,
              rr: _runRate('teamA'), isLeading: team1Leading && !scoresEqual,
              isBatting: battingTeamKey == 'teamA',
            ),
          ),
          _vsColumn(),
          Expanded(
            child: _teamColumn(
              teamKey: 'teamB', name: team2Name, logo: team2Logo,
              runs: team2Runs, wickets: team2Wickets, oversDisplay: team2OversDisplay,
              rr: _runRate('teamB'), isLeading: !team1Leading && !scoresEqual,
              isBatting: battingTeamKey == 'teamB',
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamColumn({
    required String teamKey, required String name, required String logo,
    required int runs, required int wickets, required String oversDisplay,
    required String rr, required bool isLeading, required bool isBatting,
  }) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C1C),
                border: Border.all(
                  color: isLeading ? const Color(0xFFCC0000).withAlpha(140) : Colors.white.withAlpha(18),
                  width: isLeading ? 2 : 1,
                ),
                boxShadow: isLeading
                    ? [BoxShadow(color: const Color(0xFFCC0000).withAlpha(46), blurRadius: 12, spreadRadius: 1)]
                    : [],
              ),
              child: ClipOval(
                child: logo.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: logo, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF1C1C1C),
                    child: const Center(child: SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFCC0000)))),
                  ),
                  errorWidget: (context, url, error) => _logoFallback(name),
                )
                    : _logoFallback(name),
              ),
            ),
            if (isBatting && isLive)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF161616), width: 2),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 7),

        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            style: TextStyle(
              color: isLeading ? Colors.white.withAlpha(220) : Colors.white.withAlpha(128),
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4,
            )),

        const SizedBox(height: 7),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$runs',
                style: TextStyle(
                  color: isLeading ? Colors.white : Colors.white.withAlpha(166),
                  fontSize: 26, fontWeight: FontWeight.w900, height: 1, letterSpacing: -1,
                )),
            Text('/$wickets',
                style: TextStyle(
                  color: Colors.white.withAlpha(isLeading ? 102 : 64),
                  fontSize: 14, fontWeight: FontWeight.w600, height: 1,
                )),
          ],
        ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.withAlpha(10), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(oversDisplay,
                  style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 9, fontWeight: FontWeight.w600)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(width: 1, height: 8, color: Colors.white.withAlpha(30)),
              ),
              Text('RR $rr',
                  style: TextStyle(
                    color: isLeading ? const Color(0xFFCC0000).withAlpha(217) : Colors.white.withAlpha(89),
                    fontSize: 9, fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vsColumn() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 1, height: 22, color: Colors.white.withAlpha(18)),
          const SizedBox(height: 6),
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(10),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: const Center(
              child: Text('VS',
                  style: TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 1, height: 22, color: Colors.white.withAlpha(18)),
        ],
      ),
    );
  }

  Widget _buildTargetSection() {
    if (target == null) return const SizedBox.shrink();
    final t = target!;
    final runsNeeded = t.runsNeeded;
    final ballsRemaining = t.ballsRemaining;

    final battingWickets = battingTeamKey == 'teamA' ? team1Wickets : team2Wickets;
    final wicketsLeft = 10 - battingWickets;
    final bowlingTeamName = battingTeamKey == 'teamA' ? team2Name : team1Name;
    final battingTeamName = battingTeamKey == 'teamA' ? team1Name : team2Name;

    final chasingTeamWon = runsNeeded <= 0;
    final allOut = battingWickets >= 10 && runsNeeded > 0;
    final runsByWhichWon = runsNeeded - 1;

    // Colors
    final Color urgency = (chasingTeamWon || allOut)
        ? const Color(0xFF66BB6A)
        : ballsRemaining < 12
        ? const Color(0xFFFF5252)
        : ballsRemaining < 36
        ? const Color(0xFFFFB300)
        : const Color(0xFF4FC3F7);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: urgency.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: urgency.withAlpha(55)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // icon
          Icon(
            chasingTeamWon || allOut ? Icons.emoji_events_rounded : Icons.flag_outlined,
            size: 13,
            color: urgency.withAlpha(200),
          ),
          const SizedBox(width: 7),

          // single line text
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: urgency),
                children: [
                  if (chasingTeamWon) ...[
                    TextSpan(text: battingTeamName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' won by ',
                        style: TextStyle(fontWeight: FontWeight.w400)),
                    TextSpan(text: '$wicketsLeft wickets',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ] else if (allOut) ...[
                    TextSpan(text: bowlingTeamName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: ' won by ',
                        style: TextStyle(fontWeight: FontWeight.w400)),
                    TextSpan(text: '$runsByWhichWon runs',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ] else ...[
                    TextSpan(text: battingTeamName,
                        style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600)),
                    TextSpan(text: ' need ',
                        style: TextStyle(color: Colors.white.withAlpha(100), fontWeight: FontWeight.w400)),
                    TextSpan(text: '$runsNeeded runs',
                        style: TextStyle(color: urgency, fontWeight: FontWeight.w800)),
                    TextSpan(text: ' in ',
                        style: TextStyle(color: Colors.white.withAlpha(100), fontWeight: FontWeight.w400)),
                    TextSpan(text: '$ballsRemaining balls',
                        style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Colors.white.withAlpha(18))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFCC0000).withAlpha(25),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(Icons.toll_rounded, size: 11, color: const Color(0xFFCC0000).withAlpha(191)),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(tossDisplay, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _statusChip() {
    switch (normalizedStatus) {
      case 'live': return _liveChip();
      case 'upcoming': return _pill('UPCOMING', const Color(0xFF1565C0));
      case 'completed': return _pill('ENDED', const Color(0xFF37474F));
      case 'cancelled': return _pill('CANCELLED', Colors.red.shade700);
      case 'delayed': return _pill('DELAYED', Colors.orange.shade700);
      default: return _pill(normalizedStatus.toUpperCase(), Colors.grey.shade800);
    }
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _formatChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB300).withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withAlpha(76)),
      ),
      child: Text(format.toUpperCase(),
          style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }

  Widget _liveChip() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final pulse = 0.5 + 0.5 * sin(2 * pi * _controller.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFCC0000),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: const Color(0xFFCC0000).withAlpha((127 * pulse).toInt()), blurRadius: 8),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha((140 + (115 * pulse)).toInt()),
                ),
              ),
              const SizedBox(width: 4),
              const Text('LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
            ],
          ),
        );
      },
    );
  }

  Widget _logoFallback(String name) {
    return Container(
      color: Colors.white.withAlpha(13),
      child: Center(
        child: Text(
          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}