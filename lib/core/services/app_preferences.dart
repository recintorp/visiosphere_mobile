import 'package:shared_preferences/shared_preferences.dart';

/// Small, non-secret preferences that must OUTLIVE a sign-out.
///
/// Credentials live in SecureStorageService. These are the opposite: UI state
/// that would be annoying to lose. Signing out must not send a returning user
/// back through the first-run tour, and must not forget the id they asked to be
/// remembered — so [preserveAcrossLogout] lists exactly what a logout keeps and
/// AuthProvider.logout() clears everything else by name rather than calling
/// prefs.clear(), which used to wipe these too.
class AppPreferences {
  AppPreferences._();

  static const _keyHasSeenOnboarding = 'hasSeenOnboarding';
  static const _keyRememberMe        = 'rememberMe';
  static const _keyRememberedLoginId = 'rememberedLoginId';
  static const _keyFailedLogins      = 'failedLoginAttempts';
  static const _keyLockedUntil       = 'loginLockedUntilMs';

  static const Set<String> preserveAcrossLogout = {
    _keyHasSeenOnboarding,
    _keyRememberMe,
    _keyRememberedLoginId,
    // A lock that a sign-out could clear would be no lock at all: the sign-in
    // screen is reached BY signing out.
    _keyFailedLogins,
    _keyLockedUntil,
  };

  /// Wrong passwords allowed before the sign-in button is disabled.
  static const int maxFailedLogins = 5;

  /// How long the sign-in button stays disabled. The user-facing wording —
  /// "Too many attempts. Try again in 1 minute." — is written against this
  /// value, so change both together.
  static const Duration loginLockDuration = Duration(minutes: 1);

  // ---------------------------------------------------------------------
  // Onboarding
  // ---------------------------------------------------------------------
  /// True once the user has finished (or skipped) the first-run tour, or signed
  /// in at least once. The tour is an introduction, not a gate: after this,
  /// splash goes straight to the sign-in screen.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, true);
  }

  // ---------------------------------------------------------------------
  // Remember me
  // ---------------------------------------------------------------------
  /// The sign-in ID to pre-fill, or null when "Remember me" is off.
  ///
  /// Only the ID is kept — never the password. Pre-filling a password would put
  /// a working credential one tap from anyone holding the unlocked phone, which
  /// is the wrong trade for a system carrying resident health records.
  static Future<String?> rememberedLoginId() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_keyRememberMe) ?? false)) return null;
    final id = prefs.getString(_keyRememberedLoginId);
    return (id != null && id.isNotEmpty) ? id : null;
  }

  /// Persist (or forget) the sign-in ID. Unchecking clears the stored id
  /// immediately rather than leaving it readable until the next sign-in.
  static Future<void> setRememberMe(bool remember, String loginId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, remember);
    if (remember && loginId.trim().isNotEmpty) {
      await prefs.setString(_keyRememberedLoginId, loginId.trim());
    } else {
      await prefs.remove(_keyRememberedLoginId);
    }
  }

  // ---------------------------------------------------------------------
  // Sign-in throttling
  // ---------------------------------------------------------------------
  /// WHY THIS IS ON DISK AND NOT JUST IN THE LOGIN SCREEN'S STATE
  ///
  /// A counter held in widget state is reset by killing the app, which is one
  /// swipe. Anyone guessing passwords would simply restart between batches and
  /// the lock would never once take effect — it would look like a feature and
  /// behave like nothing. SharedPreferences survives a restart, so five wrong
  /// passwords cost a real minute.
  ///
  /// This is a deterrent on THIS DEVICE, not a security boundary: the store is
  /// clearable, and someone determined can wipe app data. The boundary is the
  /// backend's authLimiter (10 attempts per 15 minutes). This closes the gap
  /// where a phone in the wrong hands can be hammered with guesses at full
  /// speed and shows the user why it stopped.

  /// How long the sign-in button must stay disabled, or null if it is free.
  static Future<Duration?> loginLockRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_keyLockedUntil);
    if (until == null) return null;

    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) {
      // Expired — tidy up so the count starts fresh next time.
      await prefs.remove(_keyLockedUntil);
      await prefs.remove(_keyFailedLogins);
      return null;
    }
    return Duration(milliseconds: remaining);
  }

  /// Record one rejected credential. Returns the lock duration if this attempt
  /// was the one that tripped it, otherwise null.
  static Future<Duration?> registerFailedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_keyFailedLogins) ?? 0) + 1;
    await prefs.setInt(_keyFailedLogins, attempts);

    if (attempts < maxFailedLogins) return null;

    await prefs.setInt(
      _keyLockedUntil,
      DateTime.now().add(loginLockDuration).millisecondsSinceEpoch,
    );
    return loginLockDuration;
  }

  /// Wipe the failure count. Called on a successful sign-in — including one
  /// that still has 2FA ahead of it, since the password was correct.
  static Future<void> clearLoginFailures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFailedLogins);
    await prefs.remove(_keyLockedUntil);
  }
}
