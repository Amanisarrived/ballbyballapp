
import 'package:ballbyball/screens/mainscreens/homescreen/home_screen.dart';
import 'package:ballbyball/screens/mainscreens/productscreen/prodcut_screen.dart';
import 'package:ballbyball/screens/mainscreens/settingscreen/setting_screen.dart';
import 'package:ballbyball/screens/rankingscreen/rankingscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnims;

  final List<_NavItem> _items = const [
    _NavItem(icon: LucideIcons.home,        label: 'Home'),
    _NavItem(icon: LucideIcons.shoppingBag, label: 'Shop'),
    _NavItem(icon: LucideIcons.trophy, label: "Rankings"),
    _NavItem(icon: LucideIcons.settings,    label: 'Settings'),

  ];

  final List<Widget> _screens = const [
    HomeScreen(),
    ShopScreen(),
    RankingsScreen(),
   SettingsScreen(),


  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_items.length, (i) =>
        AnimationController(
            vsync: this, duration: const Duration(milliseconds: 250)));
    _scaleAnims = _controllers.map((c) =>
        Tween<double>(begin: 1.0, end: 1.1)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)))
        .toList();
    _controllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _controllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _controllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        items: _items,
        currentIndex: _currentIndex,
        scaleAnims: _scaleAnims,
        onTap: _onTap,
      ),
    );
  }
}


class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final List<Animation<double>> scaleAnims;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.scaleAnims,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        border: Border(
          top: BorderSide(color: Color(0xFF1C1C1C), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(
              items.length,
                  (i) => Expanded(
                child: _NavTab(
                  item: items[i],
                  selected: i == currentIndex,
                  scaleAnim: scaleAnims[i],
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final Animation<double> scaleAnim;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.scaleAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: selected
                  ? const Color(0xFFCC0000)
                  : const Color(0xFF4A4A4A),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: selected
                    ? const Color(0xFFCC0000)
                    : const Color(0xFF3A3A3A),
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}


