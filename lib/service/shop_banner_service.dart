import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShopBanner {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color accentColor;
  final bool isActive;

  const ShopBanner({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.accentColor,
    required this.isActive,
  });

  static const ShopBanner defaultBanner = ShopBanner(
    imageUrl: '',
    title: 'Cricket Store',
    subtitle: 'Gear up for the game',
    badgeText: '',
    accentColor: Color(0xFFCC0000),
    isActive: true,
  );

  ShopBanner copyWith({bool? isActive}) {
    return ShopBanner(
      imageUrl: imageUrl,
      title: title,
      subtitle: subtitle,
      badgeText: badgeText,
      accentColor: accentColor,
      isActive: isActive ?? this.isActive,
    );
  }

  factory ShopBanner.fromFirestore(Map<String, dynamic> data) {
    return ShopBanner(
      imageUrl: data['imageUrl'] as String? ?? '',
      title: data['title'] as String? ?? 'Cricket Store',
      subtitle: data['subtitle'] as String? ?? 'Gear up for the game',
      badgeText: data['badgeText'] as String? ?? '',
      accentColor: _hexToColor(data['accentColor'] as String? ?? '#CC0000'),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  static Color _hexToColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFFCC0000);
    }
  }
}

class ShopBannerService {
  static final _db = FirebaseFirestore.instance;

  static Future<ShopBanner> fetchActiveBanner() async {
    try {
      final doc = await _db.collection('shop_banners').doc('active').get();

      if (!doc.exists || doc.data() == null) {
        return _localFestivalFallback();
      }

      final banner = ShopBanner.fromFirestore(doc.data()!);
      if (!banner.isActive)
        return ShopBanner.defaultBanner.copyWith(isActive: false);
      return banner;
    } catch (_) {
      return _localFestivalFallback();
    }
  }

  static ShopBanner _localFestivalFallback() {
    final now = DateTime.now();
    final md = now.month * 100 + now.day;

    if (md >= 1015 && md <= 1110) return _diwali;
    if (md >= 1220 && md <= 105) return _christmas;
    if (md >= 315 && md <= 410) return _holi;
    if (md >= 401 && md <= 531) return _ipl;
    if (md >= 815 && md <= 831) return _independenceDay;

    return ShopBanner.defaultBanner;
  }

  static const _diwali = ShopBanner(
    imageUrl: '',
    title: 'Diwali Sale 🪔',
    subtitle: 'Light up your cricket game',
    badgeText: 'Up to 40% off',
    accentColor: Color(0xFFFF9900),
    isActive: true,
  );

  static const _christmas = ShopBanner(
    imageUrl: '',
    title: 'Year-End Sale 🎄',
    subtitle: 'Best deals of the year',
    badgeText: 'Up to 35% off',
    accentColor: Color(0xFF10B981),
    isActive: true,
  );

  static const _holi = ShopBanner(
    imageUrl: '',
    title: 'Holi Offers 🎨',
    subtitle: 'Colorful deals on cricket gear',
    badgeText: 'Up to 30% off',
    accentColor: Color(0xFFE1306C),
    isActive: true,
  );

  static const _ipl = ShopBanner(
    imageUrl: '',
    title: 'IPL Season 🏏',
    subtitle: 'Gear up like your favourite team',
    badgeText: 'Shop the IPL edit',
    accentColor: Color(0xFF4B8BF5),
    isActive: true,
  );

  static const _independenceDay = ShopBanner(
    imageUrl: '',
    title: 'Independence Day 🇮🇳',
    subtitle: 'Proudly Indian. Play like one.',
    badgeText: 'Special offers inside',
    accentColor: Color(0xFFFF9900),
    isActive: true,
  );
}
