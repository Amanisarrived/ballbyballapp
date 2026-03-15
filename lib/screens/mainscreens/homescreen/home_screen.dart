import 'package:ballbyball/screens/mainscreens/homescreen/for_you_screen.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/news.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/upcoming_screeen.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/custom_app_bar.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/tabs_chip.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/win_predictor_sheet.dart';
import 'package:ballbyball/service/app_analytics.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../widgets/rating_prompt.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  final _scrollControllers = List.generate(4, (_) => ScrollController());
  final _showFab = ValueNotifier(false);

  ScrollController get _activeController => _scrollControllers[_selectedTab];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _scrollControllers.length; i++) {
      final ctrl = _scrollControllers[i];
      ctrl.addListener(() {
        if (_selectedTab == i) {
          _showFab.value = ctrl.hasClients && ctrl.offset > 300;
        }
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) WinPredictorSheet.showIfNeeded(context);
    });

    AppAnalytics.appOpen();
    AppAnalytics.screenHome();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final _ = await PackageInfo.fromPlatform();
      if (!mounted) return;
      await RatingPrompt.checkAndShow(context);
    });
  }

  @override
  void dispose() {
    for (final c in _scrollControllers) {
      c.dispose();
    }
    _showFab.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_activeController.hasClients) {
      _activeController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showFab,
        builder: (_, show, child) => AnimatedSlide(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          offset: show ? Offset.zero : const Offset(0, 2),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: show ? 1.0 : 0.0,
            child: child,
          ),
        ),
        child: GestureDetector(
          onTap: _scrollToTop,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(102), // 0.4 * 255 ≈ 102
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CustomAppBar(),
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: TabsChip(
                      onTabChanged: (index) {
                        setState(() => _selectedTab = index);
                        _showFab.value = false;
                      },
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        ForYouScreen(scrollController: _scrollControllers[0]),
                        Upcoming(scrollController: _scrollControllers[1]),
                        News(scrollController: _scrollControllers[3]),
                      ],
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
