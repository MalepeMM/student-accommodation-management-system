import 'package:flutter/material.dart';
import '../../../widgets/prototype_widgets.dart';
class SubmittedPage extends StatelessWidget {
  const SubmittedPage({super.key});
  @override
  Widget build(BuildContext context) => PrototypePage(nav: 1, children: [
    const SizedBox(height: 32), const SuccessMark(), const SizedBox(height: 28),
    const Text('Application submitted', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12), const Text('You can follow each step of your application from your student profile.',
      textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6F7D91))), const SizedBox(height: 28),
    ResponsiveActions(children: [PrototypeButton('Back to home', outline: true, onPressed: () => Navigator.pushReplacementNamed(context, '/explore')),
      PrototypeButton('Track application', onPressed: () => Navigator.pushReplacementNamed(context, '/track'))])]);
}
