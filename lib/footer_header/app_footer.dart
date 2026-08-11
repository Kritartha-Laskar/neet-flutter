import 'package:flutter/material.dart';

/// Shared bottom navigation footer.
///
/// Usage:
/// ```dart
/// Scaffold(
///   bottomNavigationBar: AppFooter(
///     currentIndex: _navIndex,
///     onTap: (i) => setState(() => _navIndex = i),
///   ),
/// )
/// ```
class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // ── Brand colour ────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _activeBg = Color(0xFFEDE7FF);

  // ── Nav items ───────────────────────────────────────────────────────────────
  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Courses'),
    _NavItem(icon: Icons.description_rounded, label: 'Tests'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => Expanded(
                child: _NavTile(
                  item: _items[i],
                  isActive: currentIndex == i,
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

// ── Internal tile widget ───────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _activeBg = Color(0xFFEDE7FF);
  static const Color _textMuted = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animated active pill background
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? _activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              item.icon,
              size: 22,
              color: isActive ? _primary : _textMuted,
            ),
          ),
          const SizedBox(height: 2),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? _primary : _textMuted,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
