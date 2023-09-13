import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/views/global_nav/destinations.dart';
import 'package:scannmay_toolkit/views/global_nav/window_controls.dart';

class GlobalNavView extends StatefulWidget {
  const GlobalNavView({
    super.key,
  });

  @override
  State<GlobalNavView> createState() => _GlobalNavViewState();
}

class _GlobalNavViewState extends State<GlobalNavView> {
  bool navExpanded = false;
  int selectedNavIndex = 0;

  // 一个 flag，确保只会进行一次应用启动时的更新检查
  bool updateChecked = false;

  @override
  Widget build(BuildContext context) {
    Widget currentView = getCurrentView(selectedNavIndex);

    Icon menuIcon = navExpanded ? const Icon(Icons.menu_open_sharp) : const Icon(Icons.menu_sharp);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: navExpanded,
            leading: Column(
              children: [
                const SizedBox(height: 8),
                Image.asset("assets/images/icon.png", width: 50, isAntiAlias: true),
                IconButton(
                  onPressed: () => setState(() => navExpanded = !navExpanded),
                  icon: menuIcon,
                ),
              ],
            ),
            destinations: destinations,
            onDestinationSelected: (value) => setState(() => selectedNavIndex = value),
            selectedIndex: selectedNavIndex,
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WindowControls(),
                  Expanded(child: currentView),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
