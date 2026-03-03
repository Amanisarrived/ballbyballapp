import 'package:ballbyball/screens/splashscreen/splash_screen.dart';
import 'package:ballbyball/service/notification_prefrence.dart';
import 'package:ballbyball/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../service/app_analytics.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> with TickerProviderStateMixin {
  int _deniedCount = 0;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _bellController;
  late AnimationController _pulseController;
  late AnimationController _spinController;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bellSwing;
  late Animation<double> _pulseAnim;
  late Animation<double> _spinAnim;

  final List<Map<String, String>> _messages = [
    {
      'title': 'Stay Updated!',
      'subtitle':
      'Get live cricket scores, match alerts & breaking news instantly.',
    },
    {
      'title': "You're Missing Out!",
      'subtitle':
      'Live match alerts, wickets & boundaries — all in real time. Don\'t miss a ball!',
    },
    {
      'title': 'Last Chance!',
      'subtitle':
      'Enable notifications to never miss a match moment. We promise not to spam!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDeniedCount();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
        );

    _bellSwing = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _spinAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _spinController,
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), _startBellLoop);

    // ── Analytics: screen view ───────────────────────────
    AppAnalytics.screenView('notification_permission');
  }

  void _startBellLoop() async {
    while (mounted) {
      await _bellController.forward();
      await _bellController.reverse();
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Future<void> _loadDeniedCount() async {
    final count = await NotificationPreference.getDeniedCount();
    setState(() => _deniedCount = count);

    // ── Analytics: track which prompt version user sees ──
    AppAnalytics.tapButton(
      'notification_prompt_shown',
      extra: 'attempt_${count + 1}',
    );
  }

  Map<String, String> get _currentMessage {
    final index = _deniedCount.clamp(0, _messages.length - 1);
    return _messages[index];
  }

  void _goToSplash() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SplashScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _onAllow() async {
    setState(() => _isLoading = true);

    // ── Analytics: user allowed notifications ────────────
    await AppAnalytics.tapButton(
      'notification_allowed',
      screen: 'notification_permission',
      extra: 'attempt_${_deniedCount + 1}',
    );

    await NotificationService().init();
    await NotificationPreference.saveGranted();
    if (mounted) _goToSplash();
  }

  Future<void> _onNotNow() async {
    // ── Analytics: user denied notifications ─────────────
    await AppAnalytics.tapButton(
      _deniedCount >= 2 ? 'notification_no_thanks' : 'notification_not_now',
      screen: 'notification_permission',
      extra: 'attempt_${_deniedCount + 1}',
    );

    await NotificationPreference.saveDenied();
    if (mounted) _goToSplash();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bellController.dispose();
    _pulseController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [

          // ── Pitch line background (matches splash) ──────
          Positioned.fill(
            child: CustomPaint(painter: _PitchPainter()),
          ),

          // ── Red glow top ────────────────────────────────
          Positioned(
            top: -80,
            left: size.width * 0.5 - 180,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFCC0000).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom glow ─────────────────────────────────
          Positioned(
            bottom: -60,
            left: size.width * 0.5 - 150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFCC0000).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Animated bell icon ───────────────
                      AnimatedBuilder(
                        animation:
                        Listenable.merge([_bellSwing, _pulseAnim]),
                        builder: (_, __) => Transform.rotate(
                          angle: _bellSwing.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer pulse ring
                              Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFCC0000)
                                          .withOpacity(0.12),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              // Inner circle
                              Container(
                                width: 114,
                                height: 114,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF111111),
                                  border: Border.all(
                                    color: const Color(0xFFCC0000)
                                        .withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFCC0000)
                                          .withOpacity(0.2),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              // Bell
                              const Icon(
                                Icons.notifications_active_rounded,
                                size: 52,
                                color: Color(0xFFCC0000),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Title ────────────────────────────
                      Text(
                        _currentMessage['title']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      // ── Red accent dots ──────────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFCC0000),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Subtitle ─────────────────────────
                      Text(
                        _currentMessage['subtitle']!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 14,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // ── Feature pills ────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeaturePill(
                              icon: Icons.sports_cricket,
                              label: 'Live Scores'),
                          _FeaturePill(
                              icon: Icons.bolt_rounded,
                              label: 'Wicket Alerts'),
                          _FeaturePill(
                              icon: Icons.newspaper_rounded,
                              label: 'Breaking News'),
                        ],
                      ),

                      const Spacer(flex: 2),

                      // ── Spinning ball (same as splash) ───
                      AnimatedBuilder(
                        animation: _spinAnim,
                        builder: (_, __) => Transform.rotate(
                          angle: _spinAnim.value,
                          child: Image.asset(
                            'assets/spin.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Allow button ─────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCC0000),
                            padding:
                            const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _onAllow,
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Allow Notifications",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Not Now button ───────────────────
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : _onNotNow,
                          child: Text(
                            _deniedCount >= 2 ? "No Thanks" : "Not Now",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 14,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature pill widget ──────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCC0000).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFCC0000)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cricket pitch painter (same as splash) ───────────────
class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;

    for (int i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    paint.color = Colors.white.withOpacity(0.04);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    paint
      ..color = const Color(0xFFCC0000).withOpacity(0.06)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.72),
      Offset(size.width * 0.85, size.height * 0.72),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.28),
      Offset(size.width * 0.85, size.height * 0.28),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}