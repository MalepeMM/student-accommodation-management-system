import 'package:flutter/material.dart';
import '../../../widgets/prototype_widgets.dart';
class AccountCreatedPage extends StatelessWidget {
  const AccountCreatedPage({super.key});
  @override
  Widget build(BuildContext context) => PrototypePage(nav: 1, children: [
    const SizedBox(height: 32), const SuccessMark(), const SizedBox(height: 28),
    const Text('Your next chapter starts here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12), const Text('Check your email for a verification link if confirmation is enabled. Then return here and sign in with your email and password.',
      textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6F7D91))), const SizedBox(height: 28),
    PrototypeButton('Go to login', onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false))]);
}
