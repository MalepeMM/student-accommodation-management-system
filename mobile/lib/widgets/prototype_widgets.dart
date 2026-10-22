import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'bottom_nav.dart';

const prototypeBlue = Color(0xFF2457DB);
const prototypeGrey = Color(0xFFE2E2E2);

class PrototypePage extends StatelessWidget {
  final String? title;
  final int? nav;
  final List<Widget> children;
  final bool back;
  final EdgeInsets padding;
  const PrototypePage({super.key, this.title, this.nav, required this.children,
    this.back = true, this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, viewport) {
    final wide = viewport.maxWidth >= 1000;
    final body = SafeArea(child: Align(alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1120),
        child: SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding == EdgeInsets.zero ? EdgeInsets.zero : EdgeInsets.all(viewport.maxWidth < 400 ? 16 : wide ? 32 : 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)))));
    return Scaffold(
      appBar: title == null ? null : AppBar(title: Text(title!, maxLines: 2, style: const TextStyle(fontSize: 19)),
        toolbarHeight: 72,
        leading: back ? IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back_rounded), onPressed: () => closePage(context)) : null,
        automaticallyImplyLeading: false),
      bottomNavigationBar: nav == null || wide ? null : BottomNav(currentIndex: nav!),
      body: wide && nav != null ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SideNavigation(currentIndex: nav!), Expanded(child: body)]) : body);
  });
}

/// Wraps below the breakpoint, without shrinking text or overflowing a phone.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint, gap;
  final int columns;
  const ResponsiveGrid({super.key, required this.children, this.breakpoint = 680, this.gap = 20, this.columns = 2});
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final count = constraints.maxWidth < breakpoint ? 1 : columns;
    final width = (constraints.maxWidth - gap * (count - 1)) / count;
    return Wrap(spacing: gap, runSpacing: gap, children: children.map((child) => SizedBox(width: width, child: child)).toList());
  });
}
class ResponsiveActions extends StatelessWidget {
  final List<Widget> children;
  const ResponsiveActions({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ResponsiveGrid(breakpoint: 440, gap: 12, children: children);
}

void closePage(BuildContext context) {
  if (Navigator.canPop(context)) { Navigator.pop(context); }
  else { Navigator.pushReplacementNamed(context, '/explore'); }
}
class BrandLogo extends StatelessWidget {
  final double width;
  const BrandLogo({super.key, this.width = 160});
  @override
  Widget build(BuildContext context) => Image.asset('assets/images/logo.png',
    width: width, fit: BoxFit.contain, semanticLabel: "Buti’s Bloc Student Accommodation");
}
class PrototypeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool grey, outline;
  const PrototypeButton(this.text, {super.key, required this.onPressed, this.grey = false, this.outline = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ElevatedButton(onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: outline ? const Color(0xFFEDF3FF) : prototypeBlue,
        foregroundColor: outline ? prototypeBlue : Colors.white,
        elevation: 0, minimumSize: const Size(0, 52),
        side: outline ? const BorderSide(color: Color(0xFFC6D6FF), width: 1) : BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Text(text, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))));
}
InputDecoration prototypeInput(String hint, {IconData? icon}) => InputDecoration(
  hintText: hint, hintStyle: const TextStyle(color: Color(0xFF6F7D91), fontSize: 15),
  prefixIcon: icon == null ? null : Icon(icon, color: prototypeBlue, size: 22),
  filled: true, fillColor: const Color(0xFFF8FAFE),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE3EF))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDCE3EF))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8)));
class OutlinePanel extends StatelessWidget {
  final Widget child;
  final Color border;
  const OutlinePanel({super.key, required this.child, this.border = const Color(0xFFD8D8D8)});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE4EAF4)),
      boxShadow: const [BoxShadow(color: Color(0x060F2855), blurRadius: 20, offset: Offset(0, 6))],
      borderRadius: BorderRadius.circular(20)), child: child);
}
class SuccessMark extends StatelessWidget {
  const SuccessMark({super.key});
  @override
  Widget build(BuildContext context) => Center(child: Container(
    width: 230, height: 230, padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(color: Color(0xFFEAF2FE), shape: BoxShape.circle),
    child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF9DBDFF), shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, color: Colors.white, size: 140))));
}
class UploadTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const UploadTile({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(button: true, label: label,
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22),
      child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: const [BoxShadow(color: Color(0x080F2855), blurRadius: 12)]),
        child: Column(children: [const Icon(Icons.cloud_upload_outlined, size: 34, color: prototypeBlue), const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]))));
}
