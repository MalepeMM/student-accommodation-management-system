import 'package:flutter/material.dart';
import '../../../models/accommodation.dart';
import '../../../services/accommodation_repository.dart';
import '../../../services/student_auth_service.dart';
import '../../../widgets/prototype_widgets.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}
class _ExplorePageState extends State<ExplorePage> {
  final repository = AccommodationRepository();
  late Future<List<Accommodation>> rooms;
  String query = '', filter = 'All rooms';
  @override
  void initState() { super.initState(); rooms = repository.getAccommodations(); }
  void refresh() => setState(() => rooms = repository.getAccommodations());
  void open(Accommodation room) => Navigator.pushNamed(context, '/single-room', arguments: room);
  Widget roomCard(Accommodation room) => Material(color: Colors.white,
    borderRadius: BorderRadius.circular(20), clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: () => open(room), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AspectRatio(aspectRatio: 1.8, child: room.imageUrl.isEmpty
        ? const ColoredBox(color: Color(0xFFEDF3FF), child: Icon(Icons.bed_outlined, size: 64, color: prototypeBlue))
        : Image.network(room.imageUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 48)))),
      Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(room.type, style: const TextStyle(color: prototypeBlue, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(room.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(room.address, style: const TextStyle(color: Color(0xFF6F7D91))),
        const SizedBox(height: 18), Text('R ${room.monthlyPrice.toStringAsFixed(2)} / month',
          style: const TextStyle(fontSize: 23, color: prototypeBlue, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8), Text(room.availabilityLabel),
        const SizedBox(height: 16), PrototypeButton('View room', onPressed: () => open(room)),
      ])),
    ])));
  @override
  Widget build(BuildContext context) => PrototypePage(title: 'Explore accommodation', back: false, nav: 0, children: [
    const Text('Find your place. Start your journey.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10), const Text('Browse rooms published by your accommodation landlords.'),
    const SizedBox(height: 24), ResponsiveGrid(breakpoint: 580, children: [
      TextField(onChanged: (v) => setState(() => query = v.toLowerCase().trim()),
        decoration: prototypeInput('Search accommodation or location', icon: Icons.search)),
      DropdownButtonFormField<String>(initialValue: filter, decoration: prototypeInput('Room type', icon: Icons.tune),
        items: const ['All rooms', 'Single', 'Sharing'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => filter = v ?? 'All rooms')),
    ]),
    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: refresh,
      icon: const Icon(Icons.refresh), label: const Text('Refresh rooms'))),
    FutureBuilder<List<Accommodation>>(future: rooms, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) {
        return OutlinePanel(child: Column(children: [
        Text(StudentAuthService.errorMessage(snapshot.error!)), TextButton(onPressed: refresh, child: const Text('Retry'))]));
      }
      final visible = (snapshot.data ?? []).where((r) {
        final sharing = r.type.toLowerCase().contains('shar');
        return (filter == 'All rooms' || (filter == 'Sharing' ? sharing : r.type.toLowerCase().contains('single')))
          && '${r.title} ${r.address} ${r.type}'.toLowerCase().contains(query);
      }).toList();
      if (visible.isEmpty) return const OutlinePanel(child: Text('No rooms match your search. Try refreshing or changing the filters.'));
      return ResponsiveGrid(breakpoint: 560, gap: 24, children: visible.map(roomCard).toList());
    }),
  ]);
}
