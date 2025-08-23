import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nawakita/app/widgets/primary_button.dart';
import 'package:nawakita/app/widgets/app_text_field.dart';
import 'package:nawakita/app/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nawakita/app/core/widgets/custom_snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    // Navigate to home after any successful sign-in (including Google OAuth)
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn) {
        // Ensure profile exists/updated (covers Google OAuth flow)
        await AuthService.instance.ensureUserProfile();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Ensure profile exists for email/password flow as well
      await AuthService.instance.ensureUserProfile();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(context: context, message: e.message, type: SnackbarType.error);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(context: context, message: 'Terjadi kesalahan. Coba lagi.', type: SnackbarType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header back icon
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: const Color(0xFF3B73FF),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        // Kembali ke onboarding
                        Navigator.of(context).pushReplacementNamed('/onboarding');
                      },
                      child: const Center(
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 110),

                // Headline
                Text(
                  'Halo!\nSelamat datang kembali.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 32),

                // Fields card-like
                // Labels + fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: Theme.of(context).textTheme.labelLarge),
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text('Password', style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/forgot-password');
                          },
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ],
                    ),
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
                      onSubmitted: (_) => _login(),
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
                  label: _loading ? 'Memproses...' : 'Masuk',
                  onPressed: _loading ? null : _login,
                ),

                const SizedBox(height: 16),

                // Divider with 'atau'
                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('Atau', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                    Expanded(child: Divider(color: cs.outline.withValues(alpha: 0.3))),
                  ],
                ),

                const SizedBox(height: 16),

                // Google full-width outlined button (logo only)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                      foregroundColor: cs.onSurface,
                    ),
                    onPressed: () async {
                      try {
                        await AuthService.instance.signInWithGoogle();
                      } on AuthException catch (e) {
                        if (!mounted) return;
                        CustomSnackbar.show(context: context, message: e.message, type: SnackbarType.error);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo-google.png',
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        const Text('Lanjutkan dengan Google', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom sign-up link
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Belum punya akun? ', style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/register');
                        },
                        child: Text('Daftar', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
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

