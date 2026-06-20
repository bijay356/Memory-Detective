import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_filled, label: 'HOME'),
      _NavItem(icon: Icons.manage_search, label: 'CASES'),
      _NavItem(icon: Icons.emoji_events, label: 'AWARDS'),
      _NavItem(icon: Icons.person, label: 'PROFILE'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTiny = constraints.maxWidth < 360;
        final sidePadding = isTiny ? 8.0 : 16.0;
        final navHeight = isTiny ? 66.0 : 72.0;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: navHeight,
                  padding: EdgeInsets.all(isTiny ? 6 : 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A2D).withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(items.length, (index) {
                      final selected = currentIndex == index;
                      return Expanded(
                        child: _BottomNavButton(
                          item: items[index],
                          selected: selected,
                          isTiny: isTiny,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isTiny;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.isTiny,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.gold : AppTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: isTiny ? 1 : 3),
          padding: EdgeInsets.symmetric(horizontal: isTiny ? 4 : 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.gold.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppTheme.gold.withValues(alpha: 0.34)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: color, size: 22),
              SizedBox(height: isTiny ? 2 : 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: isTiny ? 10 : 11,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
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
