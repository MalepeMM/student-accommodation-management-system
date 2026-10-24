import 'dart:convert';
import 'accommodation.dart';

class ApplicationDocument {
  final String name, path;
  const ApplicationDocument({required this.name, required this.path});
  Map<String, String> toJson() => {'name': name, 'path': path};
}
class SharedApplication {
  final String id, studentId, landlordId, status;
  final Accommodation? room;
  final AssignedBed? allocatedBed;
  final DateTime submittedAt;
  final Map<String, dynamic> details;
  final List<ApplicationDocument> documents;
  SharedApplication({required this.id, required this.studentId, required this.landlordId,
    required this.status, required this.submittedAt, required this.details,
    required this.documents, this.room, this.allocatedBed});
  factory SharedApplication.fromJson(Map<String, dynamic> row) {
    final documents = <ApplicationDocument>[];
    try {
      final raw = jsonDecode(row['documents'] as String? ?? '[]');
      if (raw is List) {
        for (final entry in raw) {
          if (entry is Map && entry['name'] is String && entry['path'] is String) {
            documents.add(ApplicationDocument(name: entry['name'] as String, path: entry['path'] as String));
          }
        }
      }
    } catch (_) { /* Legacy document text is not a storage manifest. */ }
    final allocations = row['allocation'] as List<dynamic>? ?? [];
    final bed = allocations.whereType<Map<String, dynamic>>().toList();
    return SharedApplication(allocatedBed: bed.isEmpty ? null : AssignedBed.fromJson(bed.first), id: row['applicationid'] as String,
      studentId: row['studentid'] as String, landlordId: row['landlordid'] as String,
      status: row['applicationstatus'] as String? ?? 'pending',
      submittedAt: DateTime.parse(row['appliedat'] as String).toLocal(),
      details: row['formdetails'] as Map<String, dynamic>? ?? {}, documents: documents,
      room: row['room'] is Map<String, dynamic>
        ? Accommodation.fromJson(row['room'] as Map<String, dynamic>) : null);
  }
  String get statusLabel => status.isEmpty ? 'Pending' : '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}';
}
class SharedMaintenance {
  final String id, title, description, priority, status;
  final String? photo, bedLabel;
  final DateTime submittedAt;
  SharedMaintenance.fromJson(Map<String, dynamic> row)
    : id = row['requestid'] as String, title = row['title'] as String,
      description = row['description'] as String, priority = row['priority'] as String,
      status = row['status'] as String? ?? 'Pending', photo = row['photo'] as String?,
      bedLabel = row['bedlabel'] as String?,
      submittedAt = DateTime.parse(row['submittedat'] as String).toLocal();
}
class IntegrationException implements Exception {
  final String message;
  const IntegrationException(this.message);
  @override
  String toString() => message;
}

class AssignedBed {
  final String id, label, applicationId;
  final Accommodation room;
  final DateTime allocatedAt;
  AssignedBed({required this.id, required this.label, required this.applicationId,
    required this.room, required this.allocatedAt});
  factory AssignedBed.fromJson(Map<String, dynamic> row) => AssignedBed(
    id: row['bedid'] as String, label: row['bedlabel'] as String,
    applicationId: row['applicationid'] as String,
    allocatedAt: DateTime.parse(row['allocatedat'] as String).toLocal(),
    room: Accommodation.fromJson(row['room'] as Map<String, dynamic>));
  String get displayName => '${room.title} · ${room.type} · $label';
}
