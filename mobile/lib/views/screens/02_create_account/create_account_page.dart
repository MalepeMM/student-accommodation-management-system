import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/student_validation.dart';
import '../../../widgets/prototype_widgets.dart';
import '../../../services/student_auth_service.dart';
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});
  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}
class _CreateAccountPageState extends State<CreateAccountPage> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(8, (_) => TextEditingController());
  bool busy = false;
  bool agreed = false, hidden = true, confirmHidden = true;
  @override
  void dispose() { for (final c in fields) { c.dispose(); } super.dispose(); }
  Widget field(int i, String hint, IconData? icon) => Padding(padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(controller: fields[i], enabled: !busy, obscureText: i == 2 ? hidden : i == 3 ? confirmHidden : false,
      readOnly: i == 5, inputFormatters: i == 6 ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)] : null,
      keyboardType: i == 6 ? TextInputType.number : i == 1 ? TextInputType.emailAddress : i == 4 ? TextInputType.phone : TextInputType.text,
      onTap: i != 5 ? null : () async {
        final date = await showDatePicker(context: context, initialDate: DateTime(2005), firstDate: DateTime(1920), lastDate: DateTime.now());
        if (date != null && mounted) fields[5].text = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      },
      decoration: prototypeInput(hint, icon: icon).copyWith(suffixIcon: i == 2 || i == 3 ? IconButton(
        tooltip: 'Toggle password visibility', icon: Icon((i == 2 ? hidden : confirmHidden) ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() { if (i == 2) { hidden = !hidden; } else { confirmHidden = !confirmHidden; } })) : null),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        if (i == 6) return StudentValidation.studentNumberError(v);
        if (i == 1 && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) return 'Enter a valid email address';
        if (i == 4 && !RegExp(r'^\+?[0-9 ()-]{9,16}$').hasMatch(v.trim())) return 'Enter a valid phone number';
        if (i == 2 && v.length < 6) return 'Use at least 6 characters';
        if (i == 3 && v != fields[2].text) return 'Passwords do not match';
        return null;
      }));
  @override
  Widget build(BuildContext context) => PrototypePage(nav: 1, children: [
    const Align(alignment: Alignment.centerLeft, child: BrandLogo(width: 150)), const SizedBox(height: 28),
    Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [IconButton(onPressed: () => closePage(context), icon: const Icon(Icons.arrow_back, size: 30)),
          const Expanded(child: Text('Create your account', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Color(0xFF606060), fontWeight: FontWeight.bold)))]),
        const SizedBox(height: 22), Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFEDF3FF), borderRadius: BorderRadius.circular(18)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.school, color: prototypeBlue), SizedBox(width: 12),
            Text('Student', style: TextStyle(fontSize: 20, color: prototypeBlue, fontWeight: FontWeight.bold))]))),
        const SizedBox(height: 12), const Divider(color: Colors.black), const SizedBox(height: 8),
        ResponsiveGrid(children: [field(0, 'First names', Icons.person_add), field(7, 'Surname', Icons.person_outline), field(1, 'Email Address', Icons.email),
        field(2, 'Password', Icons.lock_person), field(3, 'Confirm Password', null),
        field(4, 'Contact Phone', Icons.phone), field(5, 'YYYY/MM/DD', Icons.calendar_month), field(6, 'Student Number', Icons.school)]),
        CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: agreed,
          activeColor: Colors.grey, onChanged: (v) => setState(() => agreed = v ?? false),
          title: const Text('I agree to the Rules & Regulations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        Center(child: PrototypeButton(busy ? 'Creating account…' : 'Create Account', onPressed: busy ? null : () async {
          if (!form.currentState!.validate()) return;
          if (!agreed) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Rules & Regulations'))); return; }
          setState(() => busy = true);
          try {
            await StudentAuthService.register(firstName: fields[0].text,
              lastName: fields[7].text, email: fields[1].text, password: fields[2].text,
              phone: fields[4].text, studentNumber: fields[6].text, dob: fields[5].text);
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/account-created', (_) => false);
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(StudentAuthService.errorMessage(error))));
            }
          } finally {
            if (mounted) setState(() => busy = false);
          }
        })),
        const SizedBox(height: 10), TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Already have account? Log in', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)))]))) ]);
}
