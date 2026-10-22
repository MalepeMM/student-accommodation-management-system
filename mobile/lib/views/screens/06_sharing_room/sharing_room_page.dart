import 'package:flutter/material.dart';
import '../../../widgets/room_detail.dart';
class SharingRoomPage extends StatelessWidget {
 const SharingRoomPage({super.key});
 @override
 Widget build(BuildContext context) => const RoomDetail(sharing: true);
}
