import 'package:cached_network_image/cached_network_image.dart';
import 'package:ballbyball/models/upcoming_fixture_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const _bg = Color(0xFF050505);
const _glass = Color(0xFF0E0E0E);
const _glass2 = Color(0xFF121212);
const _stroke = Color(0xFF1E1E1E);
const _stroke2 = Color(0xFF252525);
const _red = Color(0xFFCC0000);
const _redHot = Color(0xFFFF1A1A);
const _gold = Color(0xFFD4A847);
const _goldFg = Color(0xFFF0C96B);
const _green = Color(0xFF4CAF50);

class UpcomingFixtureDetailScreen extends StatelessWidget {
  final UpcomingFixtureModel fixture;
  const UpcomingFixtureDetailScreen({super.key, required this.fixture});

  bool get _ended => fixture.winningTeam.isNotEmpty;
  bool get _ongoing => !_ended && DateTime.now().isAfter(fixture.dateTime);
  bool _won(String t) =>
      _ended && fixture.winningTeam.toLowerCase().startsWith(t.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final t1Won = _won(fixture.team1);
    final t2Won = _won(fixture.team2);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(
        top: true,
        child: Scaffold(
          backgroundColor: _bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _StadiumHero(
                  fixture: fixture,
                  ended: _ended,
                  ongoing: _ongoing,
                  t1Won: t1Won,
                  t2Won: t2Won,
                ),
              ),
              if (_ended)
                SliverToBoxAdapter(child: _WinnerChip(fixture: fixture)),
              if (_ongoing) SliverToBoxAdapter(child: _OngoingChip()),
              if (_ended &&
                  (fixture.team1Score.isNotEmpty ||
                      fixture.team2Score.isNotEmpty))
                SliverToBoxAdapter(
                  child: _ScoreDuel(
                    fixture: fixture,
                    t1Won: t1Won,
                    t2Won: t2Won,
                  ),
                ),
              if (_ended && fixture.playerOfMatch.isNotEmpty)
                SliverToBoxAdapter(child: _PotmSpotlight(fixture: fixture)),
              if (!_ended && !_ongoing)
                SliverToBoxAdapter(
                  child: _LiveCountdown(matchTime: fixture.dateTime),
                ),
              SliverToBoxAdapter(child: _InfoGrid(fixture: fixture)),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  ONGOING CHIP
// ════════════════════════════════════════════════════════════
class _OngoingChip extends StatefulWidget {
  @override
  State<_OngoingChip> createState() => _OngoingChipState();
}

class _OngoingChipState extends State<_OngoingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int _a(double val) => (val * 255).round().clamp(0, 255);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_green.withAlpha(31), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _green.withAlpha(_a(_pulse.value * 0.5))),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _green.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _green.withAlpha(_a(_pulse.value * 0.6)),
                ),
              ),
              child: Icon(
                Icons.sports_cricket_rounded,
                color: _green.withAlpha(_a(_pulse.value)),
                size: 17,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATCH IN PROGRESS',
                  style: TextStyle(
                    color: _green.withAlpha(_a(_pulse.value)),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live scoring underway',
                  style: TextStyle(
                    color: Colors.white.withAlpha(60),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _green.withAlpha(_a(_pulse.value)),
                boxShadow: [
                  BoxShadow(
                    color: _green.withAlpha(_a(_pulse.value * 0.6)),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  STADIUM HERO
// ════════════════════════════════════════════════════════════
class _StadiumHero extends StatelessWidget {
  final UpcomingFixtureModel fixture;
  final bool ended, ongoing, t1Won, t2Won;
  const _StadiumHero({
    required this.fixture,
    required this.ended,
    required this.ongoing,
    required this.t1Won,
    required this.t2Won,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final h = 420.0 + top;

    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HeroPainter(t1Won: t1Won, t2Won: t2Won),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _ScanlinePainter())),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, _bg],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: top),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    _GlassBtn(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                    const Spacer(),
                    _StatusCapsule(ended: ended, ongoing: ongoing),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _EyebrowLabel(fixture.tournament),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _HeroTeamBlock(
                          name: fixture.team1,
                          logo: fixture.team1Logo,
                          isWinner: t1Won,
                          isLeft: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _VsDivider(
                          dateTime: fixture.dateTime,
                          ended: ended,
                          ongoing: ongoing,
                        ),
                      ),
                      Expanded(
                        child: _HeroTeamBlock(
                          name: fixture.team2,
                          logo: fixture.team2Logo,
                          isWinner: t2Won,
                          isLeft: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  HERO TEAM BLOCK
// ════════════════════════════════════════════════════════════
class _HeroTeamBlock extends StatelessWidget {
  final String name, logo;
  final bool isWinner, isLeft;
  const _HeroTeamBlock({
    required this.name,
    required this.logo,
    required this.isWinner,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isWinner ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _gold.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _gold.withAlpha(70)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: _goldFg,
                  size: 10,
                ),
                const SizedBox(width: 5),
                const Text(
                  'WINNER',
                  style: TextStyle(
                    color: _goldFg,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        _TeamLogo(logo: logo, name: name, isWinner: isWinner, size: 88),
        const SizedBox(height: 14),
        Text(
          name,
          maxLines: 2,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isWinner ? Colors.white : Colors.white.withAlpha(130),
            fontSize: 16,
            fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
            height: 1.15,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String logo, name;
  final bool isWinner;
  final double size;
  const _TeamLogo({
    required this.logo,
    required this.name,
    required this.isWinner,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(6),
        border: Border.all(
          color: isWinner ? _gold.withAlpha(120) : Colors.white.withAlpha(18),
          width: isWinner ? 2.5 : 1.0,
        ),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: _gold.withAlpha(50),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: _gold.withAlpha(20),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ]
            : [],
      ),
      child: ClipOval(
        child: logo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.cover,
                placeholder: (_, _) => _Fallback(name: name),
                errorWidget: (_, _, _) => _Fallback(name: name),
              )
            : _Fallback(name: name),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  final String name;
  const _Fallback({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withAlpha(8),
      child: Center(
        child: Text(
          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VS DIVIDER — ongoing support added
// ════════════════════════════════════════════════════════════
class _VsDivider extends StatelessWidget {
  final DateTime dateTime;
  final bool ended, ongoing;
  const _VsDivider({
    required this.dateTime,
    required this.ended,
    required this.ongoing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 20, color: Colors.white.withAlpha(10)),
        const SizedBox(height: 8),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _glass2,
            border: Border.all(
              color: ongoing
                  ? _green.withAlpha(102)
                  : Colors.white.withAlpha(15),
            ),
          ),
          child: Center(
            child: Text(
              ended ? 'FT' : 'VS',
              style: TextStyle(
                color: ongoing
                    ? _green
                    : ended
                    ? const Color(0xFF555555)
                    : Colors.white24,
                fontSize: ended ? 9 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          DateFormat('d MMM').format(dateTime).toUpperCase(),
          style: TextStyle(
            color: Colors.white.withAlpha(30),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('HH:mm').format(dateTime),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 1, height: 20, color: Colors.white.withAlpha(10)),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  STATUS CAPSULE — ongoing added
// ════════════════════════════════════════════════════════════
class _StatusCapsule extends StatefulWidget {
  final bool ended, ongoing;
  const _StatusCapsule({required this.ended, required this.ongoing});

  @override
  State<_StatusCapsule> createState() => _StatusCapsuleState();
}

class _StatusCapsuleState extends State<_StatusCapsule>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.ongoing) _ctrl.repeat(reverse: true);
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
    if (widget.ended) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(18)),
        ),
        child: const Text(
          'MATCH ENDED',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    // ── ONGOING — green pulsing ──
    if (widget.ongoing) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _green.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _green.withAlpha(_a(_pulse.value * 0.6))),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _green.withAlpha(_a(_pulse.value)),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withAlpha(_a(_pulse.value * 0.6)),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Text(
                'ONGOING',
                style: TextStyle(
                  color: _green.withAlpha(_a(_pulse.value)),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── UPCOMING ──
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _red.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _red.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(right: 7),
            decoration: const BoxDecoration(
              color: _redHot,
              shape: BoxShape.circle,
            ),
          ),
          const Text(
            'UPCOMING',
            style: TextStyle(
              color: _redHot,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  WINNER CHIP
// ════════════════════════════════════════════════════════════
class _WinnerChip extends StatelessWidget {
  final UpcomingFixtureModel fixture;
  const _WinnerChip({required this.fixture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_red.withAlpha(25), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withAlpha(55)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _red.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red.withAlpha(40)),
            ),
            child: const Icon(
              Icons.military_tech_rounded,
              color: _red,
              size: 17,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              fixture.resultSummary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SCORE DUEL
// ════════════════════════════════════════════════════════════
class _ScoreDuel extends StatelessWidget {
  final UpcomingFixtureModel fixture;
  final bool t1Won, t2Won;
  const _ScoreDuel({
    required this.fixture,
    required this.t1Won,
    required this.t2Won,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      label: 'SCORECARD',
      icon: Icons.scoreboard_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _ScoreSide(
              team: fixture.team1,
              logo: fixture.team1Logo,
              score: fixture.team1Score,
              isWinner: t1Won,
              isLeft: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              '·',
              style: TextStyle(
                color: Colors.white.withAlpha(15),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: _ScoreSide(
              team: fixture.team2,
              logo: fixture.team2Logo,
              score: fixture.team2Score,
              isWinner: t2Won,
              isLeft: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreSide extends StatelessWidget {
  final String team, logo, score;
  final bool isWinner, isLeft;
  const _ScoreSide({
    required this.team,
    required this.logo,
    required this.score,
    required this.isWinner,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final cross = isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    return Column(
      crossAxisAlignment: cross,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (!isLeft) ...[
              Flexible(
                child: Text(
                  team,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withAlpha(40),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SmallLogo(logo: logo, name: team),
            ] else ...[
              _SmallLogo(logo: logo, name: team),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  team,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(40),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          score.isNotEmpty ? score : '—',
          textAlign: isLeft ? TextAlign.left : TextAlign.right,
          style: TextStyle(
            color: isWinner ? Colors.white : Colors.white.withAlpha(80),
            fontSize: score.length > 12 ? 16 : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SmallLogo extends StatelessWidget {
  final String logo, name;
  const _SmallLogo({required this.logo, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(8),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: ClipOval(
        child: logo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: logo,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => _miniText(name),
              )
            : _miniText(name),
      ),
    );
  }

  Widget _miniText(String n) => Center(
    child: Text(
      n.isNotEmpty ? n[0] : '?',
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 8,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  POTM SPOTLIGHT
// ════════════════════════════════════════════════════════════
class _PotmSpotlight extends StatelessWidget {
  final UpcomingFixtureModel fixture;
  const _PotmSpotlight({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = fixture.playerOfMatchPhoto.isNotEmpty;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withAlpha(35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gold.withAlpha(14), _gold.withAlpha(5), Colors.transparent],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GoldNoisePainter())),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 2,
                        height: 10,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      Text(
                        'PLAYER OF THE MATCH',
                        style: TextStyle(
                          color: _gold.withAlpha(160),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [_gold.withAlpha(180), _gold.withAlpha(80)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withAlpha(60),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(2.5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _glass,
                            ),
                            child: ClipOval(
                              child: hasPhoto
                                  ? CachedNetworkImage(
                                      imageUrl: fixture.playerOfMatchPhoto,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) =>
                                          const _PersonIcon(),
                                    )
                                  : const _PersonIcon(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Man of the Match',
                              style: TextStyle(
                                color: _gold.withAlpha(120),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fixture.playerOfMatch,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _gold.withAlpha(18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withAlpha(50)),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: _goldFg,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonIcon extends StatelessWidget {
  const _PersonIcon();
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withAlpha(6),
    child: const Center(
      child: Icon(Icons.person_rounded, color: Colors.white24, size: 30),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  LIVE COUNTDOWN
// ════════════════════════════════════════════════════════════
class _LiveCountdown extends StatefulWidget {
  final DateTime matchTime;
  const _LiveCountdown({required this.matchTime});
  @override
  State<_LiveCountdown> createState() => _LiveCountdownState();
}

class _LiveCountdownState extends State<_LiveCountdown> {
  late Duration _rem;

  @override
  void initState() {
    super.initState();
    _tick();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(_tick);
      return true;
    });
  }

  void _tick() {
    _rem = widget.matchTime.difference(DateTime.now());
    if (_rem.isNegative) _rem = Duration.zero;
  }

  @override
  Widget build(BuildContext context) {
    if (_rem == Duration.zero) return const SizedBox.shrink();
    final d = _rem.inDays;
    final h = _rem.inHours % 24;
    final m = _rem.inMinutes % 60;
    final s = _rem.inSeconds % 60;

    return _Card(
      label: 'MATCH STARTS IN',
      icon: Icons.timer_outlined,
      accentColor: _red,
      child: Row(
        children: [
          _DigitBox(value: d, label: 'DAYS'),
          _Colon(),
          _DigitBox(value: h, label: 'HRS'),
          _Colon(),
          _DigitBox(value: m, label: 'MIN'),
          _Colon(),
          _DigitBox(value: s, label: 'SEC', accent: true),
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  final int value;
  final String label;
  final bool accent;
  const _DigitBox({
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: accent ? _red.withAlpha(15) : _glass2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent ? _red.withAlpha(50) : _stroke2),
            ),
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: accent ? _redHot : Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(25),
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Colon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(5, 0, 5, 22),
    child: Text(
      ':',
      style: TextStyle(
        color: Colors.white12,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════
//  INFO GRID
// ════════════════════════════════════════════════════════════
class _InfoGrid extends StatelessWidget {
  final UpcomingFixtureModel fixture;
  const _InfoGrid({required this.fixture});

  @override
  Widget build(BuildContext context) {
    final dt = fixture.dateTime;
    return _Card(
      label: 'MATCH DETAILS',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  icon: Icons.emoji_events_rounded,
                  label: 'TOURNAMENT',
                  value: fixture.tournament,
                  accent: _gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCell(
                  icon: Icons.location_on_rounded,
                  label: 'VENUE',
                  value: fixture.venue,
                  accent: const Color(0xFF4B8BF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCell(
                  icon: Icons.calendar_today_rounded,
                  label: 'DATE',
                  value: DateFormat('EEE, d MMM y').format(dt),
                  accent: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCell(
                  icon: Icons.access_time_rounded,
                  label: 'TIME (LOCAL)',
                  value: DateFormat('hh:mm a').format(dt),
                  accent: Colors.purpleAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _glass2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accent.withAlpha(18),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: accent.withAlpha(200), size: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(25),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 2,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  SHARED
// ════════════════════════════════════════════════════════════
class _GlassBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: child,
      ),
    );
  }
}

class _EyebrowLabel extends StatelessWidget {
  final String text;
  const _EyebrowLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 20, height: 1, color: Colors.white.withAlpha(15)),
        const SizedBox(width: 10),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withAlpha(30),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            overflow: TextOverflow.ellipsis,
            letterSpacing: 1.9,
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 20, height: 1, color: Colors.white.withAlpha(15)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final Color accentColor;

  const _Card({
    required this.label,
    required this.icon,
    required this.child,
    this.accentColor = _red,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: _glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 10,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Icon(icon, size: 12, color: Colors.white.withAlpha(28)),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(28),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _stroke),
          Padding(padding: const EdgeInsets.all(18), child: child),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  PAINTERS
// ════════════════════════════════════════════════════════════
class _HeroPainter extends CustomPainter {
  final bool t1Won, t2Won;
  const _HeroPainter({required this.t1Won, required this.t2Won});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bg,
    );
    final rPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [_red.withAlpha(18), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), rPaint);
    final leftGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1, 0),
        radius: 1.0,
        colors: [
          (t1Won ? _gold : _red).withAlpha(t1Won ? 30 : 14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), leftGlow);
    final rightGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1, 0),
        radius: 1.0,
        colors: [
          (t2Won ? _gold : _red).withAlpha(t2Won ? 30 : 14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), rightGlow);
    final gPaint = Paint()
      ..color = Colors.white.withAlpha(3)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gPaint);
    }
    final dPaint = Paint()
      ..color = _red.withAlpha(5)
      ..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 48) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        dPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.t1Won != t1Won || old.t2Won != t2Won;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withAlpha(18)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _GoldNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _gold.withAlpha(6)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 16) {
      for (double y = 0; y < size.height; y += 16) {
        if ((x + y).toInt() % 3 == 0) {
          canvas.drawCircle(Offset(x, y), 0.8, p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
