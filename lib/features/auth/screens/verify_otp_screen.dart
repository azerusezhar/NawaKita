import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nawakita/app/widgets/primary_button.dart';
import 'package:nawakita/app/data/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nawakita/app/core/widgets/custom_snackbar.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email, this.fullName, this.password});

  final String email;
  final String? fullName;
  final String? password;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _digitCtrls = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;
  int _seconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Autofocus first field on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 1) {
        t.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  String _collectCode() => _digitCtrls.map((c) => c.text).join();

  void _setCodeFromPaste(String value) {
    final v = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < 6; i++) {
      _digitCtrls[i].text = i < v.length ? v[i] : '';
    }
    final lastIndex = v.length.clamp(0, 6) - 1;
    if (lastIndex >= 0 && lastIndex < 6) {
      _focusNodes[lastIndex].requestFocus();
    }
    setState(() {});
  }

  bool get _isComplete => _collectCode().length == 6;

  Future<void> _verify() async {
    if (!_isComplete) {
      setState(() => _error = 'Mohon isi 6 digit kode.');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.verifyEmailOtp(
        email: widget.email,
        token: _collectCode(),
      );
      // After OTP sign-in
      if (!mounted) return;
      if (widget.password != null && widget.password!.isNotEmpty) {
        // Sign-up flow: set password and profile then go home
        await AuthService.instance.setPasswordAndProfile(
          password: widget.password!,
          fullName: widget.fullName,
        );
        // Pastikan row profiles dibuat/diperbarui
        await AuthService.instance.ensureUserProfile(fullName: widget.fullName);
        // Minta user login manual: keluar dari sesi lalu ke halaman login
        await AuthService.instance.signOut();
        if (!mounted) return;
        HapticFeedback.selectionClick();
        CustomSnackbar.show(
          context: context,
          message: 'Registrasi berhasil. Silakan login untuk melanjutkan.',
          type: SnackbarType.success,
        );
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        // Reset-password flow: go to reset screen with email
        HapticFeedback.selectionClick();
        Navigator.of(context).pushReplacementNamed(
          '/reset-password',
          arguments: {'email': widget.email},
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      HapticFeedback.heavyImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Kode OTP tidak valid. Coba lagi.');
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_seconds > 0) return;
    try {
      await AuthService.instance.sendEmailOtp(email: widget.email);
      if (!mounted) return;
      _startTimer();
      CustomSnackbar.show(
        context: context,
        message: 'Kode OTP telah dikirim ulang.',
        type: SnackbarType.success,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget digitBox(int i) {
      return SizedBox(
        width: 50,
        child: TextField(
          controller: _digitCtrls[i],
          focusNode: _focusNodes[i],
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          keyboardType: TextInputType.number,
          maxLength: 1,
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
          ),
          onChanged: (v) {
            // Handle paste of multiple digits
            if (v.length > 1) {
              _setCodeFromPaste(v);
              if (_isComplete) _verify();
              return;
            }
            // Move focus
            if (v.isNotEmpty && i < 5) {
              _focusNodes[i + 1].requestFocus();
            }
            if (v.isEmpty && i > 0) {
              _focusNodes[i - 1].requestFocus();
            }
            setState(() => _error = null);
            if (v.isNotEmpty) {
              HapticFeedback.selectionClick();
            }
            if (_isComplete) _verify();
          },
          onSubmitted: (_) => _verify(),
        ),
      );
    }

    Future<void> pasteFromClipboard() async {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text ?? '';
      if (text.isEmpty) return;
      _setCodeFromPaste(text);
      HapticFeedback.lightImpact();
      if (_isComplete) _verify();
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
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
                ),
                const SizedBox(height: 88),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/otp.png',
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Verifikasi OTP',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan 6 digit kode yang dikirim ke ${widget.email}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, digitBox),
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _loading ? null : pasteFromClipboard,
                      icon: const Icon(Icons.content_paste),
                      label: const Text('Tempel dari clipboard'),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                  ],

                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: _loading ? 'Memproses...' : 'Verifikasi',
                    onPressed: (!_isComplete || _loading) ? null : _verify,
                  ),

                  const SizedBox(height: 16),
                  Text(
                    _seconds > 0
                        ? 'Kirim ulang kode dalam 0:${_seconds.toString().padLeft(2, '0')}'
                        : 'Tidak menerima kode?',
                    style: theme.textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: _seconds == 0 && !_loading ? _resend : null,
                    child: const Text('Kirim ulang kode'),
                  ),

                  // Removed 'Ganti email' action as requested
                ],
              ),
            ),
          ),
        ),
      );
  }
}
