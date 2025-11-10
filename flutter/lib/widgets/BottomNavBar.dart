
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isLoggedIn;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onLoginRequested;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.isLoggedIn,
    this.onTabSelected,
    this.onLoginRequested,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        // Giriş gerektiren sekmeler: Favoriler (1), İlanlarım (2), Profil (4)
        if ((index == 1 || index == 2 || index == 4) && !isLoggedIn) {
          if (onLoginRequested != null) {
            onLoginRequested!();
          }
          return;
        }
        if (onTabSelected != null) {
          onTabSelected!(index);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Keşfedin"),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favoriler"),
        BottomNavigationBarItem(icon: Icon(Icons.home_work), label: "İlanlarım"),
        BottomNavigationBarItem(icon: Icon(Icons.travel_explore), label: "Seyahatler"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
      ],
    );
  }
}