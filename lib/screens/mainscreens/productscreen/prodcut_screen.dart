import 'package:ballbyball/models/product_model.dart';
import 'package:ballbyball/providers/product_provider.dart';
import 'package:ballbyball/screens/mainscreens/productscreen/product_detils_screen.dart'
    show ProductDetailScreen;
import 'package:ballbyball/service/shop_banner_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../service/app_analytics.dart';

// ─────────────────────────────────────────────────────────
//  DESIGN SYSTEM
// ─────────────────────────────────────────────────────────
const _bg      = Color(0xFF060606);
const _surface = Color(0xFF0D0D0D);
const _raised  = Color(0xFF131313);
const _line    = Color(0xFF1C1C1C);
const _muted   = Color(0xFF2A2A2A);
const _red     = Color(0xFFCC0000);
const _redDim  = Color(0xFF3D0000);

const _srcTint = {
  'amazon':   Color(0xFFFF9900),
  'flipkart': Color(0xFF4285F4),
  'myntra':   Color(0xFFFF3F6C),
  'other':    Color(0xFF666666),
};
const _srcName = {
  'amazon': 'Amazon', 'flipkart': 'Flipkart',
  'myntra': 'Myntra', 'other': 'Store',
};
const _catName = {
  'all': 'All', 'bat': 'Bat', 'ball': 'Ball',
  'gloves': 'Gloves', 'pads': 'Pads', 'shoes': 'Shoes',
  'helmet': 'Helmet', 'kit': 'Kit', 'accessories': 'Accessories',
};

const double _cardH = 280;
const double _imgH  = 168;

// ══════════════════════════════════════════════════════════
//  ROOT
// ══════════════════════════════════════════════════════════
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  // Banner is loaded independently — never blocks product load
  late Future<ShopBanner> _bannerFuture;

  @override
  void initState() {
    super.initState();
    _bannerFuture = ShopBannerService.fetchActiveBanner();
    WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.read<ShopProvider>().init());

    AppAnalytics.screenNews();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: SafeArea(top: true,
        child: Scaffold(
          backgroundColor: _bg,
          body: Consumer<ShopProvider>(
            builder: (_, p, _) {
              if (p.isLoading) return const _Shimmer();
              if (p.error != null) {
                return _ErrorState(msg: p.error!, onRetry: p.init);
              }
              return _Body(p: p, bannerFuture: _bannerFuture);
            },
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  BODY
// ══════════════════════════════════════════════════════════
class _Body extends StatelessWidget {
  final ShopProvider p;
  final Future<ShopBanner> bannerFuture;
  const _Body({required this.p, required this.bannerFuture});

  @override
  Widget build(BuildContext context) {
    final prods = p.products;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [

        SliverToBoxAdapter(child: _Header(p: p)),


        SliverToBoxAdapter(
          child: _FestivalBannerSlot(future: bannerFuture),
        ),


        SliverPersistentHeader(
            pinned: true, delegate: _CatStrip(p: p)),


        if (p.trendingProducts.isNotEmpty &&
            p.selectedCategory == 'all' &&
            !p.trendingOnly)
          SliverToBoxAdapter(
              child: _FeaturedBanner(items: p.trendingProducts)),

        // ── Toolbar ─────────────────────────────────────
        SliverToBoxAdapter(
            child: _Toolbar(p: p, count: prods.length)),

        // ── Grid ────────────────────────────────────────
        prods.isEmpty
            ? const SliverFillRemaining(
            hasScrollBody: false, child: _EmptyState())
            : SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 60),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (_, i) => _ProductCard(product: prods[i]),
              childCount: prods.length,
            ),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: _cardH,
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════
//  FESTIVAL BANNER SLOT  — async, non-blocking
// ══════════════════════════════════════════════════════════
class _FestivalBannerSlot extends StatelessWidget {
  final Future<ShopBanner> future;
  const _FestivalBannerSlot({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShopBanner>(
      future: future,
      builder: (_, snap) {
        // Still loading — show a slim animated placeholder
        if (snap.connectionState != ConnectionState.done) {
          return const _BannerSkeleton();
        }

        final banner = snap.data;

        // No banner / inactive — render nothing (zero height)
        if (banner == null || !banner.isActive) {
          return const SizedBox.shrink();
        }

        return _FestivalBannerCard(banner: banner);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
//  FESTIVAL BANNER CARD
// ══════════════════════════════════════════════════════════
class _FestivalBannerCard extends StatelessWidget {
  final ShopBanner banner;
  const _FestivalBannerCard({required this.banner});

  static const double _h = 190.0;

  @override
  Widget build(BuildContext context) {
    final accent = banner.accentColor;
    final hasImage = banner.imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: _h,
          child: Stack(
            fit: StackFit.expand,
            children: [

              // ── 1. Background: network image OR gradient ─
              if (hasImage)
                CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  // Smooth fade-in
                  fadeInDuration: const Duration(milliseconds: 400),
                  placeholder: (_, __) => _GradientBg(accent: accent),
                  errorWidget: (_, __, ___) => _GradientBg(accent: accent),
                )
              else
                _GradientBg(accent: accent),

              // ── 2. Dark scrim so text is always legible ──
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(120),
                      Colors.black.withAlpha(210),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),

              // ── 3. Subtle accent glow (bottom-left) ─────
              Positioned(
                bottom: -30, left: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withAlpha(35),
                  ),
                ),
              ),

              // ── 4. Content ───────────────────────────────
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    // Badge pill
                    if (banner.badgeText.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          banner.badgeText.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Title
                    Text(
                      banner.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      banner.subtitle,
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CTA button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Shop Now',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── 5. Top-right decorative cricket icon ─────
              Positioned(
                top: 18, right: 18,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withAlpha(20)),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏏',
                      style: TextStyle(fontSize: 20)),
                ),
              ),

              // ── 6. Border ────────────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color: accent.withAlpha(60), width: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gradient fallback background ──────────────────────────
class _GradientBg extends StatelessWidget {
  final Color accent;
  const _GradientBg({required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            accent.withAlpha(80),
            accent.withAlpha(30),
            _surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ── Skeleton placeholder while banner loads ───────────────
class _BannerSkeleton extends StatefulWidget {
  const _BannerSkeleton();
  @override State<_BannerSkeleton> createState() => _BannerSkeletonState();
}

class _BannerSkeletonState extends State<_BannerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.03, end: 0.07)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Container(
          height: 190,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_a.value),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  HEADER
// ══════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final ShopProvider p;
  const _Header({required this.p});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 18, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CRICKET STORE',
                    style: TextStyle(
                        color: _red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0)),
                const SizedBox(height: 4),
                const Text('Shop',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.0)),
              ],
            ),
          ),
          Row(
            children: [
              if (p.hasActiveFilters)
                _IconBtn(
                  onTap: p.clearFilters,
                  active: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.x, size: 12, color: _red),
                      const SizedBox(width: 4),
                      const Text('Clear',
                          style: TextStyle(
                              color: _red,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              if (p.hasActiveFilters) const SizedBox(width: 8),
              _IconBtn(
                onTap: () => _openSort(context, p),
                active: p.sortBy != 'newest',
                child:  Icon(
                  LucideIcons.slidersHorizontal,
                  size: 16,
                  color: p.sortBy != 'newest'
                      ? _red
                      : Colors.white.withAlpha(80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSort(BuildContext ctx, ShopProvider p) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortSheet(p: p),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool active;
  const _IconBtn(
      {required this.child, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: active ? _redDim.withAlpha(180) : _raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active ? _red.withAlpha(80) : _line),
      ),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  CATEGORY STRIP (sticky)
// ══════════════════════════════════════════════════════════
class _CatStrip extends SliverPersistentHeaderDelegate {
  final ShopProvider p;
  _CatStrip({required this.p});

  @override double get minExtent => 52;
  @override double get maxExtent => 52;
  @override bool shouldRebuild(_CatStrip o) => true;

  @override
  Widget build(BuildContext ctx, double shrink, bool overlaps) {
    return Container(
      height: 52,
      color: _bg,
      foregroundDecoration: overlaps
          ? const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFF1A1A1A), width: 1)))
          : null,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: ShopService.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final cat = ShopService.categories[i];
          final sel = p.selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              p.setCategory(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: sel ? _red : _raised,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel ? _red : _line, width: 1),
              ),
              child: Text(
                _catName[cat] ?? cat,
                style: TextStyle(
                  color: sel ? Colors.white : Colors.white.withAlpha(110),
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  FEATURED / TRENDING BANNER (horizontal product scroll)
// ══════════════════════════════════════════════════════════
class _FeaturedBanner extends StatelessWidget {
  final List<ProductModel> items;
  const _FeaturedBanner({required this.items});

  static const double _bW = 200;
  static const double _bH = 240;
  static const double _bImgH = 150;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                  width: 2,
                  height: 16,
                  color: _red,
                  margin: const EdgeInsets.only(right: 10)),
              const Text('TRENDING NOW',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: _bH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: items.take(8).length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _BannerCard(
                product: items[i], w: _bW, h: _bH, imgH: _bImgH),
          ),
        ),
        const SizedBox(height: 22),
        Container(height: 1, color: _line),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final ProductModel product;
  final double w, h, imgH;
  const _BannerCard(
      {required this.product,
        required this.w,
        required this.h,
        required this.imgH});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product)));
      },
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
              ),
            ),
            Positioned(
              top: 0, left: 0, right: 0, height: imgH,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(17)),
                child: _NetImg(url: product.image),
              ),
            ),
            Positioned(
              top: imgH - 50, left: 0, right: 0, height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_surface, _surface.withAlpha(0)],
                  ),
                ),
              ),
            ),
            if (product.discount > 0)
              Positioned(
                  top: 10, left: 10,
                  child: _DiscountBadge(pct: product.discount)),
            Positioned(
                top: 10, right: 10,
                child: _SourceDot(source: product.source)),
            Positioned(
              top: imgH + 10, left: 12, right: 12, height: 32,
              child: Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.4)),
            ),
            Positioned(
              bottom: 12, left: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  if (product.originalPrice > product.price) ...[
                    const SizedBox(width: 6),
                    Text('₹${product.originalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Color(0xFF3A3A3A),
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFF3A3A3A))),
                  ],
                ],
              ),
            ),
            if (!product.inStock)
              Positioned(
                top: 0, left: 0, right: 0, height: imgH,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17)),
                  child: Container(
                    color: Colors.black.withAlpha(140),
                    alignment: Alignment.center,
                    child: const _OosBadge(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _Toolbar extends StatelessWidget {
  final ShopProvider p;
  final int count;
  const _Toolbar({required this.p, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Text('$count products',
              style: TextStyle(
                  color: Colors.white.withAlpha(40),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              p.toggleTrending();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: p.trendingOnly
                    ? Colors.orange.withAlpha(20)
                    : _raised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: p.trendingOnly
                        ? Colors.orange.withAlpha(70)
                        : _line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text('Trending',
                      style: TextStyle(
                          color: p.trendingOnly
                              ? Colors.orange
                              : Colors.white.withAlpha(60),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final srcTint = _srcTint[product.source] ?? const Color(0xFF666666);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product)));
      },
      child: SizedBox(
        width: double.infinity,
        height: _cardH,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
              ),
            ),
            Positioned(
              top: 0, left: 0, right: 0, height: _imgH,
              child: ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(17)),
                child: _NetImg(url: product.image),
              ),
            ),
            Positioned(
              top: _imgH - 56, left: 0, right: 0, height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_surface, _surface.withAlpha(0)],
                  ),
                ),
              ),
            ),
            if (product.discount > 0)
              Positioned(
                  top: 10, left: 10,
                  child: _DiscountBadge(pct: product.discount)),
            Positioned(
                top: 10, right: 10,
                child: _SourceDot(source: product.source)),
            if (!product.inStock)
              Positioned(
                top: 0, left: 0, right: 0, height: _imgH,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17)),
                  child: Container(
                    color: Colors.black.withAlpha(150),
                    alignment: Alignment.center,
                    child: const _OosBadge(),
                  ),
                ),
              ),
            if (product.isTrending)
              Positioned(
                top: _imgH - 20, right: 10,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: _line),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔥',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            Positioned(
              top: _imgH + 10, left: 12, right: 12, height: 36,
              child: Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4)),
            ),
            Positioned(
              top: _imgH + 50, left: 12,
              child: product.rating > 0
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.star,
                      size: 9, color: Color(0xFFFFB800)),
                  const SizedBox(width: 3),
                  Text(product.rating.toStringAsFixed(1),
                      style: TextStyle(
                          color: Colors.white.withAlpha(80),
                          fontSize: 10,
                          fontWeight: FontWeight.w500)),
                ],
              )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              bottom: 14, left: 12, right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (product.originalPrice > product.price)
                        Text('₹${product.originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Color(0xFF444444))),
                      Text('₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: srcTint.withAlpha(20),
                      shape: BoxShape.circle,
                      border: Border.all(color: srcTint.withAlpha(60)),
                    ),
                    child: Center(
                      child: Icon(LucideIcons.externalLink,
                          size: 10, color: srcTint),
                    ),
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


class _SortSheet extends StatelessWidget {
  final ShopProvider p;
  const _SortSheet({required this.p});

  static const _opts = [
    ('newest',     'Newest First',       LucideIcons.sparkles),
    ('price_low',  'Price: Low → High',  LucideIcons.trendingDown),
    ('price_high', 'Price: High → Low',  LucideIcons.trendingUp),
    ('rating',     'Top Rated',          LucideIcons.star),
    ('discount',   'Best Discount',      LucideIcons.tag),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _line),
      ),
      padding: EdgeInsets.fromLTRB(22, 14, 22, bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: _muted, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Sort by',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${_opts.length} options',
                  style: TextStyle(
                      color: Colors.white.withAlpha(30), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          ..._opts.map((o) {
            final sel = p.sortBy == o.$1;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                p.setSortBy(o.$1);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sel ? _redDim.withAlpha(200) : _raised,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel ? _red.withAlpha(80) : _line),
                ),
                child: Row(
                  children: [
                    Icon(o.$3,
                        size: 16,
                        color: sel ? _red : Colors.white.withAlpha(45)),
                    const SizedBox(width: 14),
                    Text(o.$2,
                        style: TextStyle(
                            color: sel
                                ? Colors.white
                                : Colors.white.withAlpha(160),
                            fontSize: 13,
                            fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400)),
                    const Spacer(),
                    if (sel)
                      Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                            color: _red, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.check,
                            size: 11, color: Colors.white),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  SHIMMER
// ══════════════════════════════════════════════════════════
class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.03, end: 0.08)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  Widget _box(double w, double h, double r) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_a.value),
        borderRadius: BorderRadius.circular(r),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: top > 0 ? 0 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _box(50, 10, 4),
                  const SizedBox(height: 6),
                  _box(100, 24, 6),
                ],
              ),
            ),
            // Banner skeleton in shimmer too
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: _box(double.infinity, 190, 22),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: 7,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (_, _) => _box(65, 30, 20),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: _cardH,
                ),
                itemCount: 6,
                itemBuilder: (_, __) =>
                    _box(double.infinity, _cardH, 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DiscountBadge extends StatelessWidget {
  final int pct;
  const _DiscountBadge({required this.pct});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: _red, borderRadius: BorderRadius.circular(6)),
      child: Text('$pct% off',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2)));
}

class _SourceDot extends StatelessWidget {
  final String source;
  const _SourceDot({required this.source});
  @override
  Widget build(BuildContext context) {
    final c = _srcTint[source] ?? const Color(0xFF666666);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(130),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Text(_srcName[source] ?? 'Store',
          style: TextStyle(
              color: c,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2)),
    );
  }
}

class _OosBadge extends StatelessWidget {
  const _OosBadge();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _line)),
      child: const Text('Out of Stock',
          style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              fontWeight: FontWeight.w700)));
}

class _NetImg extends StatelessWidget {
  final String url;
  const _NetImg({required this.url});
  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: const Color(0xFF141414)),
      errorWidget: (_, _, _) => _fallback(),
    );
  }
  Widget _fallback() => Container(
      color: const Color(0xFF141414),
      child: Icon(LucideIcons.shoppingBag,
          size: 32, color: Colors.white.withAlpha(8)));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.packageSearch,
            size: 44, color: Colors.white.withAlpha(12)),
        const SizedBox(height: 16),
        const Text('Nothing here',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Try a different category or filter',
            style: TextStyle(
                color: Colors.white.withAlpha(30), fontSize: 13)),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrorState({required this.msg, required this.onRetry});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.wifiOff,
              size: 40, color: Colors.white.withAlpha(15)),
          const SizedBox(height: 16),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withAlpha(45), fontSize: 13)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Try Again',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}