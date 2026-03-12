import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../../../service/reaction_service.dart';

// ── Usage ─────────────────────────────────────────────────
// ReactionBar(matchId: match.id)

class ReactionBar extends StatefulWidget {

  const ReactionBar({super.key, });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  String? _myReaction;
  bool _loading = false;

  final _reactions = [
    _Reaction('fire', '🔥', const Color(0xFFFF6B35)),
    _Reaction('shocked', '😱', const Color(0xFF7C4DFF)),
    _Reaction('celebrate', '🎉', const Color(0xFF00C853)),
    _Reaction('heartbreak', '💔', const Color(0xFFE91E63)),
  ];

  @override
  void initState() {
    super.initState();
    _loadMyReaction();
  }

  Future<void> _loadMyReaction() async {
    final r = await AppReactionService.getUserReaction();
    if (mounted) setState(() => _myReaction = r);
  }

  Future<void> _onTap(String type) async {
    if (_loading) return;

    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _myReaction = type;
    });

    try {
      await AppReactionService.react(type);
      await AppReactionService.saveReaction(type);
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: AppReactionService.stream(),
      builder: (context, snap) {
        final counts = snap.data ?? {};

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _reactions.map((r) {
              final count = counts[r.type] ?? 0;
              final isSelected = _myReaction == r.type;

              return _ReactionButton(
                reaction: r,
                count: count,
                isSelected: isSelected,
                onTap: () => _onTap(r.type),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════
//  REACTION BUTTON
// ════════════════════════════════════════════════════════════
class _ReactionButton extends StatefulWidget {
  final _Reaction reaction;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.reaction,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ReactionButton old) {
    super.didUpdateWidget(old);
    // Animate when selected
    if (widget.isSelected && !old.isSelected) {
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.reaction.color.withOpacity(0.15)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? widget.reaction.color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.reaction.emoji,
                  style: TextStyle(
                      fontSize: widget.isSelected ? 15 : 13)),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isSelected
                      ? widget.reaction.color
                      : Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
                child: Text(_formatCount(widget.count)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────
class _Reaction {
  final String type;
  final String emoji;
  final Color color;
  const _Reaction(this.type, this.emoji, this.color);
}