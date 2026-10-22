import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const url = 'https://ibzbavponwdpvmdemqdi.supabase.co';
  // Public client key only. Never use a service-role key in Flutter.
  static const publishableKey = 'sb_publishable_MKZ9lNnvWA37hGg0kAsvmg_R22mpwBv';
  static String get redirectUrl => kIsWeb
      ? '${Uri.base.origin}/'
      : 'com.butisbloc.student://login-callback/';
}
