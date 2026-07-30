import 'package:flutter/material.dart';
import '../tokens/nano_spacing.dart';

class NanoSideRailItem {
  const NanoSideRailItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class NanoSideRail extends StatelessWidget {
  const NanoSideRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.title = 'Nano',
    this.extended = true,
  });

  final List<NanoSideRailItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String title;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: SizedBox(
          width: extended ? 240 : 88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(NanoSpacing.md),
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final selected = i == selectedIndex;
                    return ListTile(
                      selected: selected,
                      leading: Icon(item.icon),
                      title: extended ? Text(item.label) : null,
                      onTap: () => onSelect(i),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
