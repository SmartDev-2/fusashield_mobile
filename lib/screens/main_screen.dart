import 'package:flutter/material.dart';

import '../pages/dashboard_page.dart';
import '../pages/detection_page.dart';
import '../pages/history_page.dart';
import '../pages/mitigation_page.dart';
import '../pages/profile_page.dart';
import '../widgets/farm_background.dart';
import '../widgets/glass_tab_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    DetectionPage(),
    HistoryPage(),
    MitigationPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FarmBackground(),
          IndexedStack(index: _index, children: _pages),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassTabBar(
              selectedIndex: _index,
              onChanged: (i) => setState(() => _index = i),
            ),
          ),
        ],
      ),
    );
  }
}
