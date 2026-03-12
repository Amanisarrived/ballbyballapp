import 'package:ballbyball/models/upcoming_fixture_model.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/upcoming_fixture_detiled_screen.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/upcomming_fixture_card.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/upcoming_fixture_card_screen.dart';
import 'package:ballbyball/service/upcoming_fixture_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpcomingSection extends StatelessWidget {
  final bool previewMode;

  const UpcomingSection({
    super.key,
    this.previewMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UpcomingFixtureModel>>(
      stream: UpcomingFixtureService.instance.streamUpcomingFixtures(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return previewMode ? _buildHorizontalEmpty() : _buildVerticalEmpty();
        }
        return previewMode
            ? _buildHorizontal(snapshot.data!)
            : _buildVertical(snapshot.data!);
      },
    );
  }

  // ── HORIZONTAL (For You tab — 3 cards, no See All) ──────
  Widget _buildHorizontal(List<UpcomingFixtureModel> fixtures) {
    final displayFixtures = fixtures.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            itemCount: displayFixtures.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return UpcomingFixtureCard(fixture: displayFixtures[index]);
            },
          ),
        ),
      ],
    );
  }

  // ── VERTICAL (Upcoming tab — all cards) ─────────────────
  Widget _buildVertical(List<UpcomingFixtureModel> fixtures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fixtures.length,
          itemBuilder: (context, index) {
            return _FadeIn(
              delay: Duration(milliseconds: index * 80),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UpcomingFixtureDetailScreen(
                          fixture: fixtures[index]),
                    ),
                  );
                },
                child: UpcomingFixtureCardScreen(fixture: fixtures[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── EMPTY STATE — horizontal (preview card strip) ───────
  Widget _buildHorizontalEmpty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(10)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(12)),
                    ),
                    child: const Icon(
                      Icons.sports_cricket_rounded,
                      color: Color(0xFF444444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No upcoming matches',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check back soon',
                    style: TextStyle(
                      color: Color(0xFF3A3A3A),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── EMPTY STATE — vertical (full tab) ───────────────────
  Widget _buildVerticalEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(12)),
              ),
              child: const Icon(
                Icons.sports_cricket_rounded,
                color: Color(0xFF3A3A3A),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No upcoming matches',
              style: TextStyle(
                color: Color(0xFFAAAAAA),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fixtures will appear here once\nthey are scheduled.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pill/chip badge header ───────────────────────────────
  // Widget _pillHeader() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF1A1A1A),
  //         borderRadius: BorderRadius.circular(50),
  //         border: Border.all(color: Colors.white.withAlpha(18)),
  //       ),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 6,
  //             height: 6,
  //             decoration: const BoxDecoration(
  //               color: Color(0xFFCC0000),
  //               shape: BoxShape.circle,
  //             ),
  //           ),
  //           const SizedBox(width: 7),
  //           const Text(
  //             'Upcoming Matches',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 12,
  //               fontWeight: FontWeight.w700,
  //               letterSpacing: 0.2,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(),
        const SizedBox(height: 12),
        previewMode
            ? SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => _skeletonCardH(),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (_, _) => _skeletonCardV(),
        ),
      ],
    );
  }

  Widget _sectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFCC0000),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Upcoming Matches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCardH() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shimmerCircle(44),
              _shimmerCircle(24),
              _shimmerCircle(44)
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shimmerBox(50, 8),
              const SizedBox(width: 30),
              _shimmerBox(50, 8)
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonCardV() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Column(
        children: [
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(5),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _shimmerCircle(62),
              _shimmerCircle(42),
              _shimmerCircle(62)
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerCircle(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: Colors.white.withAlpha(10)));

  Widget _shimmerBox(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(4)));
}

class _FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(widget.delay, () {
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
    return FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child));
  }
}