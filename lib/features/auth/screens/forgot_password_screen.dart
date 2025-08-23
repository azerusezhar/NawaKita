import 'package:flutter/material.dart';
import 'package:nawakita/app/widgets/app_text_field.dart';
import 'package:nawakita/app/widgets/primary_button.dart';
import 'package:nawakita/app/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nawakita/app/core/widgets/custom_snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Send 6-digit OTP to email for verification
      await AuthService.instance.sendEmailOtp(email: _emailCtrl.text.trim(), shouldCreateUser: false);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/verify-otp',
        arguments: {
          'email': _emailCtrl.text.trim(),
          // No password/fullName passed -> VerifyOtpScreen will route to reset-password
        },
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(context: context, message: e.message, type: SnackbarType.error);
    } catch (_) {
      if (!mounted) return;
      CustomSnackbar.show(context: context, message: 'Gagal mengirim kode. Coba lagi.', type: SnackbarType.error);
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
                // Back button styled like LoginScreen
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: const Color(0xFF3B73FF),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _loading ? null : () => Navigator.of(context).pop(),
                      child: const Center(
                        child: Icon(Icons.arrow_back_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Center(
                  child: Text(
                    'Lupa Kata Sandi',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Masukkan email terdaftar Anda. Kami akan mengirimkan kode OTP 6 digit untuk verifikasi.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),

                const SizedBox(height: 28),
                Text('Email', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _emailCtrl,
                  hint: 'm@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    return null;
                  },
                  onSubmitted: (_) => _sendReset(),
                ),

                const SizedBox(height: 24),
                PrimaryButton(
                  label: _loading ? 'Mengirim...' : 'Kirim kode OTP',
                  onPressed: _loading ? null : _sendReset,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
