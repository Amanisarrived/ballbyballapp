import 'package:ballbyball/models/news_model.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/news_detils_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════
//  FEATURED CARD  — Editorial hero
// ══════════════════════════════════════════════════════════
class FeaturedNewsCard extends StatefulWidget {
  final NewsModel news;
  const FeaturedNewsCard({super.key, required this.news});
  @override
  State<FeaturedNewsCard> createState() => _FeaturedNewsCardState();
}

class _FeaturedNewsCardState extends State<FeaturedNewsCard> {
  bool _pressed = false;

  void _open() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => NewsDetailScreen(news: widget.news),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _open,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 310,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Background image ──────────────────
                  widget.news.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                    imageUrl: widget.news.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: const Color(0xFF1C1C1C)),
                    errorWidget: (_, _,_) => _imgFallback(),
                  )
                      : _imgFallback(),

                  // ── Deep editorial gradient ───────────
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.05),
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.65),
                          Colors.black.withOpacity(0.97),
                        ],
                        stops: const [0.0, 0.30, 0.62, 1.0],
                      ),
                    ),
                  ),

                  // ── Top badge row ─────────────────────
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCC0000),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TOP STORY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy')
                                .format(widget.news.createdAt),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom content block ──────────────
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Issue line / category feel
                          Text(
                            DateFormat('EEEE').format(widget.news.createdAt).toUpperCase(),
                            style: TextStyle(
                              color: const Color(0xFFCC0000).withOpacity(0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 7),

                          // Headline
                          Text(
                            widget.news.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.22,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Thin rule
                          Container(
                            height: 0.5,
                            color: Colors.white.withOpacity(0.15),
                            margin: const EdgeInsets.only(bottom: 12),
                          ),

                          // Byline + read pill
                          Row(
                            children: [
                              if (widget.news.credits.isNotEmpty) ...[
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                    const Color(0xFFCC0000).withOpacity(0.18),
                                    border: Border.all(
                                        color: const Color(0xFFCC0000)
                                            .withOpacity(0.35)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person_outline_rounded,
                                        size: 12, color: Color(0xFFCC0000)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.news.credits,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.55),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Read',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 11,
                                        color: Colors.white.withOpacity(0.8)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
    color: const Color(0xFF1C1C1C),
    child: const Center(
      child: Icon(Icons.article_outlined, color: Colors.white12, size: 48),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  COMPACT CARD  — Editorial list item
// ══════════════════════════════════════════════════════════
class NewsCard extends StatefulWidget {
  final NewsModel news;
  final bool showDivider;
  const NewsCard({super.key, required this.news, this.showDivider = true});
  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _pressed = false;

  void _open() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, _) => NewsDetailScreen(news: widget.news),
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
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: _open,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            color: _pressed ? Colors.white.withAlpha(5) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail ─────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 74,
                    child: widget.news.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: widget.news.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: const Color(0xFF1A1A1A)),
                      errorWidget: (_, _, _) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Icon(Icons.article_outlined,
                            color: Colors.white12, size: 22),
                      ),
                    )
                        : Container(
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.article_outlined,
                          color: Colors.white12, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Text block ────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.news.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          height: 1.38,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          if (widget.news.credits.isNotEmpty) ...[
                            Text(
                              widget.news.credits,
                              style: TextStyle(
                                color: Colors.white.withAlpha(65),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 6),
                              child: Container(
                                width: 2,
                                height: 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(35),
                                ),
                              ),
                            ),
                          ],
                          Text(
                            DateFormat('dd MMM').format(widget.news.createdAt),
                            style: TextStyle(
                              color: Colors.white.withAlpha(42),
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 9, color: Colors.white.withAlpha(18)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.showDivider)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Colors.white.withAlpha(7),
          ),
      ],
    );
  }
}