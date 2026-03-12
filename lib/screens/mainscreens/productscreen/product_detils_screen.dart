import 'package:ballbyball/models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

const _bg      = Color(0xFF060606);
const _surface = Color(0xFF0D0D0D);
const _line    = Color(0xFF1C1C1C);
const _red     = Color(0xFFCC0000);

const _srcColor = {
  'amazon':   Color(0xFFFF9900),
  'flipkart': Color(0xFF4285F4),
  'myntra':   Color(0xFFFF3F6C),
  'other':    Color(0xFF888888),
};
const _srcLabel = {
  'amazon': 'Amazon', 'flipkart': 'Flipkart',
  'myntra': 'Myntra', 'other': 'Store',
};

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});
  @override State<ProductDetailScreen> createState() => _State();
}

class _State extends State<ProductDetailScreen> {
  final _scroll = ScrollController();
  double _scrollOffset = 0;

  ProductModel get p => widget.product;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      setState(() => _scrollOffset = _scroll.offset);
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }


  double get _appBarOpacity => (_scrollOffset - 220).clamp(0, 40) / 40;

  @override
  Widget build(BuildContext context) {
    final bottom   = MediaQuery.of(context).padding.bottom;
    final top      = MediaQuery.of(context).padding.top;
    final srcColor = _srcColor[p.source] ?? const Color(0xFF888888);
    final srcLabel = _srcLabel[p.source] ?? 'Store';
    final canBuy   = p.inStock && p.affiliateUrl.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
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
                  // Hero
                  _Hero(product: p, topPad: top),

                  // All info
                  _Info(product: p),

                  SizedBox(height: bottom + 100),
                ],
              ),
            ),

            Positioned(
              top: 0, left: 0, right: 0,
              height: top + 56,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _appBarOpacity,
                  child: Container(
                    color: _bg,
                    padding: EdgeInsets.fromLTRB(60, top + 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text('₹${p.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: _red,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ),


            Positioned(
              top: top + 10,
              left: 16,
              child: _BackButton(),
            ),

            // ── BOTTOM CTA ───────────────────────────
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _CTA(
                srcColor: srcColor,
                srcLabel: srcLabel,
                canBuy: canBuy,
                onTap: () => _launch(p.affiliateUrl),
                bottom: bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      Navigator.pop(context);
    },
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: const Icon(LucideIcons.arrowLeft,
          color: Colors.white, size: 17),
    ),
  );
}

class _Hero extends StatelessWidget {
  final ProductModel product;
  final double topPad;
  const _Hero({required this.product, required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [

          product.image.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: product.image,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                Container(color: const Color(0xFF111111)),
            errorWidget: (_, _, _) => _ImgFallback(),
          )
              : _ImgFallback(),

          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(80),
                  Colors.transparent,
                  _bg.withAlpha(200),
                  _bg,
                ],
                stops: const [0.0, 0.35, 0.80, 1.0],
              ),
            ),
          ),


          Positioned(
            bottom: 20, left: 18,
            child: Wrap(
              spacing: 7, runSpacing: 7,
              children: [
                if (product.discount > 0)
                  _Badge(
                      text: '${product.discount}% OFF',
                      bg: _red,
                      fg: Colors.white),
                if (product.isTrending)
                  _Badge(
                      text: '🔥 Trending',
                      bg: Colors.orange.withAlpha(230),
                      fg: Colors.white),
                if (!product.inStock)
                  _Badge(
                      text: 'Out of Stock',
                      bg: const Color(0xFF1E1E1E),
                      fg: const Color(0xFF777777)),
              ],
            ),
          ),


          Positioned(
            top: topPad + 12, right: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(130),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: Colors.white.withAlpha(12)),
              ),
              child: Text(_capitalize(product.category),
                  style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImgFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFF111111),
      child: Icon(LucideIcons.shoppingBag,
          size: 64, color: Colors.white.withAlpha(8)));
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Badge({required this.text, required this.bg, required this.fg});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2)));
}


class _Info extends StatelessWidget {
  final ProductModel product;
  const _Info({required this.product});

  @override
  Widget build(BuildContext context) {
    final srcColor = _srcColor[product.source] ?? const Color(0xFF888888);
    final srcLabel = _srcLabel[product.source] ?? 'Store';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          Text(product.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.5)),

          const SizedBox(height: 6),


          if (product.rating > 0)
            Row(
              children: [
                ...List.generate(5, (i) {
                  final filled = i < product.rating.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: filled
                        ? const Color(0xFFFFB800)
                        : Colors.white.withAlpha(20),
                  );
                }),
                const SizedBox(width: 6),
                Text(product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Color(0xFFFFB800),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                Text('/ 5',
                    style: TextStyle(
                        color: Colors.white.withAlpha(30),
                        fontSize: 11)),
              ],
            ),

          const SizedBox(height: 20),


          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('PRICE',
                          style: TextStyle(
                              color: Colors.white.withAlpha(30),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 6),
                      Text('₹${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              height: 1.0)),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${product.originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Color(0xFF3A3A3A),
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Color(0xFF3A3A3A)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withAlpha(18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFF4CAF50)
                                        .withAlpha(45)),
                              ),
                              child: Text(
                                'Save ₹${(product.originalPrice - product.price).toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),


                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: srcColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: srcColor.withAlpha(50)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.store,
                          size: 16, color: srcColor),
                      const SizedBox(height: 5),
                      Text(srcLabel,
                          style: TextStyle(
                              color: srcColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),


          Row(
            children: [
              _QuickChip(
                icon: product.inStock
                    ? LucideIcons.checkCircle
                    : LucideIcons.xCircle,
                label: product.inStock ? 'In Stock' : 'Out of Stock',
                color: product.inStock
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF666666),
              ),
              const SizedBox(width: 8),
              _QuickChip(
                icon: LucideIcons.tag,
                label: _capitalize(product.category),
                color: Colors.white.withAlpha(120),
              ),
              if (product.discount > 0) ...[
                const SizedBox(width: 8),
                _QuickChip(
                  icon: LucideIcons.percent,
                  label: '${product.discount}% off',
                  color: _red,
                ),
              ],
            ],
          ),


          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 28),
            _SectionHead('About this product'),
            const SizedBox(height: 12),
            Text(product.description,
                style: TextStyle(
                    color: Colors.white.withAlpha(130),
                    fontSize: 14,
                    height: 1.75)),
          ],


          const SizedBox(height: 28),
          _SectionHead('Product Details'),
          const SizedBox(height: 12),
          _DetailsTable(product: product),


          const SizedBox(height: 28),
          _SectionHead('Why buy from $_appName?'),
          const SizedBox(height: 12),
          _WhyBuy(),
        ],
      ),
    );
  }
}


class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _QuickChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 5),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );
}


class _SectionHead extends StatelessWidget {
  final String text;
  const _SectionHead(this.text);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
          width: 2,
          height: 14,
          color: _red,
          margin: const EdgeInsets.only(right: 8)),
      Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700)),
    ],
  );
}


class _DetailsTable extends StatelessWidget {
  final ProductModel product;
  const _DetailsTable({required this.product});

  @override
  Widget build(BuildContext context) {
    final srcColor = _srcColor[product.source] ?? const Color(0xFF888888);
    final rows = [
      ('Category',     _capitalize(product.category), null),
      ('Sold on',      _srcLabel[product.source] ?? 'Store', srcColor),
      ('Currency',     product.currency, null),
      if (product.discount > 0)
        ('Discount',   '${product.discount}% off', _red),
      ('Availability', product.inStock ? 'In Stock' : 'Out of Stock',
      product.inStock ? const Color(0xFF4CAF50) : const Color(0xFF666666)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(rows[i].$1,
                          style: TextStyle(
                              color: Colors.white.withAlpha(35),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: Text(rows[i].$2,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: rows[i].$3 ??
                                  Colors.white.withAlpha(180),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Container(height: 1, color: _line),
            ],
          ],
        ),
      ),
    );
  }
}


class _WhyBuy extends StatelessWidget {
  static const _points = [
    (LucideIcons.shieldCheck, 'Verified affiliate links only'),
    (LucideIcons.truck,        'Delivered by trusted platforms'),
    (LucideIcons.refreshCcw,   'Easy returns via the seller'),
    (LucideIcons.lock,         'Secure checkout on partner site'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _points.map((pt) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _red.withAlpha(14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(pt.$1, size: 14, color: _red),
              ),
              const SizedBox(width: 12),
              Text(pt.$2,
                  style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}


class _CTA extends StatefulWidget {
  final Color srcColor;
  final String srcLabel;
  final bool canBuy;
  final VoidCallback onTap;
  final double bottom;
  const _CTA({
    required this.srcColor,
    required this.srcLabel,
    required this.canBuy,
    required this.onTap,
    required this.bottom,
  });
  @override State<_CTA> createState() => _CTAState();
}

class _CTAState extends State<_CTA> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, widget.bottom + 14),
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(top: BorderSide(color: Color(0xFF161616))),
      ),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.canBuy) return;
          HapticFeedback.mediumImpact();
          setState(() => _pressed = true);
        },
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.canBuy ? widget.onTap : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 56,
            decoration: BoxDecoration(
              color: widget.canBuy
                  ? widget.srcColor
                  : const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.canBuy && !_pressed
                  ? [
                BoxShadow(
                    color: widget.srcColor.withAlpha(70),
                    blurRadius: 20,
                    offset: const Offset(0, 5))
              ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.canBuy
                      ? LucideIcons.externalLink
                      : LucideIcons.xCircle,
                  size: 18,
                  color: widget.canBuy
                      ? Colors.white
                      : const Color(0xFF3A3A3A),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.canBuy
                      ? 'Buy on ${widget.srcLabel}'
                      : 'Currently Unavailable',
                  style: TextStyle(
                    color: widget.canBuy
                        ? Colors.white
                        : const Color(0xFF3A3A3A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                if (widget.canBuy) ...[
                  const SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight,
                      size: 16,
                      color: Colors.white.withAlpha(180)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


const _appName = 'BallByBall';

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

Future<void> _launch(String url) async {
  if (url.isEmpty) return;
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}