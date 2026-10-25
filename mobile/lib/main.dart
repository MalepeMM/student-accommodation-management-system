import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'views/screens/01_login/reset_password_page.dart';
import 'routes/app_routes.dart';
import 'models/prototype_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
      url: SupabaseConfig.url, anonKey: SupabaseConfig.publishableKey);
  runApp(const ButisBlocApp());
}

class ButisBlocApp extends StatefulWidget {
  const ButisBlocApp({super.key});
  @override
  State<ButisBlocApp> createState() => _ButisBlocAppState();
}

class _ButisBlocAppState extends State<ButisBlocApp> {
  final navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? subscription;
  @override
  void initState() {
    super.initState();
    subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) PrototypeSession.clear();
      if (state.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.currentState?.pushAndRemoveUntil(
              MaterialPageRoute<void>(
                  builder: (_) => const ResetPasswordPage()),
              (_) => false);
        });
      }
    }, onError: (Object error) {
      // A refresh/network failure must not crash the interface.
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      navigatorKey: navigator,
      debugShowCheckedModeBanner: false,
      title: "Buti’s Bloc | Student Living",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2457DB),
            primary: const Color(0xFF2457DB),
            surface: Colors.white),
        scaffoldBackgroundColor: const Color(0xFFF5F7FC),
        textTheme: const TextTheme(
            bodyMedium: TextStyle(
                color: Color(0xFF28364D), fontSize: 16, height: 1.45)),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF152642),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
                color: Color(0xFF152642),
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        checkboxTheme: CheckboxThemeData(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        textButtonTheme: TextButtonThemeData(
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF2457DB))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2457DB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 52),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700))),
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes);
}
