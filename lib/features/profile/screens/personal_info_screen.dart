import 'package:flutter/material.dart';
import '../../../app/data/auth_service.dart';
import '../widgets/profile_form_field.dart';
import '../../../app/core/widgets/custom_snackbar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with TickerProviderStateMixin {
  String? _fullName;
  String? _email;
  String? _username;
  String? _phone;
  String? _address;
  String? _city;
  String? _postalCode;
  bool _loading = true;
  bool _isScrolled = false;
  late AnimationController _animationController;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Background color animation
    _backgroundAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Elevation animation
    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AuthService.instance.getUserProfile();
      final email = await AuthService.instance.getCurrentUserEmail();
      
      if (!mounted) return;
      setState(() {
        _fullName = profile?['full_name'] ?? 'Azerus Ezhar';
        _email = email ?? 'azerusezhar5@gmail.com';
        _username = profile?['username'] ?? 'Belum diisi';
        _phone = profile?['phone'] ?? 'Belum diisi';
        _address = profile?['address'] ?? 'Belum diisi';
        _city = profile?['city'] ?? 'Belum diisi';
        _postalCode = profile?['postal_code'] ?? 'Belum diisi';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _editField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue == 'Belum diisi' ? '' : currentValue);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        switch (field) {
          case 'Nama Lengkap':
            _fullName = result;
            break;
          case 'Username':
            _username = result;
            break;
          case 'Nomor Telepon':
            _phone = result;
            break;
          case 'Alamat Lengkap':
            _address = result;
            break;
          case 'Kota':
            _city = result;
            break;
          case 'Kode Pos':
            _postalCode = result;
            break;
        }
      });
      
      // TODO: Update database with new values
      await _updateProfile();
    }
  }

  Future<void> _updateProfile() async {
    try {
      // Update profile in database with all fields
      await AuthService.instance.updateUserProfile(
        fullName: _fullName,
        username: _username,
        phone: _phone == 'Belum diisi' ? null : _phone,
        address: _address == 'Belum diisi' ? null : _address,
        city: _city == 'Belum diisi' ? null : _city,
        postalCode: _postalCode == 'Belum diisi' ? null : _postalCode,
      );
      
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Profil berhasil diperbarui',
        type: SnackbarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Gagal memperbarui profil: $e',
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                final isScrolled = scrollInfo.metrics.pixels > 0;
                if (isScrolled != _isScrolled) {
                  setState(() {
                    _isScrolled = isScrolled;
                  });
                  
                  // Animate based on scroll state
                  if (isScrolled) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                }
                return false;
              },
              child: CustomScrollView(
                slivers: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return SliverAppBar(
                        backgroundColor: _backgroundAnimation.value,
                        surfaceTintColor: Colors.white,
                        elevation: _elevationAnimation.value,
                        shadowColor: Colors.black.withOpacity(0.1),
                        pinned: true,
                        leading: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                        ),
                        title: Text(
                          'Informasi Pribadi',
                          style: textTheme.titleLarge?.copyWith(
                            color: const Color(0xFF6B73FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        centerTitle: true,
                      );
                    },
                  ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                  const SizedBox(height: 20),
                  
                  // Profile Photo Section
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: const Color(0xFF6B73FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Change Photo Button
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement photo picker
                    },
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF6B73FF)),
                    label: Text(
                      'Ubah Foto',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B73FF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Basic Information Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Informasi Dasar',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF6B73FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ProfileFormField(
                    icon: Icons.person_outline,
                    label: 'Nama Lengkap',
                    value: _fullName ?? 'Belum diisi',
                    onTap: () => _editField('Nama Lengkap', _fullName ?? 'Belum diisi'),
                  ),
                  
                  ProfileFormField(
                    icon: Icons.alternate_email,
                    label: 'Username',
                    value: _username ?? 'Belum diisi',
                    onTap: () => _editField('Username', _username ?? 'Belum diisi'),
                  ),
                  
                  ProfileFormField(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: _email ?? 'Belum diisi',
                    isEditable: false,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Contact Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Kontak',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF6B73FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ProfileFormField(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: _phone ?? 'Belum diisi',
                    onTap: () => _editField('Nomor Telepon', _phone ?? 'Belum diisi'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Address Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Alamat',
                        style: textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF6B73FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ProfileFormField(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat Lengkap',
                    value: _address ?? 'Belum diisi',
                    onTap: () => _editField('Alamat Lengkap', _address ?? 'Belum diisi'),
                  ),
                  
                  ProfileFormField(
                    icon: Icons.location_city_outlined,
                    label: 'Kota',
                    value: _city ?? 'Belum diisi',
                    onTap: () => _editField('Kota', _city ?? 'Belum diisi'),
                  ),
                  
                  ProfileFormField(
                    icon: Icons.markunread_mailbox_outlined,
                    label: 'Kode Pos',
                    value: _postalCode ?? 'Belum diisi',
                    onTap: () => _editField('Kode Pos', _postalCode ?? 'Belum diisi'),
                  ),
                  
                  const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
