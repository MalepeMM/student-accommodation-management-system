import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/prototype_session.dart';
import '../../../widgets/prototype_widgets.dart';
import '../../../widgets/student_bed_panel.dart';

class ProfilePage extends StatefulWidget {
  final Widget? accommodationPanel;
  const ProfilePage({super.key, this.accommodationPanel});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  bool uploading = false;
  Future<void> edit() async {
    final changed = await Navigator.pushNamed(context, '/personal-details');
    if (!mounted) return;
    setState(() {});
    if (changed == true) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your personal details have been updated.')));
  }
  Future<void> pickPhoto() async {
    if (uploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'], withData: true);
      if (result == null || !mounted) return;
      final bytes = result.files.single.bytes;
      if (bytes == null || bytes.length > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose an image smaller than 2 MB.'))); return;
      }
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 512);
      final frame = await codec.getNextFrame(); frame.image.dispose(); codec.dispose();
      if (!mounted) return;
      setState(() => uploading = true);
      await PrototypeSession.saveProfile(fullName: PrototypeSession.name, emailAddress: PrototypeSession.email,
        contactPhone: PrototypeSession.phone, number: PrototypeSession.studentNumber,
        dateOfBirth: PrototypeSession.dob, photo: bytes);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this photo. Please choose a valid image and try again.')));
    } finally { if (mounted) setState(() => uploading = false); }
  }
  Widget detail(String label, String value, IconData icon) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: prototypeBlue, size: 21)), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6F7D91))),
      const SizedBox(height: 3), Text(value.isEmpty ? 'Not added yet' : value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]))]);
  @override
  Widget build(BuildContext context) => PrototypePage(title: 'My profile', back: false, nav: 3, children: [
    const Text('Your space. Your story.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6), const Text('Manage your information and your accommodation journey.', style: TextStyle(color: Color(0xFF6F7D91))),
    const SizedBox(height: 24),
    ClipRRect(borderRadius: BorderRadius.circular(22), child: Stack(children: [
      Positioned.fill(child: Image.asset('assets/images/building_bg.png', fit: BoxFit.cover)),
      const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        colors: [Color(0xF0122D60), Color(0xA02457DB)], begin: Alignment.centerLeft, end: Alignment.centerRight)))),
      Padding(padding: const EdgeInsets.all(28), child: LayoutBuilder(builder: (context, box) {
        final photo = Stack(children: [CircleAvatar(radius: 48, backgroundColor: Colors.white,
          backgroundImage: PrototypeSession.profilePhoto == null ? null : MemoryImage(PrototypeSession.profilePhoto!),
          child: PrototypeSession.profilePhoto == null ? const Icon(Icons.person_outline, color: prototypeBlue, size: 50) : null),
          Positioned(right: 0, bottom: 0, child: Material(color: prototypeBlue, shape: const CircleBorder(),
            child: IconButton(tooltip: 'Change profile photo (this session only)', onPressed: uploading ? null : pickPhoto,
              icon: Icon(uploading ? Icons.hourglass_empty : Icons.camera_alt_outlined, size: 18, color: Colors.white))))]);
        final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('STUDENT PROFILE', style: TextStyle(color: Color(0xFFBDCEFF), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
          const SizedBox(height: 8), Text(PrototypeSession.name.isEmpty ? 'Welcome, student' : PrototypeSession.name,
            style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4), Text(PrototypeSession.email.isEmpty ? 'Add your contact details below' : PrototypeSession.email,
            style: const TextStyle(color: Colors.white, fontSize: 15)), const SizedBox(height: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: const Color(0x332E7DFF), borderRadius: BorderRadius.circular(8)),
            child: const Text('Student', style: TextStyle(color: Colors.white, fontSize: 13)))]);
        return box.maxWidth < 480 ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [photo, const SizedBox(height: 20), info])
          : Row(children: [photo, const SizedBox(width: 24), Expanded(child: info)]);
      }))])),
    const SizedBox(height: 24), widget.accommodationPanel ?? const StudentBedPanel(),
    const SizedBox(height: 24), OutlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, children: [
        const Text('Personal details', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
        TextButton.icon(onPressed: edit, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit details'))]),
      const SizedBox(height: 24), ResponsiveGrid(children: [
        detail('Full name', PrototypeSession.name, Icons.person_outline), detail('Email address', PrototypeSession.email, Icons.mail_outline),
        detail('Phone number', PrototypeSession.phone, Icons.phone_outlined), detail('Student number', PrototypeSession.studentNumber, Icons.school_outlined),
        detail('Date of birth', PrototypeSession.dob, Icons.calendar_today_outlined)]),
      const SizedBox(height: 24), Align(alignment: Alignment.centerLeft,
        child: PrototypeButton('Edit personal details', onPressed: edit))])),
    const SizedBox(height: 20), Align(alignment: Alignment.centerLeft,
      child: TextButton.icon(icon: const Icon(Icons.logout), label: const Text('Sign out'), onPressed: () async {
        try {
          await PrototypeSession.signOut();
          if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        } catch (_) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not sign out. Please try again.')));
        }
      })),
    const SizedBox(height: 24), ResponsiveGrid(children: [
      _action('My application', 'Follow your application progress.', Icons.article_outlined, '/track'),
      _action('Maintenance requests', 'Report an issue or view your requests.', Icons.build_outlined, '/requests')])]);
  Widget _action(String title, String subtitle, IconData icon, String route) => OutlinePanel(child: InkWell(
    borderRadius: BorderRadius.circular(12), onTap: () => Navigator.pushNamed(context, route), child: Row(children: [
      Icon(icon, color: prototypeBlue, size: 28), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 14, color: Color(0xFF6F7D91)))])),
      const Icon(Icons.chevron_right, color: prototypeBlue)])));
}
