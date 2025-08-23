import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  // Use a lazy getter so Supabase.instance is only accessed after initialization in main()
  SupabaseClient get _supabase => Supabase.instance.client;

  // Email/password login
  Future<void> signInWithEmail({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Email/password signup with optional profile data
  Future<void> signUpWithEmail({required String email, required String password, String? fullName}) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName} : null,
    );
  }

  // Google OAuth (PKCE enabled in main.dart)
  Future<void> signInWithGoogle({String? redirectTo}) async {
    // Provide a sane default for mobile deep-link callback if none supplied
    final fallbackRedirect = redirectTo ?? 'io.supabase.flutter://callback';
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: fallbackRedirect,
    );
  }

  // Send 6-digit OTP to email (requires Email OTP enabled in Supabase Auth settings)
  Future<void> sendEmailOtp({required String email, bool shouldCreateUser = false}) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
    );
  }

  // Verify 6-digit OTP
  Future<void> verifyEmailOtp({required String email, required String token}) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  // After OTP sign-in, set password and optional profile data
  Future<void> setPasswordAndProfile({required String password, String? fullName}) async {
    await _supabase.auth.updateUser(
      UserAttributes(
        password: password,
        data: fullName != null && fullName.isNotEmpty ? {'full_name': fullName} : null,
      ),
    );
  }

  // Send password reset email with redirect (must be configured in Supabase Auth -> URL config)
  Future<void> sendPasswordResetEmail({required String email, String? redirectTo}) async {
    await _supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Change password by verifying the current password first, then updating to the new password.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final email = await getCurrentUserEmail();
    if (email == null || email.isEmpty) {
      throw AuthException('Tidak ada pengguna yang masuk.');
    }

    // Re-authenticate by signing in with the current password to ensure it's correct
    await _supabase.auth.signInWithPassword(email: email, password: currentPassword);

    // Update to the new password
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  User? get currentUser => _supabase.auth.currentUser;

  /// Ensure a minimal profile row exists in `public.profiles`.
  /// - Creates a row if missing, using provided [fullName]/[avatarUrl] or metadata from Auth.
  /// - If row exists, updates only non-null fields to avoid overwriting with nulls.
  Future<void> ensureUserProfile({String? fullName, String? avatarUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final name = (fullName?.trim().isNotEmpty == true)
        ? fullName!.trim()
        : (meta['full_name'] ?? meta['name']) as String?;
    final avatar = (avatarUrl?.trim().isNotEmpty == true)
        ? avatarUrl!.trim()
        : (meta['avatar_url'] ?? meta['picture']) as String?;

    // Check if profile exists
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      // Insert minimal row; include only fields that are available
      final payload = <String, dynamic>{'id': user.id};
      if (name != null && name.isNotEmpty) payload['full_name'] = name;
      if (avatar != null && avatar.isNotEmpty) payload['avatar_url'] = avatar;
      await _supabase.from('profiles').insert(payload);
      return;
    }

    // Update only when we have non-null values to set
    final updates = <String, dynamic>{};
    if (name != null && name.isNotEmpty) updates['full_name'] = name;
    if (avatar != null && avatar.isNotEmpty) updates['avatar_url'] = avatar;
    if (updates.isEmpty) return;
    updates['id'] = user.id; // required for RLS check and update target
    await _supabase.from('profiles').update(updates).eq('id', user.id);
  }

  /// Get the current user's full name from `public.profiles`.
  /// Returns null if there is no authenticated user or if the profile is missing.
  Future<String?> getCurrentUserFullName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final row = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    final value = row['full_name'];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  /// Get the current user's email from Supabase Auth session.
  /// Returns null if there is no authenticated user.
  Future<String?> getCurrentUserEmail() async {
    final user = _supabase.auth.currentUser;
    return user?.email;
  }

  /// Update user profile with additional fields
  Future<void> updateUserProfile({
    String? fullName,
    String? username,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    String? avatarUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{'id': user.id};
    if (fullName != null && fullName.isNotEmpty) updates['full_name'] = fullName;
    if (username != null && username.isNotEmpty) updates['username'] = username;
    if (phone != null && phone.isNotEmpty) updates['phone'] = phone;
    if (address != null && address.isNotEmpty) updates['address'] = address;
    if (city != null && city.isNotEmpty) updates['city'] = city;
    if (postalCode != null && postalCode.isNotEmpty) updates['postal_code'] = postalCode;
    if (avatarUrl != null && avatarUrl.isNotEmpty) updates['avatar_url'] = avatarUrl;

    if (updates.length > 1) { // More than just the ID
      await _supabase.from('profiles').upsert(updates);
    }
  }

  /// Get complete user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    final row = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();
    
    return row;
  }
}
