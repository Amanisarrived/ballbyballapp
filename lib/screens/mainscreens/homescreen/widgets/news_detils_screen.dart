import 'package:ballbyball/models/news_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Muted, low-contrast palette ───────────────────────────
const _bg       = Color(0xFF060606);
const _surface  = Color(0xFF0C0C0C);
const _raised   = Color(0xFF111111);
const _line     = Color(0xFF181818);
const _red      = Color(0xFF991111);
const _redTint  = Color(0xFF1A0808);
const _textHi   = Color(0xFFD0D0D0);
const _textMid  = Color(0xFF666666);
const _textDim  = Color(0xFF333333);

class NewsDetailScreen extends StatefulWidget {
  final NewsModel news;
  const NewsDetailScreen({super.key, required this.news});
  @override
  State<NewsDetailScreen> createState() => _State();
}

class _State extends State<NewsDetailScreen> {
  final _scroll = ScrollController();
  double _offset = 0;
  NewsModel get n => widget.news;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() => _offset = _scroll.offset));
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  double get _barOpacity => (_offset - 240).clamp(0.0, 40.0) / 40.0;

  @override
  Widget build(BuildContext context) {
    final top    = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(bottom: true,
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
        
              SingleChildScrollView(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(news: n, topPad: top),
                    _ArticleBody(news: n),
                    SizedBox(height: bottom),
                  ],
                ),
              ),
        
              // Fading top bar — non-interactive
              Positioned(
                top: 0, left: 0, right: 0,
                height: top + 52,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _barOpacity,
                    child: Container(
                      color: _bg,
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.fromLTRB(62, 0, 16, 12),
                      child: Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textHi,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        
              // Back button — last in stack = on top
              Positioned(
                top: top + 10, left: 16,
                child: _BackBtn(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  BACK BUTTON
// ══════════════════════════════════════════════════════════
class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    },
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(12)),
      ),
      child: Icon(LucideIcons.arrowLeft,
          color: Colors.white.withAlpha(180), size: 16),
    ),
  );
}

class _HeroImage extends StatelessWidget {
  final NewsModel news;
  final double topPad;
  const _HeroImage({required this.news, required this.topPad});

  @override
  Widget build(BuildContext context) {
    final hasImg = news.imageUrl.isNotEmpty;

    return SizedBox(
      height: hasImg ? 320 : topPad + 80,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image — desaturated feel via color filter
          if (hasImg)
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                0.85, 0,    0,    0, 0,
                0,    0.85, 0,    0, 0,
                0,    0,    0.85, 0, 0,
                0,    0,    0,    1, 0,
              ]),
              child: CachedNetworkImage(
                imageUrl: news.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: const Color(0xFF0E0E0E)),
                errorWidget: (_, _, _) => _NoImage(),
              ),
            )
          else
            _NoImage(),

          // Gradient — heavier, makes image feel darker
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(hasImg ? 120 : 0),
                  Colors.transparent,
                  _bg.withAlpha(230),
                  _bg,
                ],
                stops: const [0.0, 0.25, 0.72, 1.0],
              ),
            ),
          ),

          // Credits tag — muted, bottom left
          if (news.credits.isNotEmpty)
            Positioned(
              bottom: 18, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withAlpha(10)),
                ),
                child: Text(
                  news.credits,
                  style: const TextStyle(
                    color: _textMid,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFF0A0A0A),
      child: Icon(LucideIcons.newspaper,
          size: 48, color: Colors.white.withAlpha(6)));
}


class _ArticleBody extends StatelessWidget {
  final NewsModel news;
  const _ArticleBody({required this.news});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          Row(
            children: [
              Icon(LucideIcons.clock,
                  size: 10, color: Colors.white.withAlpha(22)),
              const SizedBox(width: 5),
              Text(
                _formatDate(news.createdAt),
                style: const TextStyle(color: _textDim, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 12),


          Text(
            news.title,
            style: const TextStyle(
              color: _textHi,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              height: 1.35,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 14),

          // ── CREDITS ─────────────────────────────────
          if (news.credits.isNotEmpty) ...[
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _raised,
                    shape: BoxShape.circle,
                    border: Border.all(color: _line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    news.credits[0].toUpperCase(),
                    style: const TextStyle(
                        color: _textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(news.credits,
                        style: const TextStyle(
                            color: _textHi,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    const Text('Source',
                        style: TextStyle(
                            color: _textDim, fontSize: 10)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 4),

          // Thin separator
          Container(height: 1, color: _line),
          const SizedBox(height: 20),

          // ── DESCRIPTION — pull quote ─────────────────
          if (news.description.isNotEmpty) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 2,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: _red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      news.description,
                      style: const TextStyle(
                        color: _textHi,
                        fontSize: 15,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── READ FULL STORY ──────────────────────────
          if (news.url.isNotEmpty) ...[
            // Info strip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: _redTint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(LucideIcons.newspaper,
                        size: 15, color: _red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full story available',
                            style: TextStyle(
                                color: _textHi,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        Text(
                          news.credits.isNotEmpty
                              ? 'Reported by ${news.credits}'
                              : 'Read the complete article',
                          style: const TextStyle(
                              color: _textDim, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.externalLink,
                      size: 13, color: _textDim),
                ],
              ),
            ),

            const SizedBox(height: 12),

            _ReadFullBtn(url: news.url, credits: news.credits),

            const SizedBox(height: 8),
            Center(
              child: Text(
                'Opens in your browser',
                style: TextStyle(
                    color: Colors.white.withAlpha(14), fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  CTA BUTTON
// ══════════════════════════════════════════════════════════
class _ReadFullBtn extends StatefulWidget {
  final String url, credits;
  const _ReadFullBtn({required this.url, required this.credits});
  @override
  State<_ReadFullBtn> createState() => _S();
}

class _S extends State<_ReadFullBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => _launch(widget.url),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            // Dark red — not bright
            color: _pressed
                ? const Color(0xFF0E0606)
                : const Color(0xFF120606),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: _red.withAlpha(_pressed ? 120 : 70)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.newspaper,
                  size: 16, color: _red),
              const SizedBox(width: 10),
              Text(
                widget.credits.isNotEmpty
                    ? 'Read on ${widget.credits}'
                    : 'Read full story',
                style: const TextStyle(
                  color: _textHi,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.arrowRight,
                  size: 14, color: _textDim),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  HELPERS
// ══════════════════════════════════════════════════════════
String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local  = dt.toLocal();
  final hour   = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final ampm   = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} ${local.year}  ·  $hour:$minute $ampm';
}

Future<void> _launch(String url) async {
  if (url.isEmpty) return;
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

