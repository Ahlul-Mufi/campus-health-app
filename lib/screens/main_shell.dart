import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'maps/maps_screen.dart';
// import '../favorites/favorites_screen.dart';
// import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MapsScreen(),
    // FavoritesScreen(),
    // ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _HealthyBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i >= _screens.length) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Coming Soon',
                    style: TextStyle(color: Color(0xFF1B1C17))),
                backgroundColor: const Color(0xFFBDEFBE),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
            return;
          }
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}

class _HealthyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HealthyBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.map_rounded, label: 'Map'),
      _NavItem(icon: Icons.favorite_rounded, label: 'Favorites'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9F1).withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 20 : 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFBDEFBE)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].icon,
                      size: 22,
                      color: selected
                          ? const Color(0xFF426E47)
                          : const Color(0xFF40493D),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? const Color(0xFF426E47)
                            : const Color(0xFF40493D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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