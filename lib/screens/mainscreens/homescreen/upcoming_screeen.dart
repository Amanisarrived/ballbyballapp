import 'package:ballbyball/screens/mainscreens/homescreen/widgets/upcoming_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pointstabelscreen/pointstabelscreen.dart';

class Upcoming extends StatefulWidget {
  final ScrollController? scrollController;
  const Upcoming({super.key, required this.scrollController});

  @override
  State<Upcoming> createState() => _UpcomingState();
}

class _UpcomingState extends State<Upcoming> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _SegmentBar(
            selected: _selected,
            onTap: (i) {
              HapticFeedback.lightImpact();
              setState(() => _selected = i);
            },
          ),
          const SizedBox(height: 8),

          // ── keeps both alive, collapses hidden one to zero height ──
          Visibility(
            visible: _selected == 0,
            maintainState: true, // keeps stream + scroll alive
            child: const UpcomingSection(previewMode: false),
          ),
          Visibility(
            visible: _selected == 1,
            maintainState: true,
            child: const Pointstabelscreen(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Segment bar ───────────────────────────────────────────
class _SegmentBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _SegmentBar({required this.selected, required this.onTap});

  static const _labels = ['Upcoming', 'Points Table'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withAlpha(12)),
        ),
        child: Row(
          children: List.generate(_labels.length, (i) {
            final active = selected == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF242424)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: active
                        ? Border.all(color: Colors.white.withAlpha(14))
                        : null,
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : Colors.white.withAlpha(55),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      child: Text(_labels[i]),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
