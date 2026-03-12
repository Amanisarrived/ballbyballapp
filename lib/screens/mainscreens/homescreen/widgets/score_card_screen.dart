import 'dart:async';
import 'package:ballbyball/models/current_over.dart';
import 'package:ballbyball/models/live_score_match.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/scores_screen.dart';
import 'package:ballbyball/screens/mainscreens/homescreen/widgets/squad_screen.dart';
import 'package:ballbyball/service/live_match_service.dart';
import 'package:flutter/foundation.dart';
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

  // FIX 3: Two separate notifiers — header/scores get one, over strip gets
  // its own. This means a new ball only repaints the over strip, NOT the
  // entire header tree (logos, score, target bar, etc.).
  final _matchNotifier = ValueNotifier<FeaturedMatch?>(null);
  final _overNotifier  = ValueNotifier<List<CurrentOver>>([]);

  @override
  void initState() {
    super.initState();
    _sub = LiveMatchService.instance.streamFeaturedMatch().listen((match) {
      if (match == null || !mounted) return;

      // FIX 4: Only push to _matchNotifier when match data actually changed.
      // Firestore can emit multiple rapid snapshots for the same logical state.
      // Using listEquals / identical checks avoids redundant downstream rebuilds.
      final prev = _matchNotifier.value;
      final overChanged = !listEquals(match.currentOver, prev?.currentOver);
      final matchChanged = !identical(match, prev);

      if (matchChanged) {
        _matchNotifier.value = match;
      }

      // FIX 5: Push over updates independently. _CurrentOverStrip only rebuilds
      // when the over list actually changes — not on every score/wicket update.
      if (overChanged) {
        _overNotifier.value = List.unmodifiable(match.currentOver);
      }

      // Only call setState once — for the very first load to swap spinner → content.
      if (_match == null) setState(() => _match = match);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _matchNotifier.dispose();
    _overNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_match == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
              color: Color(0xFFCC0000), strokeWidth: 1.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: true,
        child: Column(children: [
          // Header listens to matchNotifier — repaints on score/wicket/target changes
          _LiveMatchHeader(matchNotifier: _matchNotifier),
          _buildTabs(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _LiveScoresScreen(notifier: _matchNotifier),
                _LiveSquadsScreen(notifier: _matchNotifier),
              ],
            ),
          ),
        ]),
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

// ── Wrapper widgets — created once, update via ValueNotifier ──

class _LiveMatchHeader extends StatelessWidget {
  final ValueNotifier<FeaturedMatch?> matchNotifier;
  const _LiveMatchHeader({required this.matchNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FeaturedMatch?>(
      valueListenable: matchNotifier,
      builder: (_, match, _) {
        if (match == null) return const SizedBox.shrink();
        return RepaintBoundary(
          child: MatchHeader(match: match),
        );
      },
    );
  }
}

class _LiveScoresScreen extends StatelessWidget {
  final ValueNotifier<FeaturedMatch?> notifier;
  const _LiveScoresScreen({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FeaturedMatch?>(
      valueListenable: notifier,
      builder: (_, match, _) {
        if (match == null) return const SizedBox.shrink();
        return RepaintBoundary(
          child: ScoresScreen(match: match),
        );
      },
    );
  }
}

class _LiveSquadsScreen extends StatelessWidget {
  final ValueNotifier<FeaturedMatch?> notifier;
  const _LiveSquadsScreen({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FeaturedMatch?>(
      valueListenable: notifier,
      builder: (_, match, _) {
        if (match == null) return const SizedBox.shrink();
        return RepaintBoundary(
          child: SquadsScreen(match: match),
        );
      },
    );
  }
}