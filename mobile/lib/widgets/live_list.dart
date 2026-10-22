import 'dart:async';
import 'package:flutter/material.dart';
import '../services/student_auth_service.dart';
import 'prototype_widgets.dart';

/// Polling needs no Realtime publication changes. Opening a page also fetches fresh data.
class LiveList<T> extends StatefulWidget {
  final Future<List<T>> Function() load;
  final Widget Function(BuildContext, List<T>) builder;
  const LiveList({super.key, required this.load, required this.builder});
  @override
  State<LiveList<T>> createState() => _LiveListState<T>();
}
class _LiveListState<T> extends State<LiveList<T>> {
  List<T>? data;
  String? error;
  bool busy = false;
  Timer? timer;
  @override
  void initState() {
    super.initState(); refresh();
    timer = Timer.periodic(const Duration(seconds: 20), (_) => refresh());
  }
  Future<void> refresh() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final rows = await widget.load();
      if (mounted) setState(() { data = rows; error = null; });
    } catch (e) {
      if (mounted) setState(() => error = StudentAuthService.errorMessage(e));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: busy ? null : refresh,
      icon: const Icon(Icons.refresh), label: Text(busy ? 'Refreshing…' : 'Refresh'))),
    if (error != null) OutlinePanel(child: Text(error!)),
    if (data == null && busy) const Center(child: CircularProgressIndicator()),
    if (data != null) widget.builder(context, data!),
  ]);
}
