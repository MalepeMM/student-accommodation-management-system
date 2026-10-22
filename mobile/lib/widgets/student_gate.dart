import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/student_auth_service.dart';
import '../views/screens/01_login/login_page.dart';

class StudentGate extends StatefulWidget {
  final Widget child;
  const StudentGate({super.key, required this.child});
  @override
  State<StudentGate> createState() => _StudentGateState();
}
class _StudentGateState extends State<StudentGate> {
  Future<void>? profile;
  String? userId;
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: StudentAuthService.client.auth.onAuthStateChange, builder: (context, auth) {
      final currentId = StudentAuthService.client.auth.currentUser?.id;
      if (currentId == null) return const LoginPage();
      if (userId != currentId) {
        userId = currentId;
        profile = StudentAuthService.loadProfile();
      }
      return FutureBuilder<void>(future: profile, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError || auth.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('Student account')),
          body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
            Text(StudentAuthService.errorMessage(snapshot.error ?? auth.error!)),
            TextButton(onPressed: () => setState(() => profile = StudentAuthService.loadProfile()), child: const Text('Retry')),
            TextButton(onPressed: () async {
              try {
                await StudentAuthService.logout();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              } catch (error) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(StudentAuthService.errorMessage(error))));
              }
            }, child: const Text('Sign out')),
          ])));
        }
        // Changing account discards any private child page state from the previous user.
        return KeyedSubtree(key: ValueKey(currentId), child: widget.child);
      });
    });
}
