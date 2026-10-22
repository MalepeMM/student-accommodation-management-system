import 'package:flutter/material.dart';
import '../../../models/shared_records.dart';
import '../../../services/accommodation_repository.dart';
import '../../../widgets/live_list.dart';
import '../../../widgets/private_file.dart';
import '../../../widgets/prototype_widgets.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});
  Widget value(String label, String text) => Padding(padding: const EdgeInsets.only(bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6F7D91))), const SizedBox(height: 5),
      Text(text.isEmpty ? 'Not provided' : text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))]));
  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments;
    final repository = AccommodationRepository();
    return PrototypePage(title: 'Application details', nav: 1, children: [
      if (id is! String) PrototypeButton('Choose an application', onPressed: () => Navigator.pushReplacementNamed(context, '/track'))
      else LiveList<SharedApplication>(load: () async => [await repository.getApplication(id)], builder: (context, rows) {
        final a = rows.single;
        String detail(String key) => a.details[key]?.toString() ?? '';
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Status: ${a.statusLabel}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: prototypeBlue)),
          const SizedBox(height: 12), value('Bed allocation', a.allocatedBed?.label ?? 'Awaiting landlord allocation'),
          const SizedBox(height: 24), ResponsiveGrid(children: [
            OutlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              value('Full name', detail('name')), value('Email address', detail('email')),
              value('Student number', detail('studentnumber')), value('Phone number', detail('phone')),
              value('NSFAS beneficiary', detail('nsfas'))])),
            OutlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              value('Accommodation', a.room?.title ?? 'Listing unavailable'), value('Room type', a.room?.type ?? 'Room unavailable'),
              value('Address', a.room?.address ?? ''), value('Current residence', detail('residence')),
              value('Institution', detail('institution'))])),
          ]),
          const SizedBox(height: 20), const Text('Submitted documents', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
          if (a.documents.isEmpty) const Text('No downloadable documents recorded.'),
          ...a.documents.map((document) => ListTile(leading: const Icon(Icons.description_outlined, color: prototypeBlue),
            title: Text(document.name), trailing: const Icon(Icons.open_in_new),
            onTap: () => openPrivateFile(context, () => repository.documentUrl(a, document)))),
        ]);
      }),
    ]);
  }
}
