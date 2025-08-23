import 'package:flutter/material.dart';
import '../../../app/data/auth_service.dart';
import 'profile_header.dart';
import 'profile_menu_item.dart';
import 'logout_button.dart';
import '../screens/personal_info_screen.dart';
import '../screens/change_password_screen.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  String? _fullName;
  String? _email;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final name = await AuthService.instance.getCurrentUserFullName();
      final email = await AuthService.instance.getCurrentUserEmail();
      if (!mounted) return;
      setState(() {
        _fullName = name;
        _email = email;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal keluar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Header
                    if (_loadingProfile)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      )
                    else
                      ProfileHeader(
                        name: _fullName ?? 'Azerus Ezhar',
                        email: _email ?? 'azerusezhar5@gmail.com',
                      ),

                    // Menu Items
                    ProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Informasi Pribadi',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PersonalInfoScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ProfileMenuItem(
                      icon: Icons.store_outlined,
                      title: 'Tambahkan UMKM Anda',
                      onTap: () {
                        // TODO: Navigate to add UMKM screen
                      },
                    ),
                    const SizedBox(height: 8),
                    ProfileMenuItem(
                      icon: Icons.lock_outline,
                      title: 'Ganti Password',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Logout Button
            LogoutButton(onPressed: _handleLogout),
          ],
        ),
      ),
    );
  }
}
