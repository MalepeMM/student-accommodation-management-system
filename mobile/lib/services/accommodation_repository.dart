import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/accommodation.dart';
import '../models/shared_records.dart';
import 'student_auth_service.dart';
import 'student_validation.dart';

class AccommodationRepository {
  final SupabaseClient? _client;
  AccommodationRepository({SupabaseClient? client}) : _client = client;
  SupabaseClient get client => _client ?? StudentAuthService.client;
  String get studentId {
    final id = client.auth.currentUser?.id;
    if (id == null) throw const IntegrationException('Please sign in with a student account.');
    return id;
  }
  static const roomSelect = '*,listing:accommodation_listings!rooms_listingid_fkey(*)';
  static const bedSelect = '*,room:rooms!beds_roomid_fkey($roomSelect)';
  static const applicationSelect = '*,room:rooms!applications_selectedroomid_fkey($roomSelect),allocation:beds!beds_applicationid_fkey($bedSelect)';

  Future<List<Accommodation>> getAccommodations() async {
    // Browsing includes rooms awaiting bed setup and rooms that are currently full.
    final counts = await client.from('room_bed_availability').select('roomid,totalbeds,availablebeds');
    final byRoom = {for (final row in counts) row['roomid'] as String: row};
    final rows = await client.from('rooms').select(roomSelect)
      .eq('availabilitystatus', 'Available').order('monthlyrent');
    return rows.map((row) => Accommodation.fromJson({...row, ...?(byRoom[row['roomid']])}))
      .where((r) => r.landlordId.isNotEmpty && r.listingId.isNotEmpty).toList();
  }
  Future<Accommodation> getRoomWithAvailability(String id) async {
    final row = await client.from('rooms').select(roomSelect).eq('roomid', id).single();
    final counts = await client.from('room_bed_availability').select('totalbeds,availablebeds').eq('roomid', id).single();
    return Accommodation.fromJson({...row, ...counts});
  }
  Future<Map<String, dynamic>> getStudentProfile() async {
    final owner = studentId;
    final row = await client.from('students').select('firstname,lastname,email,phonenumber,studentnumber')
      .eq('studentid', owner).single();
    if (studentId != owner) throw const IntegrationException('Your account changed. Please try again.');
    return row;
  }
  Future<String?> getExistingApplicationId() async {
    final row = await client.from('applications').select('applicationid')
      .eq('studentid', studentId).limit(1).maybeSingle();
    return row?['applicationid'] as String?;
  }
  Future<List<AssignedBed>> getAssignedBeds() async {
    final rows = await client.from('beds').select(bedSelect).eq('studentid', studentId).order('bedlabel');
    return rows.map(AssignedBed.fromJson).toList();
  }
  Future<List<SharedApplication>> getApplications() async {
    final rows = await client.from('applications').select(applicationSelect)
      .eq('studentid', studentId).order('appliedat', ascending: false);
    return rows.map(SharedApplication.fromJson).toList();
  }
  Future<SharedApplication> getApplication(String id) async {
    final row = await client.from('applications').select(applicationSelect)
      .eq('applicationid', id).eq('studentid', studentId).single();
    return SharedApplication.fromJson(row);
  }
  Future<bool> _exists(String table, String key, String id, {String? owner}) async =>
    await client.from(table).select(key).eq(key, id).eq('studentid', owner ?? studentId).maybeSingle() != null;

  static String documentMime(String filename) {
    switch (filename.split('.').last.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: throw const IntegrationException('Choose PDF or Word documents.');
    }
  }
  static String imageMime(String filename) {
    switch (filename.split('.').last.toLowerCase()) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'webp': return 'image/webp';
      default: throw const IntegrationException('Choose a JPG, PNG, or WebP photo.');
    }
  }
  static void validateFile(PlatformFile file, int maxBytes) {
    if (file.bytes == null || file.bytes!.isEmpty) throw const IntegrationException('The selected file could not be read. Please select it again.');
    if (file.bytes!.length > maxBytes) throw IntegrationException('${file.name} is too large. Maximum ${maxBytes ~/ (1024 * 1024)} MB.');
  }
  Future<String> _upload(String bucket, String recordId, PlatformFile file, String mime, {required String owner}) async {
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$owner/$recordId/${const Uuid().v4()}_$safeName';
    await client.storage.from(bucket).uploadBinary(path, file.bytes!,
      fileOptions: FileOptions(contentType: mime, upsert: false));
    return path;
  }
  Future<void> _cleanup(String bucket, List<String> paths) async {
    if (paths.isEmpty) return;
    try { await client.storage.from(bucket).remove(paths); }
    catch (_) { /* Private orphan cleanup can be retried; never hide the original error. */ }
  }
  Future<String> submitApplication({required String id, required Accommodation room,
    required Map<String, dynamic> details, required List<PlatformFile> files}) async {
    final owner = studentId;
    if (await _exists('applications', 'applicationid', id, owner: owner)) return id;
    if (await getExistingApplicationId() != null) {
      throw const IntegrationException('You have already submitted an application. Only one application per student is allowed. Check My applications.');
    }
    final profile = await getStudentProfile();
    final numberError = StudentValidation.studentNumberError(profile['studentnumber'] as String?);
    if (numberError != null) throw const IntegrationException('Update your profile with a valid 9-digit student number before applying.');
    final personalDetails = {...details,
      'name': '${profile['firstname'] ?? ''} ${profile['lastname'] ?? ''}'.trim(),
      'email': profile['email'], 'phone': profile['phonenumber'] ?? '',
      'studentnumber': profile['studentnumber']};
    if (files.isEmpty || files.length > 5) throw const IntegrationException('Select between 1 and 5 documents.');
    for (final file in files) { validateFile(file, 10 * 1024 * 1024); documentMime(file.name); }
    // Re-read availability immediately before uploading. RLS also enforces ownership/availability.
    final fresh = await getRoomWithAvailability(room.id);
    if (!fresh.available || fresh.landlordId != room.landlordId) throw const IntegrationException('This room is no longer available. Please choose another room.');
    final paths = <String>[];
    final manifest = <Map<String, String>>[];
    try {
      for (final file in files) {
        final path = await _upload('application-documents', id, file, documentMime(file.name), owner: owner);
        paths.add(path); manifest.add({'name': file.name, 'path': path});
      }
    } catch (_) { await _cleanup('application-documents', paths); rethrow; }
    try {
      // Do not PATCH a room here: application approval is distinct from occupancy.
      await client.from('applications').insert({'applicationid': id,
        'studentid': owner, 'landlordid': fresh.landlordId,
        'selectedroomid': fresh.id, 'applicationstatus': 'pending',
        'documents': jsonEncode(manifest), 'formdetails': personalDetails});
    } catch (error) {
      // A lost response may follow a committed insert. Check before reporting failure or deleting files.
      try { if (await _exists('applications', 'applicationid', id, owner: owner)) return id; }
      catch (_) { throw IntegrationException('Submission could not be confirmed. Check My applications before trying again. Reference: $id'); }
      if (error is PostgrestException) {
        await _cleanup('application-documents', paths);
        rethrow;
      }
      throw IntegrationException('Submission could not be confirmed. Check My applications and retry using this form. Reference: $id');
    }
    return id;
  }
  Future<List<SharedMaintenance>> getRequests() async {
    final rows = await client.from('maintenancerequests').select()
      .eq('studentid', studentId).order('submittedat', ascending: false);
    return rows.map(SharedMaintenance.fromJson).toList();
  }
  Future<String> submitMaintenance({required String id, required AssignedBed bed,
    required String title, required String description, required String priority, PlatformFile? photo}) async {
    final owner = studentId;
    if (await _exists('maintenancerequests', 'requestid', id, owner: owner)) return id;
    final row = await client.from('beds').select(bedSelect)
      .eq('bedid', bed.id).eq('studentid', owner).maybeSingle();
    if (row == null) throw const IntegrationException('Your landlord must allocate your bed before you can report maintenance.');
    final assigned = AssignedBed.fromJson(row);
    String? path;
    if (photo != null) {
      validateFile(photo, 5 * 1024 * 1024);
      path = await _upload('maintenance-photos', id, photo, imageMime(photo.name), owner: owner);
    }
    try {
      await client.from('maintenancerequests').insert({'requestid': id,
        'studentid': owner, 'landlordid': assigned.room.landlordId, 'roomid': assigned.room.id, 'bedid': assigned.id,
        'title': title, 'description': description, 'priority': priority,
        'status': 'Pending', 'photo': path});
    } catch (error) {
      try { if (await _exists('maintenancerequests', 'requestid', id, owner: owner)) return id; }
      catch (_) { throw IntegrationException('Request could not be confirmed. Check My requests. Reference: $id'); }
      if (error is PostgrestException && path != null) await _cleanup('maintenance-photos', [path]);
      rethrow;
    }
    return id;
  }
  Future<String> documentUrl(SharedApplication application, ApplicationDocument document) async {
    if (!document.path.startsWith('${application.studentId}/${application.id}/')) throw const IntegrationException('Invalid document reference.');
    return client.storage.from('application-documents').createSignedUrl(document.path, 60);
  }
  Future<String> maintenancePhotoUrl(SharedMaintenance request) async {
    final path = request.photo;
    if (path == null || !path.startsWith('$studentId/${request.id}/')) throw const IntegrationException('No photo available.');
    return client.storage.from('maintenance-photos').createSignedUrl(path, 60);
  }
}
