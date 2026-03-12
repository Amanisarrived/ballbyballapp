import 'package:ballbyball/screens/main.nav.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../providers/banner_provder.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _wicketController;
  late AnimationController _progressController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _wicketRotate;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BannerProvider>().loadBanners();
    });


    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );


    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );


    _wicketController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();


    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _wicketRotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(_wicketController);
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );


    _logoController.forward().then((_) {
      _contentController.forward();
      _progressController.forward();
    });

    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainNav(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _wicketController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Stack(
        children: [


          Positioned.fill(
            child: CustomPaint(painter: _PitchPainter()),
          ),


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


          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFCC0000).withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),

                        Container(
                          width: 114,
                          height: 114,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF111111),
                            border: Border.all(
                              color: const Color(0xFFCC0000).withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFCC0000).withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),

                        ClipOval(
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Image.asset(
                              "assets/bb51.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const Text(
                      'BallByBall',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),


                FadeTransition(
                  opacity: _contentFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCC0000),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Scores  •  Highlights  •  News',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFCC0000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),


                FadeTransition(
                  opacity: _contentFade,
                  child: AnimatedBuilder(
                    animation: _wicketRotate,
                    builder: (_, __) => Transform.rotate(
                      angle: _wicketRotate.value,
                      child: Image.asset(
                        'assets/spin.png',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),


                FadeTransition(
                  opacity: _contentFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progressAnim.value,
                              backgroundColor: Colors.white.withOpacity(0.06),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFCC0000),
                              ),
                              minHeight: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),


                FadeTransition(
                  opacity: _contentFade,
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
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