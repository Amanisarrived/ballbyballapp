import 'package:flutter/material.dart';

class TabsChip extends StatefulWidget {
  final ValueChanged<int> onTabChanged;
  const TabsChip({super.key, required this.onTabChanged});

  @override
  State<TabsChip> createState() => _TabsChipState();
}

class _TabsChipState extends State<TabsChip> {
  int _selectedIndex = 0;

  final List<String> _tabs = ['For You', 'Upcoming', 'News'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double padding = 4;
        final tabWidth = (constraints.maxWidth - padding * 2) / _tabs.length;

        return Container(
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  // 🔴 Sliding Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    left: _selectedIndex * tabWidth,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B0000),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),

                  // 📝 Tab Labels
                  Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                            widget.onTabChanged(index); // ✅ callback
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF666666),
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                letterSpacing: 0.3,
                              ),
                              child: Text(
                                _tabs[index],
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}