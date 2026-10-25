import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SGBottomNavItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;

  const SGBottomNavItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}

class SGBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SGBottomNavItem> items;
  final Color? backgroundColor;
  final Color? indicatorColor;
  final double height;

  const SGBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
    this.backgroundColor,
    this.indicatorColor,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      height: height,
      backgroundColor: backgroundColor ?? theme.navigationBarTheme.backgroundColor,
      indicatorColor: indicatorColor ?? theme.navigationBarTheme.indicatorColor,
      elevation: theme.navigationBarTheme.elevation ?? 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: theme.navigationBarTheme.shadowColor,
      labelTextStyle: theme.navigationBarTheme.labelTextStyle,
      destinations: items.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon ?? item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}

class SGNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<SGBottomNavItem> items;
  final bool extended;
  final double minWidth;

  const SGNavigationRail({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
    this.extended = false,
    this.minWidth = 56,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      extended: extended,
      minWidth: minWidth,
      backgroundColor: theme.navigationBarTheme.backgroundColor,
      indicatorColor: theme.navigationBarTheme.indicatorColor,
      elevation: 0,
      labelType: extended ? NavigationRailLabelType.all : NavigationRailLabelType.none,
      destinations: items.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon ?? item.icon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}