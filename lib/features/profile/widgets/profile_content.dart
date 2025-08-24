import 'package:flutter/material.dart';
import '../../../app/data/auth_service.dart';
import 'profile_header.dart';
import 'profile_menu_item.dart';
import 'logout_button.dart';
import '../screens/personal_info_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/add_destination_screen.dart';

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

  Future<void> _showLogoutConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Konfirmasi Keluar'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      _handleLogout();
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddDestinationScreen(),
                          ),
                        );
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
            LogoutButton(onPressed: _showLogoutConfirmation),
          ],
        ),
      ),
    );
  }
}
