import 'package:ballbyball/models/current_over.dart';
import 'package:ballbyball/models/live_score_match.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MatchHeader extends StatelessWidget {
  final FeaturedMatch match;

  const MatchHeader({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final isLive = match.meta.status.toLowerCase().contains('live');
    final teamAScore = match.scores['teamA'];
    final teamBScore = match.scores['teamB'];

    final innings = match.liveMatch?.innings ?? 1;
    final target = match.liveMatch?.target;
    final battingTeamKey = match.liveMatch?.battingTeam ?? '';
    final toss = match.toss;

    String tossText = '';
    if (innings == 1 && toss != null && toss.wonBy.isNotEmpty && toss.decision.isNotEmpty) {
      final wonTeam = toss.wonBy == 'teamA' ? match.teamA : match.teamB;
      tossText = '${wonTeam.name} won toss · elected to ${toss.decision}';
    }

    final bool showTarget = innings == 2 && target != null;
    final int runsNeeded = target?.runsNeeded ?? 0;
    final int ballsRemaining = target?.ballsRemaining ?? 0;
    final int oversLeft = ballsRemaining ~/ 6;
    final int ballsLeft = ballsRemaining % 6;
    final double rrr = ballsRemaining > 0 ? (runsNeeded / ballsRemaining * 6) : 0;
    final String battingTeamName = battingTeamKey == 'teamA' ? match.teamA.name : match.teamB.name;
    final int battingWickets = battingTeamKey == 'teamA'
        ? (teamAScore?.wickets ?? 0)
        : (teamBScore?.wickets ?? 0);
    final int wicketsLeft = 10 - battingWickets;
    final bool chasingWon = runsNeeded <= 0;
    final bool allOut = battingWickets >= 10 && runsNeeded > 0;
    final String bowlingTeamName = battingTeamKey == 'teamA' ? match.teamB.name : match.teamA.name;

    final bool showInfoStrip = tossText.isNotEmpty || showTarget;

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            // ── Solid dark base — no BackdropFilter ──────
            Positioned.fill(
              child: Container(color: const Color(0xFF050505)),
            ),

            // ── Subtle team color blobs (cheap, no blur) ─
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.centerLeft,
                          radius: 1.2,
                          colors: [
                            Colors.white.withAlpha(6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.centerRight,
                          radius: 1.2,
                          colors: [
                            Colors.white.withAlpha(6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Red glow center ───────────────────────────
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 250,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFCC0000).withAlpha(20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Nav row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        _NavIcon(onTap: () => Navigator.pop(context)),
                        const Spacer(),
                        _StatusPill(isLive: isLive, status: match.meta.status),
                      ],
                    ),
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
                            runs: teamAScore?.runs ?? 0,
                            wickets: teamAScore?.wickets ?? 0,
                            overs: teamAScore?.overs ?? 0,
                            balls: teamAScore?.balls ?? 0,
                            flipLayout: false,
                            teamKey: 'teamA',
                          ),
                        ),
                        _VsDivider(),
                        Expanded(
                          child: _TeamScoreBlock(
                            logo: match.teamB.logo,
                            name: match.teamB.name,
                            runs: teamBScore?.runs ?? 0,
                            wickets: teamBScore?.wickets ?? 0,
                            overs: teamBScore?.overs ?? 0,
                            balls: teamBScore?.balls ?? 0,
                            flipLayout: true,
                            teamKey: 'teamB',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info strip
                  if (showInfoStrip)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (showTarget)
                            _TargetBar(
                              chasingWon: chasingWon,
                              allOut: allOut,
                              runsNeeded: runsNeeded,
                              oversLeft: oversLeft,
                              ballsLeft: ballsLeft,
                              rrr: rrr,
                              wicketsLeft: wicketsLeft,
                              battingTeamName: battingTeamName,
                              bowlingTeamName: bowlingTeamName,
                              runsByWhichWon: runsNeeded - 1,
                            ),
                          if (tossText.isNotEmpty) ...[
                            if (showTarget) const SizedBox(height: 6),
                            _TossStrip(text: tossText),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Current over strip
                  if (isLive && match.currentOver.isNotEmpty) ...[
                    _CurrentOverStrip(balls: match.currentOver),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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
        Icon(Icons.toll_rounded,
            size: 10, color: const Color(0xFFCC0000).withAlpha(140)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(80),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
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
    required this.chasingWon,
    required this.allOut,
    required this.runsNeeded,
    required this.oversLeft,
    required this.ballsLeft,
    required this.rrr,
    required this.wicketsLeft,
    required this.battingTeamName,
    required this.bowlingTeamName,
    required this.runsByWhichWon,
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
            const Icon(Icons.emoji_events_rounded,
                size: 14, color: Color(0xFF66BB6A)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$winner won by $margin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: battingTeamName,
              style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: ' need ',
              style: TextStyle(
                  color: Colors.white.withAlpha(80),
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: '$runsNeeded runs',
              style: TextStyle(
                  color: urgency,
                  fontSize: 12,
                  fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: ' in ',
              style: TextStyle(
                  color: Colors.white.withAlpha(80),
                  fontSize: 12,
                  fontWeight: FontWeight.w400),
            ),
            TextSpan(
              text: '${oversLeft * 6 + ballsLeft} balls',
              style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
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
        width: 38,
        height: 38,
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
        color: isLive
            ? const Color(0xFFCC0000).withAlpha(38)
            : Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? const Color(0xFFCC0000).withAlpha(102)
              : Colors.white.withAlpha(26),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: Color(0xFFFF5252), shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(
            isLive ? 'LIVE' : status.toUpperCase(),
            style: TextStyle(
              color:
              isLive ? const Color(0xFFFF5252) : const Color(0xFF999999),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── VS Divider ────────────────────────────────────────────────
class _VsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
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
                    color: Color(0xFF666666),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 10),
          _gradientLine(),
        ],
      ),
    );
  }

  Widget _gradientLine() => Container(
    width: 1,
    height: 30,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withAlpha(38),
          Colors.transparent
        ],
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
    required this.logo,
    required this.name,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
    required this.flipLayout,
    required this.teamKey,
  });

  @override
  Widget build(BuildContext context) {
    final cross =
    flipLayout ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      children: [
        Hero(
          tag: 'team_logo_$teamKey',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
              Border.all(color: Colors.white.withAlpha(46), width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(128),
                    blurRadius: 16,
                    spreadRadius: 3,
                    offset: const Offset(0, 4))
              ],
            ),
            child: ClipOval(
                child: CachedNetworkImage(imageUrl: logo, fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 12),
        Text(name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: flipLayout ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$runs',
                style: const TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    height: 1.0)),
            Text('/$wickets',
                style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.0)),
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
                  color: Color(0xFF888888),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
        ),
      ],
    );
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('THIS OVER',
                  style: TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3)),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCC0000).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$legalCount/6',
                    style: const TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...balls
                    .asMap()
                    .entries
                    .map((e) => _BallDot(ball: e.value, index: e.key)),
                ...List.generate(
                  (6 - legalCount).clamp(0, 6),
                      (i) => _EmptyBallDot(index: balls.length + i),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ball Dot ──────────────────────────────────────────────────
class _BallDot extends StatefulWidget {
  final CurrentOver ball;
  final int index;
  const _BallDot({required this.ball, required this.index});

  @override
  State<_BallDot> createState() => _BallDotState();
}

class _BallDotState extends State<_BallDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    Future.delayed(Duration(milliseconds: widget.index * 25), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bg {
    if (widget.ball.isWicket) return const Color(0xFFCC0000).withAlpha(51);
    if (widget.ball.isWide) return const Color(0xFF1565C0).withAlpha(51);
    if (widget.ball.isNoBall) return const Color(0xFFE65100).withAlpha(51);
    if (widget.ball.value == 4) return const Color(0xFF0288D1).withAlpha(51);
    if (widget.ball.value == 6) return const Color(0xFF2E7D32).withAlpha(51);
    if (widget.ball.value == 0) return Colors.white.withAlpha(8);
    return Colors.white.withAlpha(13);
  }

  Color get _border {
    if (widget.ball.isWicket) return const Color(0xFFCC0000).withAlpha(179);
    if (widget.ball.isWide) return const Color(0xFF1565C0).withAlpha(153);
    if (widget.ball.isNoBall) return const Color(0xFFE65100).withAlpha(153);
    if (widget.ball.value == 4) return const Color(0xFF0288D1).withAlpha(153);
    if (widget.ball.value == 6) return const Color(0xFF2E7D32).withAlpha(153);
    return Colors.white.withAlpha(38);
  }

  Color get _text {
    if (widget.ball.isWicket) return const Color(0xFFFF5252);
    if (widget.ball.isWide) return const Color(0xFF42A5F5);
    if (widget.ball.isNoBall) return const Color(0xFFFF7043);
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _bg,
              shape: BoxShape.circle,
              border: Border.all(color: _border, width: 1.5),
              boxShadow: widget.ball.isWicket || widget.ball.value >= 4
                  ? [
                BoxShadow(
                    color: _border.withAlpha(102),
                    blurRadius: 8,
                    spreadRadius: 1)
              ]
                  : null,
            ),
            child: Center(
              child: Text(widget.ball.label,
                  style: TextStyle(
                    color: _text,
                    fontSize:
                    widget.ball.isWide || widget.ball.isNoBall ? 8 : 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
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
  const _EmptyBallDot({required this.index});

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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(26), width: 1.5),
          ),
        ),
      ),
    );
  }
}