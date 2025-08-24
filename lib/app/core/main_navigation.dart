import 'package:flutter/material.dart';
import '../../features/home/widgets/home_content.dart';
import '../../features/profile/widgets/profile_content.dart';
import '../../features/chatbot/screens/chatbot_screen.dart';
import '../../features/explore/screens/destinations_explore_screen.dart';
import '../../features/favorite/screens/favorites_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(), // Home
    const DestinationsExploreScreen(), // Eksplorasi
    const FavoritesScreen(), // Favorit
    const ProfileContent(), // Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 80,
        padding: EdgeInsets.zero,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.explore, 'Eksplorasi', 1),
              const SizedBox(width: 50), // Space for FAB
              _buildNavItem(Icons.favorite_border, 'Favorit', 2),
              _buildNavItem(Icons.person, 'Profil', 3),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatPage()),
            );
          },
          backgroundColor: const Color(0xFF6B73FF),
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF6B73FF) : Colors.grey,
                size: 26,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF6B73FF) : Colors.grey,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
