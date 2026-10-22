import 'package:flutter/material.dart';
import '../models/accommodation.dart';
import 'prototype_widgets.dart';

class RoomDetail extends StatelessWidget {
  final bool sharing;
  const RoomDetail({super.key, this.sharing = false});
  @override
  Widget build(BuildContext context) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is! Accommodation) {
      return PrototypePage(title: 'Choose a room', children: [
      const Text('Select a room to view its details.'),
      PrototypeButton('Browse rooms', onPressed: () => Navigator.pushReplacementNamed(context, '/explore'))]);
    }
    final room = argument;
    return PrototypePage(title: room.type, children: [
      if (room.imageUrl.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(22),
        child: AspectRatio(aspectRatio: 1.8, child: Image.network(room.imageUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 64))))),
      const SizedBox(height: 24), Text(room.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8), Text('${room.type} · ${room.address}'),
      const SizedBox(height: 16), Text('R ${room.monthlyPrice.toStringAsFixed(2)} / month',
        style: const TextStyle(fontSize: 23, color: prototypeBlue, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12), Text(room.availabilityLabel),
      const SizedBox(height: 24), OutlinePanel(child: Text(room.description.isEmpty ? 'Contact your landlord for more details.' : room.description)),
      if (room.amenities.isNotEmpty) ...[const SizedBox(height: 20),
        const Text('Amenities', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Text(room.amenities)],
      const SizedBox(height: 28), ResponsiveActions(children: [
        PrototypeButton('Back to rooms', outline: true, onPressed: () => Navigator.pop(context)),
        PrototypeButton('Apply for this room', onPressed: room.available
          ? () => Navigator.pushNamed(context, '/apply', arguments: room) : null)]),
    ]);
  }
}
