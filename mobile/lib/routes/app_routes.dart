import 'package:flutter/material.dart';
import '../widgets/student_gate.dart';
import '../views/screens/11_my_profile/personal_details_page.dart';
import '../views/screens/01_login/login_page.dart';
import '../views/screens/02_create_account/create_account_page.dart';
import '../views/screens/03_account_created/account_created_page.dart';
import '../views/screens/04_explore_accommodation/explore_page.dart';
import '../views/screens/05_single_room/single_room_page.dart';
import '../views/screens/06_sharing_room/sharing_room_page.dart';
import '../views/screens/07_application_form/application_form_page.dart';
import '../views/screens/08_application_submitted/submitted_page.dart';
import '../views/screens/09_track_application/track_page.dart';
import '../views/screens/10_application_details/details_page.dart';
import '../views/screens/11_my_profile/profile_page.dart';
import '../views/screens/12_maintenance_request/maintenance_page.dart';
import '../views/screens/13_my_requests/my_requests_page.dart';

/// Centralized named routes. Browsing listings is public; sign-in is optional until applying.
class AppRoutes {
  AppRoutes._();
  static const explore = '/explore';
  static const login = '/login';
  static const createAccount = '/create-account';
  static const accountCreated = '/account-created';
  static const singleRoom = '/single-room';
  static const sharingRoom = '/sharing-room';
  static const apply = '/apply';
  static const submitted = '/submitted';
  static const track = '/track';
  static const details = '/details';
  static const profile = '/profile';
  static const maintenance = '/maintenance';
  static const requests = '/requests';

  static Map<String, WidgetBuilder> get routes => {
    '/personal-details': (_) => const StudentGate(child: PersonalDetailsPage()),
    login: (_) => const LoginPage(), createAccount: (_) => const CreateAccountPage(),
    accountCreated: (_) => const AccountCreatedPage(), explore: (_) => const ExplorePage(),
    singleRoom: (_) => const SingleRoomPage(), sharingRoom: (_) => const SharingRoomPage(),
    apply: (_) => const StudentGate(child: ApplicationFormPage()), submitted: (_) => const StudentGate(child: SubmittedPage()),
    track: (_) => const StudentGate(child: TrackPage()), details: (_) => const StudentGate(child: DetailsPage()),
    profile: (_) => const StudentGate(child: ProfilePage()), maintenance: (_) => const StudentGate(child: MaintenancePage()),
    requests: (_) => const StudentGate(child: MyRequestPage()),
  };
}
