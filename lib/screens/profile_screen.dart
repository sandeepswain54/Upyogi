import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_user_profile_screen.dart';
import 'my_services_screen.dart';
import 'role_select_screen.dart';

const kPrimaryPurple = Color(0xFF6C5CE7);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = "";
  String _role = "";
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fullName = prefs.getString("fullName") ?? "User";
      _role = prefs.getString("role") ?? "Customer";
      _profileImageUrl = prefs.getString("profileImageUrl");
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFFF3F1FE),
              backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 45, color: kPrimaryPurple)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_role, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            if (_role == "Provider")
              ListTile(
                leading: const Icon(Icons.business_center_outlined, color: kPrimaryPurple),
                title: const Text("My Services"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyServicesScreen()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("Edit Profile"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditUserProfileScreen()),
                );
                _loadUser(); // refresh displayed name/image after editing
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Change Password"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text("Notifications"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text("Help & Support"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
