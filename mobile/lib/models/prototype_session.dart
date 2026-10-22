import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/student_auth_service.dart';
import '../services/student_validation.dart';
import 'shared_records.dart';
import 'dart:typed_data';

/// Student presentation cache. Identity and core profile fields come from Supabase.
class PrototypeSession {
  PrototypeSession._();
  static String name = '', email = '', phone = '', studentNumber = '', dob = '';
  static Uint8List? profilePhoto;
  static String? profileUserId;
  static Future<void> loadProfile() => StudentAuthService.loadProfile();
  static Future<void> saveProfile({required String fullName, required String emailAddress,
    required String contactPhone, required String number, required String dateOfBirth, Uint8List? photo}) async {
    final numberError = StudentValidation.studentNumberError(number);
    if (numberError != null) throw IntegrationException(numberError);
    final client = StudentAuthService.client;
    final user = client.auth.currentUser;
    if (user == null) throw StateError('Please sign in.');
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final row = await client.from('students').update({
      'firstname': parts.first, 'lastname': parts.skip(1).join(' '),
      'phonenumber': contactPhone, 'studentnumber': number,
    }).eq('studentid', user.id).select('studentid').single();
    if (row['studentid'] != user.id) throw StateError('Profile was not saved.');
    if (client.auth.currentUser?.id != user.id) throw StateError('Your account changed. Please try again.');
    await client.auth.updateUser(UserAttributes(data: {'dob': dateOfBirth}));
    // Email is an authentication identifier; editing it needs its own verification flow.
    if (client.auth.currentUser?.id != user.id) throw StateError('Your account changed. Please try again.');
    name = fullName; phone = contactPhone; studentNumber = number;
    // DOB uses Auth metadata. Photos remain in memory until storage is configured.
    dob = dateOfBirth; profilePhoto = photo ?? profilePhoto;
  }
  static Future<void> signOut() async {
    await StudentAuthService.logout();
    await (await SharedPreferences.getInstance()).remove('butis_bloc_personal_details_v1');
  }
  static void clear() {
    name = ''; email = ''; phone = ''; studentNumber = ''; dob = '';
    profileUserId = null; profilePhoto = null;

  }
}