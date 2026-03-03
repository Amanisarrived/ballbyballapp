import 'package:ballbyball/models/highlights_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrendingCard extends StatelessWidget {
  final MovieModel movie;
  final int index;

  const TrendingCard({super.key, required this.movie, this.index = 0});

  Future<void> _openUrl() async {
    final uri = Uri.parse(movie.url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $uri: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openUrl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Full thumbnail
              Image.network(
                movie.getYoutubeThumbnail() ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1E1E1E),
                  child: const Icon(Icons.sports_cricket,
                      color: Colors.white12, size: 48),
                ),
              ),

              // Gradient — top for chip, bottom for title
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.25),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.25, 0.5, 1.0],
                  ),
                ),
              ),

              // Trending animated chip — top left
              Positioned(
                top: 12,
                left: 12,
                child: const _AnimatedTrendingChip(),
              ),

              // Play icon — center
              const Center(
                child: Icon(
                  Icons.play_circle_filled_rounded,
                  color: Colors.white60,
                  size: 48,
                ),
              ),

              // Title — bottom left
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Text(
                  movie.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedTrendingChip extends StatefulWidget {
  const _AnimatedTrendingChip();

  @override
  State<_AnimatedTrendingChip> createState() => _AnimatedTrendingChipState();
}

class _AnimatedTrendingChipState extends State<_AnimatedTrendingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFCC0000).withOpacity(_pulse.value),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing dot
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF3B3B).withOpacity(_pulse.value),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'TRENDING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}