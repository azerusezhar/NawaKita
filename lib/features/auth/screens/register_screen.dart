import 'package:flutter/material.dart';
import 'package:nawakita/app/widgets/app_text_field.dart';
import 'package:nawakita/app/widgets/primary_button.dart';
import 'package:nawakita/app/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nawakita/app/core/widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailCtrl.text.trim();
      final fullName = _nameCtrl.text.trim();
      final password = _passwordCtrl.text;

      // Send OTP and navigate to verification screen
      await AuthService.instance.sendEmailOtp(email: email, shouldCreateUser: true);
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        '/verify-otp',
        arguments: {
          'email': email,
          'fullName': fullName,
          'password': password,
        },
      );
    } on AuthException catch (e) {
      // If user already exists, fallback to sending OTP for login
      final msg = e.message.toLowerCase();
      print('AuthException on register: ${e.message}');
      if (msg.contains('already') || msg.contains('exists') || msg.contains('registered')) {
        try {
          final email = _emailCtrl.text.trim();
          final fullName = _nameCtrl.text.trim();
          final password = _passwordCtrl.text;
          await AuthService.instance.sendEmailOtp(email: email, shouldCreateUser: false);
          if (!mounted) return;
          CustomSnackbar.show(
            context: context,
            message: 'Email sudah terdaftar. Kami kirimkan OTP untuk verifikasi/login.',
            type: SnackbarType.info,
          );
          Navigator.of(context).pushNamed(
            '/verify-otp',
            arguments: {
              'email': email,
              'fullName': fullName,
              'password': password,
            },
          );
        } on AuthException catch (e2) {
          if (!mounted) return;
          CustomSnackbar.show(
            context: context,
            message: e2.message,
            type: SnackbarType.error,
          );
        }
        return;
      }
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: e.message,
        type: SnackbarType.error,
      );
    } catch (e, st) {
      // Show real error string for easier diagnosis during development
      print('Unexpected error on register: $e');
      print(st);
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: e.toString(),
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 110),

                // Headline
                Text(
                  'Daftar Akun',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 32),

                // Full name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Lengkap', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _nameCtrl,
                      hint: 'Nama lengkap Anda',
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                        if (v.trim().length < 2) return 'Nama terlalu pendek';
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Email
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _emailCtrl,
                      hint: 'm@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _passwordCtrl,
                      hint: '••••••••',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                      onSubmitted: (_) => _register(),
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Primary action
                PrimaryButton(
                  label: _loading ? 'Memproses...' : 'Daftar',
                  onPressed: _loading ? null : _register,
                ),

                const SizedBox(height: 16),

                // Divider with 'atau'
                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outline.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Atau', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                    Expanded(child: Divider(color: cs.outline.withOpacity(0.3))),
                  ],
                ),

                const SizedBox(height: 16),

                // Google full-width outlined button (reuse pattern)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      side: BorderSide(color: cs.outline.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                      foregroundColor: cs.onSurface,
                    ),
                    onPressed: () async {
                      try {
                        await AuthService.instance.signInWithGoogle();
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        CustomSnackbar.show(
                          context: context,
                          message: e.message,
                          type: SnackbarType.error,
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/images/logo-google.png', height: 20, fit: BoxFit.contain),
                        const SizedBox(width: 8),
                        const Text('Lanjutkan dengan Google', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom sign-in link
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Sudah punya akun? ', style: theme.textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: Text(
                          'Masuk',
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
