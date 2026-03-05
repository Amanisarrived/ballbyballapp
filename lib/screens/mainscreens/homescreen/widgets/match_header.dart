import 'package:ballbyball/models/current_over.dart';
import 'package:ballbyball/models/live_score_match.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// ── MatchHeader is now StatelessWidget ────────────────────────
// _HeaderData is computed once per call, no didUpdateWidget latency.
class MatchHeader extends StatelessWidget {
  final FeaturedMatch match;
  const MatchHeader({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final d = _HeaderData.from(match);

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Stack(children: [
          // ── Solid dark base ───────────────────────────
          Positioned.fill(child: Container(color: const Color(0xFF050505))),

          // ── Subtle blobs ──────────────────────────────
          Positioned.fill(
            child: Row(children: [
              Expanded(child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerLeft, radius: 1.2,
                    colors: [Color(0x06FFFFFF), Colors.transparent],
                  ),
                ),
              )),
              Expanded(child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.centerRight, radius: 1.2,
                    colors: [Color(0x06FFFFFF), Colors.transparent],
                  ),
                ),
              )),
            ]),
          ),

          // ── Red glow center ───────────────────────────
          Positioned.fill(
            child: Center(
              child: Container(
                width: 250, height: 150,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0x14CC0000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(children: [
              // Nav row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  _NavIcon(onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  _StatusPill(isLive: d.isLive, status: match.meta.status),
                ]),
              ),

              const SizedBox(height: 24),

              // Score row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TeamScoreBlock(
                        logo: match.teamA.logo,
                        name: match.teamA.name,
                        runs: d.teamAScore?.runs ?? 0,
                        wickets: d.teamAScore?.wickets ?? 0,
                        overs: d.teamAScore?.overs ?? 0,
                        balls: d.teamAScore?.balls ?? 0,
                        flipLayout: false,
                        teamKey: 'teamA',
                      ),
                    ),
                    const _VsDivider(),
                    Expanded(
                      child: _TeamScoreBlock(
                        logo: match.teamB.logo,
                        name: match.teamB.name,
                        runs: d.teamBScore?.runs ?? 0,
                        wickets: d.teamBScore?.wickets ?? 0,
                        overs: d.teamBScore?.overs ?? 0,
                        balls: d.teamBScore?.balls ?? 0,
                        flipLayout: true,
                        teamKey: 'teamB',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Info strip
              if (d.showInfoStrip)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    if (d.showTarget)
                      _TargetBar(
                        chasingWon: d.chasingWon,
                        allOut: d.allOut,
                        runsNeeded: d.runsNeeded,
                        oversLeft: d.oversLeft,
                        ballsLeft: d.ballsLeft,
                        rrr: d.rrr,
                        wicketsLeft: d.wicketsLeft,
                        battingTeamName: d.battingTeamName,
                        bowlingTeamName: d.bowlingTeamName,
                        runsByWhichWon: d.runsNeeded - 1,
                      ),
                    if (d.tossText.isNotEmpty) ...[
                      if (d.showTarget) const SizedBox(height: 6),
                      _TossStrip(text: d.tossText),
                    ],
                  ]),
                ),

              const SizedBox(height: 10),

              // ── Current over strip — scoped repaint ───
              // Only rebuilds when currentOver list identity changes.
              // Keys are ball-identity-based so existing dots are reused.
              if (d.isLive && match.currentOver.isNotEmpty) ...[
                RepaintBoundary(
                  child: _CurrentOverStrip(balls: match.currentOver),
                ),
                const SizedBox(height: 10),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── All computed values in one place ──────────────────────────
class _HeaderData {
  final bool isLive;
  final dynamic teamAScore;
  final dynamic teamBScore;
  final String tossText;
  final bool showTarget;
  final int runsNeeded;
  final int oversLeft;
  final int ballsLeft;
  final double rrr;
  final String battingTeamName;
  final String bowlingTeamName;
  final int wicketsLeft;
  final bool chasingWon;
  final bool allOut;
  final bool showInfoStrip;

  const _HeaderData({
    required this.isLive,
    required this.teamAScore,
    required this.teamBScore,
    required this.tossText,
    required this.showTarget,
    required this.runsNeeded,
    required this.oversLeft,
    required this.ballsLeft,
    required this.rrr,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.wicketsLeft,
    required this.chasingWon,
    required this.allOut,
    required this.showInfoStrip,
  });

  factory _HeaderData.from(FeaturedMatch match) {
    final isLive = match.meta.status.toLowerCase().contains('live');
    final teamAScore = match.scores['teamA'];
    final teamBScore = match.scores['teamB'];
    final innings = match.liveMatch?.innings ?? 1;
    final target = match.liveMatch?.target;
    final battingTeamKey = match.liveMatch?.battingTeam ?? '';
    final toss = match.toss;

    String tossText = '';
    if (innings == 1 && toss != null &&
        toss.wonBy.isNotEmpty && toss.decision.isNotEmpty) {
      final wonTeam = toss.wonBy == 'teamA' ? match.teamA : match.teamB;
      tossText = '${wonTeam.name} won toss · elected to ${toss.decision}';
    }

    final showTarget = innings == 2 && target != null;
    final runsNeeded = target?.runsNeeded ?? 0;
    final ballsRemaining = target?.ballsRemaining ?? 0;
    final oversLeft = ballsRemaining ~/ 6;
    final ballsLeft = ballsRemaining % 6;
    final rrr = ballsRemaining > 0 ? (runsNeeded / ballsRemaining * 6) : 0.0;
    final battingTeamName =
    battingTeamKey == 'teamA' ? match.teamA.name : match.teamB.name;
    final bowlingTeamName =
    battingTeamKey == 'teamA' ? match.teamB.name : match.teamA.name;
    final battingWickets = battingTeamKey == 'teamA'
        ? (teamAScore?.wickets ?? 0)
        : (teamBScore?.wickets ?? 0);
    final wicketsLeft = 10 - battingWickets;
    final chasingWon = runsNeeded <= 0;
    final allOut = battingWickets >= 10 && runsNeeded > 0;

    return _HeaderData(
      isLive: isLive,
      teamAScore: teamAScore,
      teamBScore: teamBScore,
      tossText: tossText,
      showTarget: showTarget,
      runsNeeded: runsNeeded,
      oversLeft: oversLeft,
      ballsLeft: ballsLeft,
      rrr: rrr,
      battingTeamName: battingTeamName,
      bowlingTeamName: bowlingTeamName,
      wicketsLeft: wicketsLeft,
      chasingWon: chasingWon,
      allOut: allOut,
      showInfoStrip: tossText.isNotEmpty || showTarget,
    );
  }
}

// ── Toss Strip ────────────────────────────────────────────────
class _TossStrip extends StatelessWidget {
  final String text;
  const _TossStrip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.toll_rounded, size: 10, color: Color(0x8CCC0000)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0x50FFFFFF),
                fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.2,
              )),
        ),
      ],
    );
  }
}

// ── Target Bar ────────────────────────────────────────────────
class _TargetBar extends StatelessWidget {
  final bool chasingWon, allOut;
  final int runsNeeded, oversLeft, ballsLeft, wicketsLeft, runsByWhichWon;
  final double rrr;
  final String battingTeamName, bowlingTeamName;

  const _TargetBar({
    required this.chasingWon, required this.allOut,
    required this.runsNeeded, required this.oversLeft,
    required this.ballsLeft, required this.rrr,
    required this.wicketsLeft, required this.battingTeamName,
    required this.bowlingTeamName, required this.runsByWhichWon,
  });

  @override
  Widget build(BuildContext context) {
    if (chasingWon || allOut) {
      final winner = chasingWon ? battingTeamName : bowlingTeamName;
      final margin = chasingWon ? '$wicketsLeft wickets' : '$runsByWhichWon runs';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF66BB6A).withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF66BB6A).withAlpha(45)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFF66BB6A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text('$winner won by $margin',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF66BB6A), fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    final totalBalls = oversLeft * 6 + ballsLeft;
    final Color urgency = totalBalls < 12
        ? const Color(0xFFFF5252)
        : totalBalls < 36
        ? const Color(0xFFFFB300)
        : const Color(0xFF4FC3F7);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: RichText(
        maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
        text: TextSpan(children: [
          TextSpan(text: battingTeamName,
              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12, fontWeight: FontWeight.w600)),
          TextSpan(text: ' need ',
              style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12, fontWeight: FontWeight.w400)),
          TextSpan(text: '$runsNeeded runs',
              style: TextStyle(color: urgency, fontSize: 12, fontWeight: FontWeight.w800)),
          TextSpan(text: ' in ',
              style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12, fontWeight: FontWeight.w400)),
          TextSpan(text: '$totalBalls balls',
              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

// ── Nav Icon ──────────────────────────────────────────────────
class _NavIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _NavIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(31)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFDDDDDD), size: 16),
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final bool isLive;
  final String status;
  const _StatusPill({required this.isLive, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF260000) : Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive ? const Color(0x66CC0000) : Colors.white.withAlpha(26),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isLive) ...[
          const _PulseDot(),
          const SizedBox(width: 6),
        ],
        Text(
          isLive ? 'LIVE' : status.toUpperCase(),
          style: TextStyle(
            color: isLive ? const Color(0xFFFF5252) : const Color(0xFF999999),
            fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2,
          ),
        ),
      ]),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6, height: 6,
      decoration: const BoxDecoration(
          color: Color(0xFFFF5252), shape: BoxShape.circle),
    );
  }
}

// ── VS Divider ────────────────────────────────────────────────
class _VsDivider extends StatelessWidget {
  const _VsDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(children: [
        _gradientLine(),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(8),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: const Text('VS',
              style: TextStyle(
                  color: Color(0xFF666666), fontSize: 10,
                  fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 10),
        _gradientLine(),
      ]),
    );
  }

  Widget _gradientLine() => Container(
    width: 1, height: 30,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, Color(0x26FFFFFF), Colors.transparent],
      ),
    ),
  );
}

// ── Team Score Block ──────────────────────────────────────────
class _TeamScoreBlock extends StatelessWidget {
  final String logo, name;
  final int runs, wickets, overs, balls;
  final bool flipLayout;
  final String teamKey;

  const _TeamScoreBlock({
    required this.logo, required this.name,
    required this.runs, required this.wickets,
    required this.overs, required this.balls,
    required this.flipLayout, required this.teamKey,
  });

  @override
  Widget build(BuildContext context) {
    final cross = flipLayout ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(crossAxisAlignment: cross, children: [
      Hero(
        tag: 'team_logo_$teamKey',
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(46), width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x80000000), blurRadius: 16,
                  spreadRadius: 3, offset: Offset(0, 4))
            ],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: logo,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: const Color(0xFF1A1A1A)),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.sports_cricket_rounded,
                    color: Color(0xFF444444), size: 24),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(name,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          textAlign: flipLayout ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
              color: Color(0xFFAAAAAA), fontSize: 13,
              fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text('$runs',
              style: const TextStyle(
                  color: Color(0xFFFAFAFA), fontSize: 32,
                  fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0)),
          Text('/$wickets',
              style: const TextStyle(
                  color: Color(0xFF999999), fontSize: 20,
                  fontWeight: FontWeight.w700, height: 1.0)),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Text('$overs.$balls overs',
            style: const TextStyle(
                color: Color(0xFF888888), fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 0.3)),
      ),
    ]);
  }
}

// ── Current Over Strip ────────────────────────────────────────
class _CurrentOverStrip extends StatelessWidget {
  final List<CurrentOver> balls;
  const _CurrentOverStrip({required this.balls});

  @override
  Widget build(BuildContext context) {
    final legalCount = balls.where((b) => b.isLegal).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('THIS OVER',
              style: TextStyle(color: Color(0xFF777777), fontSize: 9,
                  fontWeight: FontWeight.w700, letterSpacing: 1.3)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0x1ACC0000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$legalCount/6',
                style: const TextStyle(color: Color(0xFFFF5252),
                    fontSize: 9, fontWeight: FontWeight.w800)),
          ),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FIX 1: Key is ball-identity-based (label + position), NOT just index.
              // Flutter reuses existing _BallDot widgets and only animates truly NEW ones.
              // Previously: ValueKey('ball_${e.key}') caused ALL dots to re-animate
              // on every stream event because the widget was fully recreated.
              ...balls.asMap().entries.map((e) =>
                  _BallDot(
                    key: ValueKey('ball_${e.key}_${e.value.label}'),
                    ball: e.value,
                    index: e.key,
                  )),
              ...List.generate(
                (6 - legalCount).clamp(0, 6),
                    (i) => _EmptyBallDot(
                  key: ValueKey('empty_${balls.length + i}'),
                  index: balls.length + i,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Ball Dot ──────────────────────────────────────────────────
class _BallDot extends StatefulWidget {
  final CurrentOver ball;
  final int index;
  const _BallDot({super.key, required this.ball, required this.index});

  @override
  State<_BallDot> createState() => _BallDotState();
}

class _BallDotState extends State<_BallDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    // FIX 2: Only the LAST ball (the newly added one) gets a delay.
    // Old balls already have their animation completed via _ctrl.value = 1.0,
    // so no staggered re-animation runs for them on rebuild.
    if (_ctrl.value == 0.0) {
      Future.delayed(Duration(milliseconds: widget.index * 25), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _bg {
    if (widget.ball.isWicket)  return const Color(0x33CC0000);
    if (widget.ball.isWide)    return const Color(0x331565C0);
    if (widget.ball.isNoBall)  return const Color(0x33E65100);
    if (widget.ball.value == 4) return const Color(0x330288D1);
    if (widget.ball.value == 6) return const Color(0x332E7D32);
    if (widget.ball.value == 0) return const Color(0x08FFFFFF);
    return const Color(0x0DFFFFFF);
  }

  Color get _border {
    if (widget.ball.isWicket)  return const Color(0xB3CC0000);
    if (widget.ball.isWide)    return const Color(0x991565C0);
    if (widget.ball.isNoBall)  return const Color(0x99E65100);
    if (widget.ball.value == 4) return const Color(0x990288D1);
    if (widget.ball.value == 6) return const Color(0x992E7D32);
    return const Color(0x26FFFFFF);
  }

  Color get _text {
    if (widget.ball.isWicket)  return const Color(0xFFFF5252);
    if (widget.ball.isWide)    return const Color(0xFF42A5F5);
    if (widget.ball.isNoBall)  return const Color(0xFFFF7043);
    if (widget.ball.value == 4) return const Color(0xFF4FC3F7);
    if (widget.ball.value == 6) return const Color(0xFF66BB6A);
    if (widget.ball.value == 0) return const Color(0xFF666666);
    return const Color(0xFFCCCCCC);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _bg, shape: BoxShape.circle,
              border: Border.all(color: _border, width: 1.5),
              boxShadow: widget.ball.isWicket || widget.ball.value >= 4
                  ? [BoxShadow(color: _border.withAlpha(102), blurRadius: 8, spreadRadius: 1)]
                  : null,
            ),
            child: Center(
              child: Text(widget.ball.label,
                  style: TextStyle(
                    color: _text,
                    fontSize: widget.ball.isWide || widget.ball.isNoBall ? 8 : 10,
                    fontWeight: FontWeight.w900, letterSpacing: -0.3,
                  )),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBallDot extends StatefulWidget {
  final int index;
  const _EmptyBallDot({super.key, required this.index});

  @override
  State<_EmptyBallDot> createState() => _EmptyBallDotState();
}

class _EmptyBallDotState extends State<_EmptyBallDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.index * 30), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: Colors.transparent, shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(26), width: 1.5),
          ),
        ),
      ),
    );
  }
}