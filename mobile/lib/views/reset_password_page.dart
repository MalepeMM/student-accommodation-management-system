import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/student_auth_service.dart';
import '../../../widgets/prototype_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}
class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final password = TextEditingController(), confirm = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  @override
  void dispose() { password.dispose(); confirm.dispose(); super.dispose(); }
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await StudentAuthService.client.auth.updateUser(UserAttributes(password: password.text));
      await StudentAuthService.logout();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Sign in with your new password.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(StudentAuthService.errorMessage(error))));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Reset password')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480), child: Form(key: form, child: Column(children: [
        TextFormField(controller: password, obscureText: true, decoration: prototypeInput('New password'),
          validator: (v) => (v?.length ?? 0) < 6 ? 'Use at least 6 characters' : null),
        const SizedBox(height: 20),
        TextFormField(controller: confirm, obscureText: true, decoration: prototypeInput('Confirm password'),
          validator: (v) => v != password.text ? 'Passwords do not match' : null),
        const SizedBox(height: 24), PrototypeButton(busy ? 'Saving…' : 'Save password', onPressed: busy ? null : save),
      ]))))));
}
