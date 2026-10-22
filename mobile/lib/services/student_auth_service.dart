import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prototype_session.dart';
import '../models/shared_records.dart';
import 'supabase_config.dart';
import 'student_validation.dart';

class StudentAuthService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> register({required String firstName,
    required String lastName, required String email, required String password,
    required String phone, required String studentNumber, required String dob}) async {
    final numberError = StudentValidation.studentNumberError(studentNumber);
    if (numberError != null) throw IntegrationException(numberError);
    final response = await client.auth.signUp(email: email.trim(), password: password,
      emailRedirectTo: SupabaseConfig.redirectUrl,
      data: {'role': 'student', 'firstname': firstName.trim(),
        'lastname': lastName.trim(), 'phonenumber': phone.trim(),
        'studentnumber': studentNumber.trim(), 'dob': dob});
    if (response.user == null) throw const AuthException('Account creation was not completed.');
    // The existing auth.users trigger creates public.students. Do not insert twice.
    // Always return to password login, even when email confirmation is disabled.
    if (response.session != null) await client.auth.signOut(scope: SignOutScope.local);
    PrototypeSession.clear();
  }

  static Future<void> login(String email, String password) async {
    PrototypeSession.clear();
    final response = await client.auth.signInWithPassword(email: email.trim(), password: password);
    if (response.session == null) throw const AuthException('Please verify your email before signing in.');
    try {
      await loadProfile();
    } catch (_) {
      await client.auth.signOut(scope: SignOutScope.local);
      PrototypeSession.clear();
      rethrow;
    }
  }

  static Future<void> loadProfile() async {
    final user = client.auth.currentUser;
    if (user == null) throw const AuthException('Please sign in.');
    if (PrototypeSession.profileUserId != user.id) PrototypeSession.clear();
    final row = await client.from('students').select()
      .eq('studentid', user.id).maybeSingle();
    if (row == null) {
      throw const AuthException(
      'No student record was found for this account. Please use a student account.');
    }
    if (client.auth.currentUser?.id != user.id) throw const AuthException('Your account changed. Please try again.');
    PrototypeSession.profileUserId = user.id;
    PrototypeSession.name = '${row['firstname']} ${row['lastname']}'.trim();
    PrototypeSession.email = user.email ?? row['email'] as String;
    PrototypeSession.phone = row['phonenumber'] as String? ?? '';
    PrototypeSession.studentNumber = row['studentnumber'] as String? ?? '';
    PrototypeSession.dob = user.userMetadata?['dob'] as String? ?? '';
  }

  static Future<void> logout() async {
    await client.auth.signOut(scope: SignOutScope.local);
    PrototypeSession.clear();
  }

  static String errorMessage(Object error) {
    if (error is IntegrationException) return error.message;
    if (error is StorageException) return 'The file could not be uploaded or opened. Check its size and run 02_shared_workflows.sql first.';
    if (error is PostgrestException && error.code == 'P0001') return error.message;
    if (error is PostgrestException && error.code == '23505') return 'You have already submitted an application. Only one application per student is allowed. Check My applications.';
    if (error is AuthException) return error.message;
    if (error is PostgrestException) return 'Could not access the shared data. Check your connection and ensure the integration SQL has been run.';
    return 'Could not connect. Check your internet connection and try again.';
  }
}
