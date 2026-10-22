import 'package:flutter/material.dart';
import '../../../models/shared_records.dart';
import '../../../services/accommodation_repository.dart';
import '../../../widgets/live_list.dart';
import '../../../widgets/private_file.dart';
import '../../../widgets/prototype_widgets.dart';

class MyRequestPage extends StatelessWidget {
  const MyRequestPage({super.key});
  @override
  Widget build(BuildContext context) {
    final repository = AccommodationRepository();
    return PrototypePage(title: 'My requests', nav: 2, children: [
      Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 12, children: [
        const Text('We’re here to help.', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700)),
        PrototypeButton('New request', onPressed: () => Navigator.pushNamed(context, '/maintenance'))]),
      const SizedBox(height: 12), const Text('Landlord updates refresh every 20 seconds while this page is open.'),
      LiveList<SharedMaintenance>(load: repository.getRequests, builder: (context, requests) {
        if (requests.isEmpty) return const OutlinePanel(child: Text('No maintenance requests yet.'));
        return Column(children: requests.map((request) => Padding(padding: const EdgeInsets.only(bottom: 16),
          child: OutlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(request.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8), Text('Status: ${request.status} · Priority: ${request.priority}',
              style: const TextStyle(color: prototypeBlue, fontWeight: FontWeight.w600)),
            if (request.bedLabel != null) Text('Bed: ${request.bedLabel}'),
            const SizedBox(height: 12), Text(request.description),
            const SizedBox(height: 12), Text('Reported: ${request.submittedAt.day}/${request.submittedAt.month}/${request.submittedAt.year}'),
            if (request.photo != null) TextButton.icon(onPressed: () => openPrivateFile(context, () => repository.maintenancePhotoUrl(request)),
              icon: const Icon(Icons.photo_outlined), label: const Text('View photo')),
          ])))).toList());
      }),
    ]);
  }
}
