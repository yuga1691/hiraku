import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'my_page_screen.dart';
import 'register_screen.dart';
import 'test_screen.dart';
import 'usage_guide_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  final List<Widget> _pages = const [
    TestScreen(),
    RegisterScreen(),
    UsageGuideScreen(),
    MyPageScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(forceTestMode: true),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.9),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              backgroundColor: Colors.transparent,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt),
                  label: 'テスト',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.app_registration_outlined),
                  selectedIcon: Icon(Icons.app_registration),
                  label: '登録',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: '使い方',
                ),
                NavigationDestination(
                  icon: _buildMyPageNavIcon(
                    selected: false,
                    userId: currentUser?.uid,
                  ),
                  selectedIcon: _buildMyPageNavIcon(
                    selected: true,
                    userId: currentUser?.uid,
                  ),
                  label: 'マイページ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPageNavIcon({
    required bool selected,
    required String? userId,
  }) {
    final baseIcon = Icon(selected ? Icons.person : Icons.person_outline);
    if (userId == null || userId.isEmpty) {
      return baseIcon;
    }
    return StreamBuilder<int>(
      stream: _firestoreService.watchAdminNotificationUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        if (unreadCount <= 0) {
          return baseIcon;
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            baseIcon,
            Positioned(
              right: -2,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
