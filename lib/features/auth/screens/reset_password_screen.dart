import 'package:flutter/material.dart';
import 'package:nawakita/app/widgets/app_text_field.dart';
import 'package:nawakita/app/widgets/primary_button.dart';
import 'package:nawakita/app/data/auth_service.dart';
import 'package:nawakita/app/core/widgets/custom_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.email});

  final String? email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pwdCtrl = TextEditingController();
  final _pwd2Ctrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    _pwd2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.setPasswordAndProfile(password: _pwdCtrl.text);
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Kata sandi berhasil diperbarui. Silakan login kembali.',
        type: SnackbarType.success,
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: 'Gagal memperbarui kata sandi. Coba lagi.',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button style (blue rounded)
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
                    'Atur Ulang Kata Sandi',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.email == null || widget.email!.isEmpty
                        ? 'Masukkan kata sandi baru Anda.'
                        : 'Masukkan kata sandi baru untuk ${widget.email}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),

                const SizedBox(height: 28),
                Text('Kata sandi baru', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _pwdCtrl,
                  hint: '••••••••',
                  obscureText: _obscure1,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                    icon: Icon(_obscure1 ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  ),
                ),

                const SizedBox(height: 18),
                Text('Konfirmasi kata sandi', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _pwd2Ctrl,
                  hint: '••••••••',
                  obscureText: _obscure2,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    if (v != _pwdCtrl.text) return 'Tidak sama dengan kata sandi';
                    return null;
                  },
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                    icon: Icon(_obscure2 ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  ),
                ),

                const SizedBox(height: 24),
                PrimaryButton(
                  label: _loading ? 'Menyimpan...' : 'Simpan kata sandi',
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
