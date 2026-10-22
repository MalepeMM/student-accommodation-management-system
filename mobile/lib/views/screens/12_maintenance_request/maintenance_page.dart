import 'package:flutter/material.dart';
import '../../../widgets/prototype_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shared_records.dart';
import '../../../services/accommodation_repository.dart';
import '../../../services/student_auth_service.dart';
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});
  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}
class _MaintenancePageState extends State<MaintenancePage> {
  final form = GlobalKey<FormState>();
  final description = TextEditingController();
  String? issue, bedId;
  String priority = 'Medium';
  bool busy = false;
  final repository = AccommodationRepository();
  final requestId = const Uuid().v4();
  late Future<List<AssignedBed>> assignedBeds;
  @override
  void initState() { super.initState(); assignedBeds = repository.getAssignedBeds(); }
  List<AssignedBed> beds = [];
  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    final matches = beds.where((r) => r.id == bedId).toList();
    if (matches.isEmpty) return;
    setState(() => busy = true);
    try {
      await repository.submitMaintenance(id: requestId, bed: matches.first,
        title: issue!, description: description.text.trim(), priority: priority, photo: photo);
      if (mounted) Navigator.pushReplacementNamed(context, '/requests');
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(StudentAuthService.errorMessage(error))));
    } finally { if (mounted) setState(() => busy = false); }
  }
  PlatformFile? photo;
  @override
  void dispose() { description.dispose(); super.dispose(); }
  Future<void> pick() async {
    try {
      final r = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
      if (r != null && mounted) setState(() => photo = r.files.single);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the photo picker.')));
    }
  }
  @override
  Widget build(BuildContext context) => PrototypePage(title: 'Maintenance Request', nav: 2, children: [
    const SizedBox(height: 20), const Text('Report issue and we shall get back to you as soon as possible.',
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 28),
    Align(alignment: Alignment.centerRight, child: TextButton.icon(
      onPressed: busy ? null : () => setState(() { bedId = null; assignedBeds = repository.getAssignedBeds(); }),
      icon: const Icon(Icons.refresh), label: const Text('Refresh'))),
    FutureBuilder<List<AssignedBed>>(future: assignedBeds, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const LinearProgressIndicator();
      if (snapshot.hasError) {
        return OutlinePanel(child: Column(children: [
        Text(StudentAuthService.errorMessage(snapshot.error!)),
        TextButton(onPressed: () => setState(() => assignedBeds = repository.getAssignedBeds()), child: const Text('Retry'))]));
      }
      beds = snapshot.data ?? [];
      if (beds.isEmpty) return const OutlinePanel(child: Text('Your landlord must allocate a bed after approving your application before you can submit maintenance requests.'));
      return DropdownButtonFormField<String>(initialValue: bedId, isExpanded: true,
        decoration: prototypeInput('Your allocated bed', icon: Icons.home_outlined),
        items: beds.map((r) => DropdownMenuItem(value: r.id, child: Text(r.displayName, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: busy ? null : (v) => setState(() => bedId = v));
    }),
    const SizedBox(height: 20),
    Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Issue Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 10),
      DropdownButtonFormField<String>(initialValue: issue, decoration: prototypeInput('Select issue type', icon: Icons.construction),
        hint: const Text('Select issue type'), isExpanded: true,
        items: const ['Wi-Fi connection', 'Outside Shower water', 'Broken Bulb', 'Other']
          .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        validator: (v) => v == null ? 'Select an issue type' : null, onChanged: busy ? null : (v) => setState(() => issue = v)),
      const SizedBox(height: 20), DropdownButtonFormField<String>(initialValue: priority,
        decoration: prototypeInput('Priority', icon: Icons.flag_outlined),
        items: const ['Low', 'Medium', 'High'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: busy ? null : (v) => setState(() => priority = v ?? 'Medium')),
      const SizedBox(height: 24), const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 10),
      TextFormField(controller: description, enabled: !busy, maxLength: 500, minLines: 5, maxLines: 7, decoration: prototypeInput('Describe the issue in detail'),
        validator: (v) => v == null || v.trim().isEmpty ? 'Describe the issue' : null),
      const SizedBox(height: 20), const Text('Add Photo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child: UploadTile(label: photo?.name ?? 'Image of the affected area', onTap: busy ? () {} : pick)),
      const SizedBox(height: 22), PrototypeButton(busy ? 'Submitting…' : 'Submit maintenance',
        onPressed: busy || bedId == null ? null : submit)
    ]))]);
}
