import 'package:ballbyball/screens/notificationscreen/notification_setting_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';


const _bg      = Color(0xFF060606);
const _surface = Color(0xFF0D0D0D);
const _raised  = Color(0xFF131313);
const _card    = Color(0xFF111111);
const _line    = Color(0xFF1C1C1C);
const _red     = Color(0xFFCC0000);
const _redDim  = Color(0xFF2A0000);

const _appName        = 'BallByBall';
const _appVersion     = '1.0.0';
const _playStoreUrl   = 'https://play.google.com/store/apps/details?id=com.ballbyball';
const _privacyUrl     = 'https://sites.google.com/view/ballbyballaman/home';
const _termsUrl       = 'https://ballbyball.com/terms';
const _contactEmail   = 'ballbyballoffical@gmail.com';
const _instagramUrl   = 'https://www.instagram.com/ballbyballoffical.app/';



class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: _ProfileBanner()),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  _Section(
                    label: 'APP',
                    items: [
                      _Tile(
                        icon: LucideIcons.star,
                        iconBg: const Color(0xFFFF9900),
                        title: 'Rate Us',
                        subtitle: 'Love the app? Drop a 5★',
                        onTap: () => _launch(_playStoreUrl),
                        trailing: _Arrow(),
                      ),
                      _Tile(
                        icon: LucideIcons.share2,
                        iconBg: const Color(0xFF4B8BF5),
                        title: 'Share App',
                        subtitle: 'Tell your cricket friends',
                        onTap: () => _shareApp(context),
                        trailing: _Arrow(),
                      ),
                      _Tile(
                        icon: LucideIcons.bell,
                        iconBg: const Color(0xFF8B5CF6),
                        title: 'Notifications',
                        subtitle: 'Match alerts & news updates',
                        onTap: () => showNotificationSettings(context),
                        trailing: _Arrow(),
                      ),
                    ],
                  ),


                  _Section(
                    label: 'LEGAL',
                    items: [
                      _Tile(
                        icon: LucideIcons.shield,
                        iconBg: const Color(0xFF10B981),
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: () => _launch(_privacyUrl),
                        trailing: _Arrow(),
                      ),
                      _Tile(
                        icon: LucideIcons.fileText,
                        iconBg: const Color(0xFF6366F1),
                        title: 'Terms of Service',
                        subtitle: 'Rules & usage guidelines',
                        onTap: () => _launch(_termsUrl),
                        trailing: _Arrow(),
                      ),
                    ],
                  ),


                  _Section(
                    label: 'CONNECT',
                    items: [
                      _Tile(
                        icon: LucideIcons.mail,
                        iconBg: _red,
                        title: 'Contact Us',
                        subtitle: _contactEmail,
                        onTap: () => _launch('mailto:$_contactEmail'),
                        trailing: _Arrow(),
                      ),
                      _Tile(
                        icon: LucideIcons.instagram,
                        iconBg: const Color(0xFFE1306C),
                        title: 'Instagram',
                        subtitle: '@ballbyball',
                        onTap: () => _launch(_instagramUrl),
                        trailing: _Arrow(),
                      ),
                    ],
                  ),


                  _Section(
                    label: 'ABOUT',
                    items: [
                      _Tile(
                        icon: LucideIcons.info,
                        iconBg: const Color(0xFF374151),
                        title: 'App Version',
                        subtitle: _appVersion,
                        onTap: null,
                        trailing: _VersionBadge(),
                      ),
                    ],
                  ),

                  _Footer(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREFERENCES',
              style: TextStyle(
                  color: _red,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0)),
          const SizedBox(height: 4),
          const Text('Settings',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  height: 1.0)),
        ],
      ),
    );
  }
}


class _ProfileBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: _redDim,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _red.withAlpha(60)),
            ),
            child:  Center(
              child: Image.asset("assets/bb51.png")
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(_appName,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3)),
                const SizedBox(height: 3),
                Text('Live Scores · Highlights · News',
                    style: TextStyle(
                        color: Colors.white.withAlpha(50),
                        fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _red.withAlpha(18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _red.withAlpha(40)),
                  ),
                  child: Text('v$_appVersion',
                      style: const TextStyle(
                          color: _red,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _Section extends StatelessWidget {
  final String label;
  final List<_Tile> items;
  const _Section({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(label,
                style: TextStyle(
                    color: Colors.white.withAlpha(35),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8)),
          ),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _line),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    items[i],
                    if (i < items.length - 1)
                      Container(
                          height: 1,
                          margin: const EdgeInsets.only(left: 60),
                          color: _line),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _Tile extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget trailing;

  const _Tile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.trailing,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap == null) return;
        setState(() => _pressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed
            ? Colors.white.withAlpha(6)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: widget.iconBg.withAlpha(220),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon,
                  size: 17, color: Colors.white),
            ),
            const SizedBox(width: 14),


            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle,
                      style: TextStyle(
                          color: Colors.white.withAlpha(45),
                          fontSize: 12)),
                ],
              ),
            ),

            // Trailing
            widget.trailing,
          ],
        ),
      ),
    );
  }
}


class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Icon(
    LucideIcons.chevronRight,
    size: 16,
    color: Colors.white.withAlpha(25),
  );
}

class _VersionBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _raised,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: _line),
    ),
    child: Text(_appVersion,
        style: TextStyle(
            color: Colors.white.withAlpha(40),
            fontSize: 11,
            fontWeight: FontWeight.w600)),
  );
}


class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        children: [
          // Cricket ball divider
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('🏏',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha(40))),
              ),
              Expanded(child: Container(height: 1, color: _line)),
            ],
          ),

          const SizedBox(height: 20),

          Text(_appName,
              style: TextStyle(
                  color: Colors.white.withAlpha(20),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),

          const SizedBox(height: 6),

          Text('Made with ❤️ for cricket fans',
              style: TextStyle(
                  color: Colors.white.withAlpha(20),
                  fontSize: 11)),

          const SizedBox(height: 6),

          Text('© 2025 $_appName · All rights reserved',
              style: TextStyle(
                  color: Colors.white.withAlpha(12),
                  fontSize: 10)),
        ],
      ),
    );
  }
}


Future<void> _launch(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Future<void> _openAppSettings() async {
  await _launch('app-settings:');
}

void _shareApp(BuildContext context) {

  Clipboard.setData(const ClipboardData(
      text:
      'Watch live cricket scores, highlights & more on $_appName!\n$_playStoreUrl'));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Link copied to clipboard!',style: TextStyle(color: Colors.white),),
      backgroundColor: _surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      duration: const Duration(seconds: 2),
    ),
  );
}