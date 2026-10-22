import 'package:flutter/material.dart';
import '../../../services/student_auth_service.dart';
import '../../../services/supabase_config.dart';
import '../../../widgets/prototype_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false, hidden = true;
  Future<void> resetPassword() async {
    if (busy) return;
    final address = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter your email address above first.')));
      return;
    }
    setState(() => busy = true);
    try {
      await StudentAuthService.client.auth.resetPasswordForEmail(address,
          redirectTo: SupabaseConfig.redirectUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'If an account exists, a password reset link will be emailed to you.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(StudentAuthService.errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Widget hero() => ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(children: [
        Positioned.fill(
            child: Image.asset('assets/images/building_bg.png',
                fit: BoxFit.cover)),
        const Positioned.fill(
            child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Color(0x33132955), Color(0xF0122D60)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)))),
        Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('YOUR NEXT CHAPTER',
                      style: TextStyle(
                          color: Color(0xFFCFDCFF),
                          letterSpacing: 2,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text('A place to belong.\nA space to grow.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.2)),
                  const SizedBox(height: 14),
                  const Text('Discover student living at Buti’s Bloc.',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 18),
                  ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/explore'),
                      child: const Text('Explore accommodation'))
                ]))
      ]));
  Widget loginForm() => OutlinePanel(
      child: Form(
          key: form,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const BrandLogo(width: 190),
            const SizedBox(height: 28),
            const Text('Welcome back',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Your next chapter starts here.',
                style: TextStyle(color: Color(0xFF6F7D91))),
            const SizedBox(height: 28),
            const Text('Email address',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    prototypeInput('you@example.com', icon: Icons.mail_outline),
                validator: (v) => v == null ||
                        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                            .hasMatch(v.trim())
                    ? 'Enter a valid email address'
                    : null),
            const SizedBox(height: 20),
            const Text('Password',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextFormField(
                controller: password,
                obscureText: hidden,
                decoration: prototypeInput('Enter your password',
                        icon: Icons.lock_outline)
                    .copyWith(
                        suffixIcon: IconButton(
                            tooltip: hidden ? 'Show password' : 'Hide password',
                            onPressed: () => setState(() => hidden = !hidden),
                            icon: Icon(hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined))),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter your password' : null),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: busy ? null : resetPassword,
                    child: const Text('Forgot password?'))),
            const SizedBox(height: 12),
            PrototypeButton(busy ? 'Please wait…' : 'Login',
                onPressed: busy
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        setState(() => busy = true);
                        try {
                          await StudentAuthService.login(
                              email.text, password.text);
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/explore', (_) => false);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    StudentAuthService.errorMessage(error))));
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      }),
            const SizedBox(height: 14),
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('New to Buti’s Bloc?',
                      style: TextStyle(fontSize: 14)),
                  TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/create-account'),
                      child: const Text('Create an account'))
                ])
          ])));
  @override
  Widget build(BuildContext context) => Scaffold(
      body: SafeArea(
          child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.all(box.maxWidth < 400 ? 16 : 32),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: box.maxWidth >= 900
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Expanded(
                                          child: SizedBox(
                                              height: 650, child: hero())),
                                      const SizedBox(width: 32),
                                      Expanded(child: loginForm())
                                    ])
                              : Column(children: [
                                  hero(),
                                  const SizedBox(height: 24),
                                  loginForm()
                                ])))))));
}
