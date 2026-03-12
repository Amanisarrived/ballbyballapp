import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/winpredictor_model.dart';
import '../../../../service/winpredictor_service.dart';



class WinPredictorSheet {
  static Future<void> showIfNeeded(BuildContext context) async {
    // Fetch poll
    final snap = await WinPredictorService.fetchPoll();
    if (snap.data() == null) return;

    final poll = CurrentPoll.fromDoc(snap);
    if (!poll.showPoll || poll.pollId.isEmpty) return;

    // Check if already voted on this poll
    final voted = await WinPredictorService.getLocalVote(poll.pollId);
    if (voted != null) return; // already voted, never show again

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _WinPredictorSheetContent(poll: poll),
    );
  }
}

class _WinPredictorSheetContent extends StatefulWidget {
  final CurrentPoll poll;
  const _WinPredictorSheetContent({required this.poll});

  @override
  State<_WinPredictorSheetContent> createState() =>
      _WinPredictorSheetContentState();
}

class _WinPredictorSheetContentState
    extends State<_WinPredictorSheetContent>
    with TickerProviderStateMixin {
  String? _voted;      // 'team1' | 'team2'
  bool _voting = false;
  bool _closing = false;

  // Animations
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;
  late AnimationController _thanksCtrl;
  late Animation<double> _thanksAnim;

  // Live poll (updates after vote)
  late CurrentPoll _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;

    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _barAnim =
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);

    _thanksCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _thanksAnim =
        CurvedAnimation(parent: _thanksCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _thanksCtrl.dispose();
    super.dispose();
  }

  Future<void> _vote(String team) async {
    if (_voting || _voted != null) return;
    HapticFeedback.mediumImpact();
    setState(() => _voting = true);

    try {
      await WinPredictorService.castVote(
          pollId: _poll.pollId, team: team);

      // Re-fetch to get updated counts
      final snap = await WinPredictorService.fetchPoll();
      final updated = CurrentPoll.fromDoc(snap);

      if (!mounted) return;
      setState(() {
        _voted = team;
        _poll = updated;
        _voting = false;
      });

      // Animate bar + thanks
      await _barCtrl.forward();
      await _thanksCtrl.forward();

      // Wait 2s then close
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && !_closing) {
        _closing = true;
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _voting = false);
    }
  }

  Color get _t1Color =>
      _hexColor(_poll.team1Color, const Color(0xFFCC0000));
  Color get _t2Color =>
      _hexColor(_poll.team2Color, const Color(0xFF1A73E8));

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
            child: Column(
              children: [
                // ── Header ────────────────────────────────
                _SheetHeader(voted: _voted),

                const SizedBox(height: 24),

                // ── Team buttons ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _VoteTeamBtn(
                        name: _poll.team1,
                        logo: _poll.team1Logo,
                        color: _t1Color,
                        isVoted: _voted == 'team1',
                        isOtherVoted: _voted == 'team2',
                        voting: _voting,
                        onTap: () => _vote('team1'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _VoteTeamBtn(
                        name: _poll.team2,
                        logo: _poll.team2Logo,
                        color: _t2Color,
                        isVoted: _voted == 'team2',
                        isOtherVoted: _voted == 'team1',
                        voting: _voting,
                        onTap: () => _vote('team2'),
                      ),
                    ),
                  ],
                ),

                // ── Result section (shown after vote) ─────
                if (_voted != null) ...[
                  const SizedBox(height: 20),

                  // Progress bar
                  _ResultBar(
                    poll: _poll,
                    t1Color: _t1Color,
                    t2Color: _t2Color,
                    animation: _barAnim,
                  ),

                  const SizedBox(height: 16),

                  // Thanks message
                  FadeTransition(
                    opacity: _thanksAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_thanksAnim),
                      child: _ThanksMessage(
                        votedTeam: _voted == 'team1'
                            ? _poll.team1
                            : _poll.team2,
                        color: _voted == 'team1'
                            ? _t1Color
                            : _t2Color,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),

                  // Skip button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                            color: Colors.white.withAlpha(30),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String hex, Color fallback) {
    try {
      return Color(
          int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

// ════════════════════════════════════════════════════════════
//  SHEET HEADER
// ════════════════════════════════════════════════════════════
class _SheetHeader extends StatelessWidget {
  final String? voted;
  const _SheetHeader({required this.voted});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Match day badge
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFCC0000).withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFCC0000).withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5, height: 5,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                    color: Color(0xFFCC0000),
                    shape: BoxShape.circle),
              ),
              const Text('MATCH DAY',
                  style: TextStyle(
                      color: Color(0xFFCC0000),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Text(
          voted == null ? 'Who will win today?' : 'You voted!',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5),
        ),

        const SizedBox(height: 6),

        Text(
          voted == null
              ? 'Tap your prediction below'
              : 'Here\'s what everyone thinks',
          style: TextStyle(
              color: Colors.white.withAlpha(45),
              fontSize: 13,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════
//  VOTE TEAM BUTTON
// ════════════════════════════════════════════════════════════
class _VoteTeamBtn extends StatefulWidget {
  final String name, logo;
  final Color color;
  final bool isVoted, isOtherVoted, voting;
  final VoidCallback onTap;

  const _VoteTeamBtn({
    required this.name,
    required this.logo,
    required this.color,
    required this.isVoted,
    required this.isOtherVoted,
    required this.voting,
    required this.onTap,
  });

  @override
  State<_VoteTeamBtn> createState() => _VoteTeamBtnState();
}

class _VoteTeamBtnState extends State<_VoteTeamBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _canTap =>
      !widget.isVoted && !widget.isOtherVoted && !widget.voting;

  @override
  Widget build(BuildContext context) {
    final dimmed = widget.isOtherVoted;
    final selected = widget.isVoted;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _canTap ? (_) => _ctrl.forward() : null,
        onTapUp: _canTap
            ? (_) {
          _ctrl.reverse();
          widget.onTap();
        }
            : null,
        onTapCancel: _canTap ? () => _ctrl.reverse() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? widget.color.withAlpha(20)
                : dimmed
                ? Colors.white.withAlpha(4)
                : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? widget.color.withAlpha(130)
                  : dimmed
                  ? Colors.white.withAlpha(8)
                  : Colors.white.withAlpha(18),
              width: selected ? 1.5 : 1.0,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                  color: widget.color.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: 1)
            ]
                : [],
          ),
          child: Column(
            children: [
              // Logo
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: dimmed ? 0.25 : 1.0,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(6),
                    border: Border.all(
                      color: selected
                          ? widget.color.withAlpha(100)
                          : Colors.white.withAlpha(18),
                      width: selected ? 2 : 1,
                    ),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                          color: widget.color.withAlpha(60),
                          blurRadius: 16)
                    ]
                        : [],
                  ),
                  child: ClipOval(
                    child: widget.logo.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: widget.logo,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          _Fallback(name: widget.name),
                      errorWidget: (_, _, _) =>
                          _Fallback(name: widget.name),
                    )
                        : _Fallback(name: widget.name),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Name
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: dimmed ? 0.25 : 1.0,
                child: Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                    selected ? widget.color : Colors.white,
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // State indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: selected
                      ? widget.color.withAlpha(25)
                      : Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? widget.color.withAlpha(70)
                        : Colors.white.withAlpha(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_rounded,
                          color: widget.color, size: 11),
                      const SizedBox(width: 5),
                    ] else if (widget.voting) ...[
                      SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      selected
                          ? 'Your pick ✓'
                          : widget.voting
                          ? 'Voting…'
                          : 'Tap to vote',
                      style: TextStyle(
                        color: selected
                            ? widget.color
                            : Colors.white.withAlpha(40),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  RESULT BAR
// ════════════════════════════════════════════════════════════
class _ResultBar extends StatelessWidget {
  final CurrentPoll poll;
  final Color t1Color, t2Color;
  final Animation<double> animation;

  const _ResultBar({
    required this.poll,
    required this.t1Color,
    required this.t2Color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final t1pct = poll.team1Percent;
    final t2pct = poll.team2Percent;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final t1Animated = t1pct * animation.value;
        final t2Animated = t2pct * animation.value;

        return Column(
          children: [
            // Percentage row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t1Animated.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: t1Color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                    Text(poll.team1,
                        style: TextStyle(
                            color: Colors.white.withAlpha(35),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                // Total votes
                Column(
                  children: [
                    Text(
                      '${poll.totalVotes}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    Text('fans voted',
                        style: TextStyle(
                            color: Colors.white.withAlpha(30),
                            fontSize: 9,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${t2Animated.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: t2Color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                    Text(poll.team2,
                        style: TextStyle(
                            color: Colors.white.withAlpha(35),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Flexible(
                      flex: t1Animated.round().clamp(1, 99),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              t1Color,
                              t1Color.withAlpha(180),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                        width: 3,
                        color: const Color(0xFF0F0F0F)),
                    Flexible(
                      flex: t2Animated.round().clamp(1, 99),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              t2Color.withAlpha(180),
                              t2Color,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
//  THANKS MESSAGE
// ════════════════════════════════════════════════════════════
class _ThanksMessage extends StatelessWidget {
  final String votedTeam;
  final Color color;
  const _ThanksMessage(
      {required this.votedTeam, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            'You picked $votedTeam — good luck! 🏏',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Logo fallback ─────────────────────────────────────────
class _Fallback extends StatelessWidget {
  final String name;
  const _Fallback({required this.name});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withAlpha(8),
    child: Center(
      child: Text(
        name.length >= 2
            ? name.substring(0, 2).toUpperCase()
            : name,
        style: const TextStyle(
            color: Colors.white38,
            fontSize: 16,
            fontWeight: FontWeight.w900),
      ),
    ),
  );
}