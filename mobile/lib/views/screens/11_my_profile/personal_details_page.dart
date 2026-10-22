import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/student_validation.dart';
import '../../../models/prototype_session.dart';
import '../../../widgets/prototype_widgets.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});
  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}
class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    fields = [PrototypeSession.name, PrototypeSession.email, PrototypeSession.phone,
      PrototypeSession.studentNumber, PrototypeSession.dob].map((v) => TextEditingController(text: v)).toList();
  }
  @override
  void dispose() { for (final c in fields) { c.dispose(); } super.dispose(); }
  Future<void> save() async {
    if (!form.currentState!.validate() || saving) return;
    FocusScope.of(context).unfocus();
    setState(() => saving = true);
    try {
      await PrototypeSession.saveProfile(fullName: fields[0].text.trim(), emailAddress: fields[1].text.trim(),
        contactPhone: fields[2].text.trim(), number: fields[3].text.trim(), dateOfBirth: fields[4].text.trim());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your changes could not be saved. Please try again.')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  Widget field(int i, String label, IconData icon) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(height: 8),
    TextFormField(key: ValueKey('profile-field-$i'), controller: fields[i], enabled: !saving,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: i == 3 ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)] : null,
      keyboardType: i == 3 ? TextInputType.number : i == 1 ? TextInputType.emailAddress : i == 2 ? TextInputType.phone : TextInputType.text,
      textCapitalization: i == 0 ? TextCapitalization.words : TextCapitalization.none,
      readOnly: i == 4 || i == 1,
      onTap: i != 4 ? null : () async {
        final now = DateTime.now();
        final parsed = DateTime.tryParse(fields[4].text.replaceAll('/', '-'));
        final picked = await showDatePicker(context: context,
          initialDate: parsed != null && !parsed.isAfter(now) && parsed.year >= 1900 ? parsed : DateTime(now.year - 18),
          firstDate: DateTime(1900), lastDate: now);
        if (picked != null && mounted) fields[4].text = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
      },
      decoration: prototypeInput(i == 4 ? 'YYYY/MM/DD' : label, icon: icon),
      validator: (v) {
        final text = v?.trim() ?? '';
        if (text.isEmpty) return 'Please enter ${label.toLowerCase()}';
        if (i == 3) return StudentValidation.studentNumberError(v);
        if (i == 0 && text.length < 2) return 'Enter your full name';
        if (i == 1 && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) return 'Enter a valid email address';
        if (i == 2 && !RegExp(r'^\+?[0-9 ()-]{9,16}$').hasMatch(text)) return 'Enter a valid phone number';
        if (i == 4) {
          final date = DateTime.tryParse(text.replaceAll('/', '-'));
          if (date == null || date.isAfter(DateTime.now()) || date.year < 1900) return 'Choose a valid date of birth';
        }
        return null;
      })]);
  @override
  Widget build(BuildContext context) => PrototypePage(title: 'Personal details', children: [
    const Text('Make yourself at home.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), const Text('Keep your student and contact information up to date.', style: TextStyle(color: Color(0xFF6F7D91))),
    const SizedBox(height: 12), const Text('Email changes require verification. Profile photos are currently session-only.'),
    const SizedBox(height: 28), OutlinePanel(child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Row(children: [Icon(Icons.person_outline_rounded, color: prototypeBlue), SizedBox(width: 10),
        Expanded(child: Text('Your information', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 24), ResponsiveGrid(children: [
        field(0, 'Full name', Icons.person_outline), field(1, 'Email address', Icons.mail_outline),
        field(2, 'Phone number', Icons.phone_outlined), field(3, 'Student number', Icons.school_outlined),
        field(4, 'Date of birth', Icons.calendar_today_outlined)]),
      const SizedBox(height: 28), ResponsiveActions(children: [
        PrototypeButton('Cancel', outline: true, onPressed: saving ? null : () => Navigator.pop(context, false)),
        PrototypeButton(saving ? 'Saving…' : 'Save changes', onPressed: saving ? null : save)])])))]);
}
