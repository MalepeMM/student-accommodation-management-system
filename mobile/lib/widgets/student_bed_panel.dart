import 'package:flutter/material.dart';
import '../models/shared_records.dart';
import '../services/accommodation_repository.dart';
import 'live_list.dart';
import 'prototype_widgets.dart';

class StudentBedPanel extends StatelessWidget {
  const StudentBedPanel({super.key});
  @override
  Widget build(BuildContext context) => OutlinePanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Text('My accommodation', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
    LiveList<AssignedBed>(load: AccommodationRepository().getAssignedBeds, builder: (context, beds) {
      if (beds.isEmpty) return const Text('Your landlord will allocate a bed after approving your application.');
      final bed = beds.single;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(bed.displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8), Text(bed.room.address), const SizedBox(height: 16),
        Align(alignment: Alignment.centerLeft, child: PrototypeButton('Report maintenance',
          onPressed: () => Navigator.pushNamed(context, '/maintenance'))),
      ]);
    }),
  ]));
}
