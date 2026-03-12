import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../providers/banner_provder.dart';

class BannerContainer extends StatelessWidget {
  final double height;
  final VoidCallback? onSearchTap;

  const BannerContainer({
    super.key,
    this.height = 200,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final bannerProvider = context.watch<BannerProvider>();
    final banners = bannerProvider.banners;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF1A1A1A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerProvider.isLoading || banners.isEmpty)
              _buildSkeleton(),


            if (banners.isNotEmpty)
              CachedNetworkImage(
                imageUrl: banners.first,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                fadeInDuration: const Duration(milliseconds: 400),
                placeholder: (context, url) => _buildSkeleton(),
                errorWidget: (context, url, error) => _buildErrorState(),
              ),


            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFF0A0A0A).withAlpha(100),
                      const Color(0xFF0A0A0A).withAlpha(200),
                      const Color(0xFF0A0A0A),
                    ],
                    stops: const [0.0, 0.45, 0.72, 0.88, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSkeleton() {
    return _ShimmerBox();
  }


  Widget _buildErrorState() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_cricket, size: 32, color: const Color(0xFFCC0000).withAlpha(120)),
          const SizedBox(height: 6),
          Text(
            'Banner unavailable',
            style: TextStyle(color: Colors.white.withAlpha(60), fontSize: 11),
          ),
        ],
      ),
    );
  }
}


class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF2A2A2A),
                const Color(0xFF222222),
                const Color(0xFF1A1A1A),
              ],
              stops: const [0.0, 0.4, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }
}