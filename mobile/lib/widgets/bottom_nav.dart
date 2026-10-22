import 'package:flutter/material.dart';
import '../models/prototype_session.dart';

const destinations = ['/explore', '/track', '/maintenance', '/profile'];
const labels = ['Home', 'Applications', 'Maintenance', 'Profile'];
const icons = [
  Icons.home_outlined,
  Icons.article_outlined,
  Icons.build_outlined,
  Icons.account_circle_outlined
];
void goTo(BuildContext context, int current, int index) {
  if (current != index) {
    Navigator.pushReplacementNamed(context, destinations[index]);
  }
}

class BottomNav extends StatelessWidget {
  final int currentIndex;
  const BottomNav({super.key, required this.currentIndex});
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      child: SafeArea(
          top: false,
          child: Row(
              children: List.generate(
                  4,
                  (i) => Expanded(
                      child: Tooltip(
                          message: labels[i],
                          child: InkWell(
                              onTap: () => goTo(context, currentIndex, i),
                              child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  child: Icon(icons[i],
                                      size: 26,
                                      color: currentIndex == i
                                          ? const Color(0xFF2457DB)
                                          : const Color(0xFF8793A7))))))))));
}

class SideNavigation extends StatelessWidget {
  final int currentIndex;
  const SideNavigation({super.key, required this.currentIndex});
  @override
  Widget build(BuildContext context) => Container(
      width: 220,
      color: Colors.white,
      child: Column(children: [
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Image.asset('assets/images/logo.png', width: 165)),
                  ...List.generate(
                      4,
                      (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                  selected: currentIndex == i,
                                  selectedTileColor: const Color(0xFFEDF3FF),
                                  selectedColor: const Color(0xFF2457DB),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  leading: Icon(icons[i]),
                                  title: Text(labels[i]),
                                  onTap: () =>
                                      goTo(context, currentIndex, i)))))
                ]))),
        const Divider(height: 1),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Material(
                color: Colors.transparent,
                child: ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () => _logOut(context))))
      ]));
}

Future<void> _logOut(BuildContext context) async {
  try {
    await PrototypeSession.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not sign out. Please try again.')));
    }
  }
}
