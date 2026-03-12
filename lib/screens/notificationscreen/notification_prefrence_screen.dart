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
        pageBuilder: (_, _, _) => const SplashScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _onAllow() async {
    setState(() => _isLoading = true);

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
          // Background pitch lines
          Positioned.fill(
            child: CustomPaint(painter: _PitchPainter()),
          ),

          // Top red glow
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
                    const Color(0xFFCC0000).withAlpha(46),  // 0.18 * 255
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom red glow
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
                    const Color(0xFFCC0000).withAlpha(20),  // 0.08 * 255
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
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

                      // Bell animation
                      AnimatedBuilder(
                        animation:
                        Listenable.merge([_bellSwing, _pulseAnim]),
                        builder: (_, _) => Transform.rotate(
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
                                          .withAlpha(31),  // 0.12 * 255
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
                                        .withAlpha(89),  // 0.35 * 255
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFCC0000)
                                          .withAlpha(51),  // 0.2 * 255
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              // Bell icon
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

                      // Title
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

                      // Dot divider
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

                      // Subtitle
                      Text(
                        _currentMessage['subtitle']!,
                        style: TextStyle(
                          color: Colors.white.withAlpha(115),  // 0.45 * 255
                          fontSize: 14,
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 28),

                      // Feature pills
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

                      // Spinning cricket ball
                      AnimatedBuilder(
                        animation: _spinAnim,
                        builder: (_, _) => Transform.rotate(
                          angle: _spinAnim.value,
                          child: Image.asset(
                            'assets/spin.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Allow button
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

                      // Not now button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : _onNotNow,
                          child: Text(
                            _deniedCount >= 2 ? "No Thanks" : "Not Now",
                            style: TextStyle(
                              color: Colors.white.withAlpha(77),  // 0.3 * 255
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

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),        // 0.04 * 255
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCC0000).withAlpha(51),  // 0.2 * 255
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
              color: Colors.white.withAlpha(153),  // 0.6 * 255
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(6)         // 0.025 * 255
      ..strokeWidth = 1;

    for (int i = 1; i < 8; i++) {
      final y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    paint.color = Colors.white.withAlpha(10);     // 0.04 * 255
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    paint
      ..color = const Color(0xFFCC0000).withAlpha(15)  // 0.06 * 255
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