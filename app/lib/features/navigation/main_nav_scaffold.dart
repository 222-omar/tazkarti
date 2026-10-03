import 'package:flutter/material.dart';
import '../matches/presentation/matches_screen.dart';
import '../settings/presentation/settings_screen.dart';

class MainNavScaffold extends StatefulWidget {
  const MainNavScaffold({super.key});

  @override
  State<MainNavScaffold> createState() => _MainNavScaffoldState();
}

class _MainNavScaffoldState extends State<MainNavScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MatchesScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF13141B),
          border: Border(
            top: BorderSide(color: Color(0xFF2C2F3E), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF13141B),
          selectedItemColor: const Color(0xFFD32F2F),
          unselectedItemColor: const Color(0xFF888888),
          selectedFontSize: 13,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer),
              activeIcon: Icon(Icons.sports_soccer, color: Color(0xFFD32F2F)),
              label: 'المباريات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded),
              activeIcon:
                  Icon(Icons.notifications_active, color: Color(0xFFD32F2F)),
              label: 'التنبيهات والإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}
