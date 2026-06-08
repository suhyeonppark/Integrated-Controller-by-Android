import 'package:flutter/material.dart';

import '../widgets/status_bar.dart';
import 'home_screen.dart';
import 'ir_screen.dart';
import 'relay_screen.dart';
import 'settings_screen.dart';

/// Root navigation shell: persistent status bar on top, the four screens
/// switched via a bottom navigation bar (spec §10).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ['AMX CE CONTROL', 'IR 제어', '전원 제어', '설정'];

  static const _screens = [
    HomeScreen(),
    IrScreen(),
    PowerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const StatusBar(),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        height: 72,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.settings_remote), label: 'IR 제어'),
          NavigationDestination(icon: Icon(Icons.power), label: '전원 제어'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
