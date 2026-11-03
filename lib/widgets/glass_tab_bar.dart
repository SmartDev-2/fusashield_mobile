import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

class _TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _TabItem(this.icon, this.selectedIcon, this.label);
}

class GlassTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GlassTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _items = <_TabItem>[
    _TabItem(Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    _TabItem(
      Icons.document_scanner_outlined,
      Icons.document_scanner_rounded,
      'Deteksi',
    ),
    _TabItem(Icons.insights_outlined, Icons.insights_rounded, 'Riwayat'),
    _TabItem(Icons.eco_outlined, Icons.eco_rounded, 'Mitigasi'),
    _TabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: GlassCard(
          radius: 36,
          padding: const EdgeInsets.all(8),
          elevated: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _items.length; i++)
                _TabButton(
                  item: _items[i],
                  selected: i == selectedIndex,
                  onTap: () {
                    if (i != selectedIndex) {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 10,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.o(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 24,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
