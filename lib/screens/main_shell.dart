import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/role_provider.dart';
import 'home_feed_screen.dart';
import 'upload_service_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';

const kPrimaryPurple = Color(0xFF6C5CE7);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(selectedRoleProvider); // "Provider" or "Customer"
    final isProvider = role == "Provider";

    final List<Widget> screens = isProvider
        ? const [
            HomeFeedScreen(),
            UploadServiceScreen(),
            AppointmentsScreen(),
            ProfileScreen(),
          ]
        : const [
            HomeFeedScreen(),
            AppointmentsScreen(),
            ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> items = isProvider
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: "Upload"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Appointments"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: "Appointments"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: "Profile"),
          ];

    // Clamp index if role changes and list is shorter
    if (_selectedIndex >= screens.length) _selectedIndex = 0;

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kPrimaryPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: items,
      ),
    );
  }
}
