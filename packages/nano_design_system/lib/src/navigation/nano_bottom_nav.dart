import 'package:flutter/material.dart';

class NanoBottomNavItem {
  const NanoBottomNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class NanoBottomNav extends StatelessWidget {
  const NanoBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<NanoBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex.clamp(0, items.length - 1),
      onDestinationSelected: onSelect,
      destinations: [
        for (final item in items)
          NavigationDestination(
            icon: Icon(item.icon),
            label: item.label,
          ),
      ],
    );
  }
}
