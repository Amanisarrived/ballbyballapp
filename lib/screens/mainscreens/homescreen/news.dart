import 'package:ballbyball/providers/news_provider.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/news_card.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/news_detils_screen.dart';
import 'package:ballbyball/service/app_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class News extends StatefulWidget {
  final ScrollController? scrollController;
  const News({super.key, this.scrollController});

  @override
  State<News> createState() => _NewsState();
}

class _NewsState extends State<News> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().loadNews();
    });

    AppAnalytics.screenNews();
  }

  void _open(BuildContext ctx, news) {
    Navigator.push(
      ctx,
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => NewsDetailScreen(news: news),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const _NewsShimmer();

        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: Colors.white24, size: 44),
                const SizedBox(height: 14),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => provider.loadNews(forceRefresh: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 11),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: Colors.white.withAlpha(28)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Retry',
                        style:
                        TextStyle(color: Colors.white60, fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.news.isEmpty) {
          return const Center(
            child: Text('No news available',
                style: TextStyle(color: Colors.white38)),
          );
        }

        final featured = provider.featuredNews;
        final rest = provider.remainingNews;

        return CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () => provider.loadNews(forceRefresh: true),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Section header ─────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCC0000),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                const Text(
                                  'Latest News',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                'Cricket updates & analysis',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(40),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withAlpha(12)),
                          ),
                          child: Text(
                            '${provider.news.length} articles',
                            style: TextStyle(
                              color: Colors.white.withAlpha(45),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Featured card ──────────────────────
                  if (featured.isNotEmpty)
                    _FadeIn(
                      delay: Duration.zero,
                      child: GestureDetector(
                        onTap: () => _open(context, featured.first),
                        child: FeaturedNewsCard(news: featured.first),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // ── "More Stories" divider ─────────────
                  if (rest.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Text(
                            'MORE STORIES',
                            style: TextStyle(
                              color: Color(0xFFCC0000),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 0.5,
                              color: Colors.white.withAlpha(12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (rest.isNotEmpty) const SizedBox(height: 4),

                  // ── Remaining cards ────────────────────
                  ...rest.asMap().entries.map(
                        (e) => _FadeIn(
                      delay: Duration(milliseconds: 60 + e.key * 55),
                      child: GestureDetector(
                        onTap: () => _open(context, e.value),
                        child: NewsCard(
                          news: e.value,
                          showDivider: e.key < rest.length - 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────
class _NewsShimmer extends StatefulWidget {
  const _NewsShimmer();
  @override
  State<_NewsShimmer> createState() => _NewsShimmerState();
}

class _NewsShimmerState extends State<_NewsShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.25, end: 0.55).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Header shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Container(
                    width: 3,
                    height: 16,
                    color: Colors.white.withOpacity(_anim.value * 0.4)),
                const SizedBox(width: 9),
                Container(
                    width: 110,
                    height: 16,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_anim.value * 0.2),
                        borderRadius: BorderRadius.circular(6))),
              ]),
            ),
            const SizedBox(height: 18),

            // Featured skeleton
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 310,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_anim.value * 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 28),

            // "More stories" line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                  width: 90,
                  height: 8,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_anim.value * 0.12),
                      borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 8),

            // List skeletons
            ...List.generate(
              4,
                  (i) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 88,
                        height: 74,
                        decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(_anim.value * 0.12),
                            borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 13,
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(_anim.value * 0.15),
                                  borderRadius: BorderRadius.circular(5))),
                          const SizedBox(height: 7),
                          Container(
                              width: 150,
                              height: 13,
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(_anim.value * 0.15),
                                  borderRadius: BorderRadius.circular(5))),
                          const SizedBox(height: 10),
                          Container(
                              width: 80,
                              height: 9,
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(_anim.value * 0.08),
                                  borderRadius: BorderRadius.circular(4))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fade-in ───────────────────────────────────────────────
class _FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeIn({required this.child, required this.delay});
  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(
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
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}