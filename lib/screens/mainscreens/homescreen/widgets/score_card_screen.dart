import 'dart:async';
import 'package:ballbyball/models/live_score_match.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/scores_screen.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/squad_screen.dart';
import 'package:ballbyball/service/live_match_service.dart';
import 'package:flutter/material.dart';
import 'match_header.dart';

class ScoreCardScreen extends StatefulWidget {
  const ScoreCardScreen({super.key});

  @override
  State<ScoreCardScreen> createState() => _ScoreCardScreenState();
}

class _ScoreCardScreenState extends State<ScoreCardScreen> {
  int _selectedTab = 0;
  FeaturedMatch? _match;
  StreamSubscription<FeaturedMatch?>? _sub;

  @override
  void initState() {
    super.initState();

    // ── Show cached data instantly — no loading spinner ──
    if (LiveMatchService.instance.cachedMatch != null) {
      _match = LiveMatchService.instance.cachedMatch;
    }

    _sub = LiveMatchService.instance.streamFeaturedMatch().listen((match) {
      if (match == null || !mounted) return;
      setState(() => _match = match);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_match == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFCC0000)),
        ),
      );
    }

    return SafeArea(
      bottom: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: MatchHeader(match: _match!),
            ),
            _buildTabs(),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  ScoresScreen(match: _match!),
                  SquadsScreen(match: _match!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(18)),
          bottom: BorderSide(color: Colors.white.withAlpha(18)),
        ),
      ),
      child: Row(
        children: ['Scorecard', 'Squads'].asMap().entries.map((e) {
          final isSelected = _selectedTab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = e.key),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFFCC0000)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withAlpha(100),
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}