import 'package:flutter/material.dart';
import '../../../models/shared_records.dart';
import '../../../services/accommodation_repository.dart';
import '../../../widgets/prototype_widgets.dart';
import '../../../widgets/live_list.dart';

class TrackPage extends StatelessWidget {
  const TrackPage({super.key});
  @override
  Widget build(BuildContext context) {
    final repository = AccommodationRepository();
    return PrototypePage(title: 'My applications', nav: 1, children: [
      const Text('Every step, in one place.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8), const Text('Landlord decisions refresh every 20 seconds while this page is open.'),
      LiveList<SharedApplication>(load: repository.getApplications, builder: (context, applications) {
        if (applications.isEmpty) {
          return OutlinePanel(child: Column(children: [
          const Icon(Icons.article_outlined, color: prototypeBlue, size: 42), const SizedBox(height: 12),
          const Text('No applications submitted yet.'), const SizedBox(height: 16),
          PrototypeButton('Browse rooms', onPressed: () => Navigator.pushNamed(context, '/explore'))]));
        }
        return Column(children: applications.map((a) => Padding(padding: const EdgeInsets.only(bottom: 16),
          child: OutlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(a.room?.title ?? 'Accommodation listing unavailable', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8), Text(a.room?.type ?? 'Room unavailable'),
            const SizedBox(height: 8), Text('Status: ${a.statusLabel}', style: const TextStyle(fontWeight: FontWeight.w700, color: prototypeBlue)),
            const SizedBox(height: 8), Text('Submitted: ${a.submittedAt.day}/${a.submittedAt.month}/${a.submittedAt.year}'),
            if (a.status.toLowerCase() == 'approved') ...[const SizedBox(height: 12),
              Text(a.allocatedBed == null
                ? 'Approved — awaiting bed allocation by your landlord.'
                : 'Allocated bed: ${a.allocatedBed!.label}. You can now submit maintenance requests.')],
            if (a.allocatedBed != null) Align(alignment: Alignment.centerLeft, child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/maintenance'), icon: const Icon(Icons.build_outlined), label: const Text('Report maintenance'))),
            const SizedBox(height: 16), Align(alignment: Alignment.centerLeft, child: PrototypeButton('View details', outline: true,
              onPressed: () => Navigator.pushNamed(context, '/details', arguments: a.id))),
          ])))).toList());
      }),
    ]);
  }
}
