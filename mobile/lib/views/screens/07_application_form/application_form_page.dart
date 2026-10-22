import 'package:flutter/material.dart';
import '../../../widgets/prototype_widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../models/accommodation.dart';
import '../../../services/accommodation_repository.dart';
import '../../../services/student_auth_service.dart';
import '../../../services/student_validation.dart';

class ApplicationFormPage extends StatefulWidget {
  final AccommodationRepository? repository;
  const ApplicationFormPage({super.key, this.repository});
  @override
  State<ApplicationFormPage> createState() => _ApplicationFormPageState();
}

class _ApplicationFormPageState extends State<ApplicationFormPage> {
  final form = GlobalKey<FormState>();
  final fields = List.generate(5, (_) => TextEditingController());
  String? room, institution, nsfas;
  bool agreed = false, busy = false, loadingRooms = true;
  String? roomError;
  String? existingApplicationId;
  late final AccommodationRepository repository;
  final submissionId = const Uuid().v4();
  List<Accommodation> availableRooms = [];
  bool argumentsRead = false;
  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? AccommodationRepository();
    loadApplication();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!argumentsRead) {
      argumentsRead = true;
      final selected = ModalRoute.of(context)?.settings.arguments;
      if (selected is Accommodation) room = selected.id;
    }
  }

  Future<void> loadApplication() async {
    setState(() {
      loadingRooms = true;
      roomError = null;
    });
    try {
      final existing = await repository.getExistingApplicationId();
      if (!mounted) return;
      if (existing != null) {
        setState(() {
          existingApplicationId = existing;
          loadingRooms = false;
        });
        return;
      }
      final profile = await repository.getStudentProfile();
      final result = (await repository.getAccommodations())
          .where((r) => r.available)
          .toList();
      if (!mounted) return;
      setState(() {
        fields[0].text =
            '${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}'.trim();
        fields[1].text = profile['email'] as String? ?? '';
        fields[2].text = profile['studentnumber'] as String? ?? '';
        fields[3].text = profile['phonenumber'] as String? ?? '';
        availableRooms = result;
        loadingRooms = false;
        roomError = null;
        if (room != null && !result.any((r) => r.id == room)) room = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          loadingRooms = false;
          roomError = StudentAuthService.errorMessage(error);
        });
      }
    }
  }

  static const documentTypes = [
    'ID',
    'Proof of registration',
    'Proof of funding',
  ];
  final Map<String, List<PlatformFile>> documentGroups = {
    for (final type in documentTypes) type: <PlatformFile>[],
  };
  List<PlatformFile> get documents => [
    for (final type in documentTypes)
      for (final file in documentGroups[type]!)
        PlatformFile(
          name: '${type.replaceAll(' ', '_')}_${file.name}',
          size: file.size,
          bytes: file.bytes,
        ),
  ];
  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickDocuments(String type) async {
    if (busy) return;
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx'],
          allowMultiple: true,
          withData: true);
      if (result == null || !mounted || busy) return;
      final additions = <PlatformFile>[];
      for (final file in result.files) {
        AccommodationRepository.validateFile(file, 10 * 1024 * 1024);
        AccommodationRepository.documentMime(file.name);
        final duplicate = [...documentGroups[type]!, ...additions].any(
            (existing) => existing.name == file.name && existing.size == file.size);
        if (!duplicate) additions.add(file);
      }
      if (documents.length + additions.length > 5) {
        message('You can attach up to 5 documents in total. Remove a file first.');
        return;
      }
      setState(() => documentGroups[type]!.addAll(additions));
    } catch (error) {
      if (mounted) message(StudentAuthService.errorMessage(error));
    }
  }

  Widget documentSection(String type) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        UploadTile(
            label: 'Add $type document',
            onTap: busy ? () {} : () => pickDocuments(type)),
        ...documentGroups[type]!.asMap().entries.map((entry) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: Text(entry.value.name, maxLines: 2,
                overflow: TextOverflow.ellipsis),
            trailing: IconButton(
                tooltip: 'Remove ${entry.value.name}',
                icon: const Icon(Icons.close),
                onPressed: busy ? null : () => setState(
                    () => documentGroups[type]!.removeAt(entry.key))))),
      ]));

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> submit() async {
    if (busy ||
        loadingRooms ||
        roomError != null ||
        existingApplicationId != null) {
      return;
    }
    final valid = form.currentState!.validate();
    if (!valid) return;
    if (nsfas == null) {
      message('Please select Yes or No for NSFAS.');
      return;
    }
    if (documentTypes.any((type) => documentGroups[type]!.isEmpty)) {
      message('Please attach ID, proof of registration, and proof of funding.');
      return;
    }
    if (!agreed) {
      message('Please confirm that the information is correct.');
      return;
    }
    final matches = availableRooms.where((r) => r.id == room).toList();
    final selected = matches.isEmpty ? null : matches.first;
    if (selected == null) {
      message('Please select an available room.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => busy = true);
    try {
      await repository.submitApplication(
          id: submissionId,
          room: selected,
          details: {
            'name': fields[0].text.trim(),
            'email': fields[1].text.trim(),
            'studentnumber': fields[2].text.trim(),
            'phone': fields[3].text.trim(),
            'nsfas': nsfas,
            'residence': fields[4].text.trim(),
            'institution': institution
          },
          files: documents);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/submitted',
          arguments: submissionId);
    } catch (error) {
      if (mounted) message(StudentAuthService.errorMessage(error));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget input(int i, String hint, IconData icon, {TextInputType? keyboard}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
              controller: fields[i],
              enabled: !busy && !loadingRooms,
              readOnly: i < 4,
              keyboardType: keyboard,
              decoration: prototypeInput(hint, icon: icon),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (i == 2) return StudentValidation.studentNumberError(v);
                if (i == 1 &&
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                if (i == 3 &&
                    !RegExp(r'^\+?[0-9 ()-]{9,16}$').hasMatch(v.trim())) {
                  return 'Enter a valid phone number';
                }
                return null;
              }));
  @override
  Widget build(BuildContext context) =>
      PrototypePage(title: 'Accommodation application', children: [
        if (existingApplicationId != null)
          OutlinePanel(
              child: Column(children: [
            const Text(
                'You have already submitted an application. Only one application per student is allowed.'),
            TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/track'),
                child: const Text('View my application')),
          ]))
        else if (loadingRooms)
          const Center(child: CircularProgressIndicator())
        else if (roomError != null)
          OutlinePanel(
              child: Column(children: [
            Text(roomError!),
            TextButton(onPressed: loadApplication, child: const Text('Retry'))
          ]))
        else
          Form(
              key: form,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                            3,
                            (i) => Expanded(
                                    child: Column(children: [
                                  Row(children: [
                                    Expanded(
                                        child: Container(
                                            height: 1,
                                            color: i == 0
                                                ? Colors.transparent
                                                : Colors.black)),
                                    CircleAvatar(
                                        radius: 28,
                                        backgroundColor: i == 0
                                            ? prototypeBlue
                                            : const Color(0xFFD9D9D9),
                                        child: Text('${i + 1}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold))),
                                    Expanded(
                                        child: Container(
                                            height: 1,
                                            color: i == 2
                                                ? Colors.transparent
                                                : Colors.black))
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(
                                      const [
                                        'Personal\nInformation',
                                        'Accommodation\ndetails',
                                        'Upload\ndocuments'
                                      ][i],
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold))
                                ])))),
                    const SizedBox(height: 36),
                    const Text(
                        'These details come from your registered profile.'),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                            onPressed: busy
                                ? null
                                : () async {
                                    await Navigator.pushNamed(
                                        context, '/personal-details');
                                    if (mounted) await loadApplication();
                                  },
                            child: const Text('Edit personal details'))),
                    ResponsiveGrid(children: [
                      input(0, 'Full Names', Icons.person_add),
                      input(1, 'Email Address', Icons.email,
                          keyboard: TextInputType.emailAddress),
                      input(2, 'Student Number', Icons.school),
                      input(3, 'Contact Phone', Icons.phone,
                          keyboard: TextInputType.phone)
                    ]),
                    Row(children: [
                      const Expanded(
                          child: Text('Are you a NSFAS beneficiary',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold))),
                      ...['Yes', 'No'].map((v) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Semantics(
                              selected: nsfas == v,
                              child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      backgroundColor: nsfas == v
                                          ? prototypeBlue
                                          : Colors.white,
                                      foregroundColor: nsfas == v
                                          ? Colors.white
                                          : prototypeBlue,
                                      minimumSize: const Size(46, 38),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      side: BorderSide(
                                          color: nsfas == v
                                              ? prototypeBlue
                                              : const Color(0xFFDCE3EF)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  onPressed: busy
                                      ? null
                                      : () => setState(() => nsfas = v),
                                  child: Text(v)))))
                    ]),
                    const SizedBox(height: 20),
                    input(4, 'Current residence', Icons.home_outlined),
                    DropdownButtonFormField<String>(
                        initialValue: room,
                        isExpanded: true,
                        decoration: prototypeInput('Select an available room',
                            icon: Icons.bed),
                        hint: const Text('Select an available room'),
                        items: availableRooms
                            .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.displayName,
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged:
                            busy ? null : (v) => setState(() => room = v),
                        validator: (v) =>
                            v == null ? 'Select an available room' : null),
                    if (availableRooms.isEmpty)
                      const Text(
                          'No available rooms. Please check again later.'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                        initialValue: institution,
                        isExpanded: true,
                        decoration: prototypeInput('Select institution',
                            icon: Icons.school),
                        hint: const Text('Select institution'),
                        items: const [
                          'Central University of Technology',
                          'Goldfields TVET College',
                          'Other'
                        ]
                            .map((v) => DropdownMenuItem(
                                value: v,
                                child:
                                    Text(v, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: busy
                            ? null
                            : (v) => setState(() => institution = v),
                        validator: (v) =>
                            v == null ? 'Select an institution' : null),
                    const SizedBox(height: 18),
                    const Text('Upload Documents',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    const Text(
                        'Attach all three document types. PDF or Word, up to 10 MB each. Maximum 5 files in total.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    for (final type in documentTypes) documentSection(type),
                    const SizedBox(height: 18),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: agreed,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => agreed = v ?? false),
                        title: const Text(
                            'I hereby agree the information is correct',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold))),
                    Center(
                        child: PrototypeButton(
                            busy ? 'Submitting…' : 'Submit Application',
                            onPressed: busy ? null : submit)),
                  ]))
      ]);
}
