import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:helloworld/models/accommodation.dart';
import 'package:helloworld/models/shared_records.dart';
import 'package:helloworld/services/accommodation_repository.dart';
import 'package:helloworld/services/student_validation.dart';

const student = '11111111-1111-4111-8111-111111111111';
const landlord = '22222222-2222-4222-8222-222222222222';
const roomId = '33333333-3333-4333-8333-333333333333';
const applicationId = '44444444-4444-4444-8444-444444444444';
const bedId = '66666666-6666-4666-8666-666666666666';
const listingId = '55555555-5555-4555-8555-555555555555';
Map<String, dynamic> roomRow() => {
  'roomid': roomId, 'landlordid': landlord, 'listingid': listingId,
  'roomtype': 'Sharing', 'monthlyrent': 3850.50, 'availabilitystatus': 'Available',
  'studentid': null, 'applicationid': null, 'image': '',
  'listing': {'title': 'Test residence', 'address': 'Test address', 'description': 'Test description', 'amenities': 'Wi-Fi'},
};

class Backend {
  final requests = <http.Request>[];
  final applications = <String, Map<String, dynamic>>{};
  final assignments = <String, Map<String, dynamic>>{};
  final maintenance = <String, Map<String, dynamic>>{};
  bool loseInsertResponse = false, rejectSecondUpload = false;
  int uploads = 0, removals = 0;
  int totalBeds = 2, availableBeds = 2;
  bool omitCounts = false, failCounts = false;
  late final SupabaseClient client;
  Backend() {
    client = SupabaseClient('https://example.supabase.co', 'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(handle));
  }
  http.Response json(Object? body, [int status = 200]) => http.Response(jsonEncode(body), status,
    headers: {'content-type': 'application/json'});
  Future<void> login() => client.auth.signInWithPassword(email: 'student@example.test', password: 'test-password').then((_) {});
  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    if (path == '/auth/v1/token') {
      String part(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final token = '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': student, 'exp': 2208988800, 'role': 'authenticated'})}.test';
      return json({'access_token': token, 'refresh_token': 'test-refresh', 'token_type': 'bearer', 'expires_in': 3600,
        'user': {'id': student, 'aud': 'authenticated', 'email': 'student@example.test',
          'created_at': '2026-01-01T00:00:00Z', 'app_metadata': {}, 'user_metadata': {'role': 'student'}}});
    }
    if (path == '/rest/v1/students') {
      return json({
      'firstname': 'Test', 'lastname': 'Student', 'email': 'student@example.test',
      'phonenumber': '0712345678', 'studentnumber': '012345678'});
    }
    if (path == '/rest/v1/room_bed_availability') {
      if (failCounts) return json({'message': 'Availability unavailable', 'code': '42501'}, 403);
      final counts = {'roomid': roomId, 'totalbeds': totalBeds, 'availablebeds': availableBeds};
      if (omitCounts) return json([]);
      return json(request.url.queryParameters['roomid'] != null ? counts : [counts]);
    }
    if (path == '/rest/v1/rooms') return json(request.url.queryParameters['roomid'] != null ? roomRow() : [roomRow()]);
    if (path == '/rest/v1/beds') {
      final filter = request.url.queryParameters['bedid'];
      return json(assignments.values.where((b) => filter == null || filter == "eq.${b['bedid']}").toList());
    }
    if (path == '/rest/v1/maintenancerequests') {
      if (request.method == 'POST') {
        final row = jsonDecode(request.body) as Map<String, dynamic>;
        maintenance[row['requestid'] as String] = {...row, 'submittedat': '2026-10-21T12:00:00Z'};
        return json(null, 201);
      }
      final filter = request.url.queryParameters['requestid'];
      return json(maintenance.values.where((r) => filter == null || filter == "eq.${r['requestid']}").toList());
    }
    if (path == '/rest/v1/applications') {
      if (request.method == 'POST') {
        final row = jsonDecode(request.body) as Map<String, dynamic>;
        applications[row['applicationid'] as String] = {...row, 'appliedat': '2026-10-20T12:00:00Z', 'room': roomRow()};
        if (loseInsertResponse) { loseInsertResponse = false; throw TimeoutException('Response lost after commit'); }
        return json(null, 201);
      }
      final idFilter = request.url.queryParameters['applicationid'];
      if (idFilter != null) {
        final row = applications[idFilter.replaceFirst('eq.', '')];
        // maybeSingle requests a normal array; the client converts an empty list to null.
        return json(row == null ? [] : [row]);
      }
      return json(applications.values.toList());
    }
    if (path.startsWith('/storage/v1/object/application-documents/')) {
      uploads++;
      if (rejectSecondUpload && uploads == 2) return json({'message': 'Upload denied', 'statusCode': '403', 'error': 'Unauthorized'}, 403);
      return json({'Key': path.split('/storage/v1/object/').last, 'Id': applicationId});
    }
    if (path == '/storage/v1/object/application-documents' && request.method == 'DELETE') {
      removals++;
      return json([]);
    }
    throw StateError('Unexpected request: ${request.method} $path');
  }
}
PlatformFile document(String name) => PlatformFile(name: name, size: 8, bytes: Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55]));

void main() {
  test('Published rooms preserve live prices without requiring a free bed', () async {
    final backend = Backend(); addTearDown(backend.client.dispose);
    final rooms = await AccommodationRepository(client: backend.client).getAccommodations();
    expect(rooms.single.monthlyPrice, 3850.50);
    expect(rooms.single.title, 'Test residence');
    final query = backend.requests.singleWhere((r) => r.url.path == '/rest/v1/rooms').url.queryParameters;
    expect(query['availabilitystatus'], 'eq.Available');
    expect(query.containsKey('roomid'), isFalse);
    final countsQuery = backend.requests.singleWhere((r) => r.url.path == '/rest/v1/room_bed_availability').url.queryParameters;
    expect(countsQuery.containsKey('availablebeds'), isFalse);
    expect(rooms.single.availableBeds, 2);
  });
  test('Rooms awaiting bed setup stay visible but cannot receive applications', () async {
    final backend = Backend()..totalBeds = 0..availableBeds = 0;
    addTearDown(backend.client.dispose);
    await backend.login();
    final repository = AccommodationRepository(client: backend.client);
    final room = (await repository.getAccommodations()).single;
    expect(room.title, 'Test residence');
    expect(room.available, isFalse);
    expect(room.availabilityLabel, 'Awaiting landlord bed setup');
    await expectLater(repository.submitApplication(id: applicationId, room: room,
      details: {}, files: [document('proof.pdf')]), throwsA(isA<IntegrationException>()));
    expect(backend.uploads, 0);
    expect(backend.applications, isEmpty);
  });
  test('Full rooms stay visible and become available when a bed is released', () async {
    final backend = Backend()..availableBeds = 0;
    addTearDown(backend.client.dispose);
    final repository = AccommodationRepository(client: backend.client);
    final full = (await repository.getAccommodations()).single;
    expect(full.available, isFalse);
    expect(full.availabilityLabel, 'Fully occupied');
    backend.availableBeds = 1;
    final refreshed = (await repository.getAccommodations()).single;
    expect(refreshed.available, isTrue);
    expect(refreshed.availabilityLabel, '1 of 2 beds available');
  });
  test('Missing count rows keep the listing visible without allowing applications', () async {
    final backend = Backend()..omitCounts = true;
    addTearDown(backend.client.dispose);
    final room = (await AccommodationRepository(client: backend.client).getAccommodations()).single;
    expect(room.available, isFalse);
    expect(room.totalBeds, 0);
  });
  test('Availability query errors are reported instead of appearing as an empty catalogue', () async {
    final backend = Backend()..failCounts = true;
    addTearDown(backend.client.dispose);
    await expectLater(AccommodationRepository(client: backend.client).getAccommodations(),
      throwsA(isA<PostgrestException>()));
  });
  test('A committed application with a lost response is recovered without occupying a room', () async {
    final backend = Backend()..loseInsertResponse = true; addTearDown(backend.client.dispose);
    await backend.login();
    final repository = AccommodationRepository(client: backend.client);
    final id = await repository.submitApplication(id: applicationId, room: Accommodation.fromJson(roomRow()),
      details: {'name': 'Test Student', 'institution': 'CUT'}, files: [document('proof.pdf')]);
    expect(id, applicationId); expect(backend.applications.length, 1);
    final row = backend.applications[applicationId]!;
    expect(row['studentid'], student); expect(row['landlordid'], landlord); expect(row['selectedroomid'], roomId);
    expect(row['applicationstatus'], 'pending');
    expect(jsonDecode(row['documents'] as String), hasLength(1));
    expect(backend.requests.where((r) => r.url.path == '/rest/v1/rooms' && r.method != 'GET'), isEmpty);
    final uploadsBefore = backend.uploads;
    await repository.submitApplication(id: applicationId, room: Accommodation.fromJson(roomRow()), details: {}, files: [document('proof.pdf')]);
    expect(backend.uploads, uploadsBefore); // Retry recognises the existing record.
  });
  test('An application to any other room or landlord blocks another submission', () async {
    final backend = Backend(); addTearDown(backend.client.dispose); await backend.login();
    backend.applications[applicationId] = {'applicationid': applicationId,
      'studentid': student, 'landlordid': landlord, 'applicationstatus': 'rejected'};
    final repository = AccommodationRepository(client: backend.client);
    expect(await repository.getExistingApplicationId(), applicationId);
    await expectLater(repository.submitApplication(id: '77777777-7777-4777-8777-777777777777',
      room: Accommodation.fromJson(roomRow()), details: {}, files: [document('proof.pdf')]),
      throwsA(isA<IntegrationException>()));
    expect(backend.uploads, 0);
    expect(backend.applications.length, 1);
  });
  test('Submitted personal information comes from the registered student profile', () async {
    final backend = Backend(); addTearDown(backend.client.dispose); await backend.login();
    await AccommodationRepository(client: backend.client).submitApplication(id: applicationId,
      room: Accommodation.fromJson(roomRow()), details: {'name': 'Wrong person',
        'studentnumber': '999999999', 'institution': 'CUT'}, files: [document('proof.pdf')]);
    final details = backend.applications[applicationId]!['formdetails'] as Map;
    expect(details['name'], 'Test Student');
    expect(details['email'], 'student@example.test');
    expect(details['phone'], '0712345678');
    expect(details['studentnumber'], '012345678');
    expect(details['institution'], 'CUT');
    final reads = backend.requests.where((r) => r.url.path == '/rest/v1/students');
    expect(reads.every((r) => r.url.queryParameters['studentid'] == 'eq.$student'), isTrue);
  });
  test('Student numbers require exactly nine ASCII digits and preserve leading zeroes', () {
    for (final value in ['12345678', '1234567890', 'abcdefghi', '12345 789', '１２３４５６７８９', '123456789\n', '']) {
      expect(StudentValidation.studentNumberError(value), isNotNull);
    }
    expect(StudentValidation.studentNumberError('012345678'), isNull);
    expect(StudentValidation.studentNumberError('123456789'), isNull);
  });
  test('An upload failure stops application insertion and cleans up completed uploads', () async {
    final backend = Backend()..rejectSecondUpload = true; addTearDown(backend.client.dispose);
    await backend.login();
    final repository = AccommodationRepository(client: backend.client);
    await expectLater(repository.submitApplication(id: applicationId, room: Accommodation.fromJson(roomRow()),
      details: {}, files: [document('one.pdf'), document('two.pdf')]), throwsA(isA<StorageException>()));
    expect(backend.applications, isEmpty); expect(backend.removals, 1);
  });
  test('Tracking reads the latest decision and remains scoped to the signed-in student', () async {
    final backend = Backend(); addTearDown(backend.client.dispose); await backend.login();
    backend.applications[applicationId] = {'applicationid': applicationId, 'studentid': student,
      'landlordid': landlord, 'applicationstatus': 'pending', 'appliedat': '2026-10-20T12:00:00Z', 'documents': '[]', 'formdetails': {}, 'room': roomRow()};
    final repository = AccommodationRepository(client: backend.client);
    expect((await repository.getApplications()).single.statusLabel, 'Pending');
    backend.applications[applicationId]!['applicationstatus'] = 'approved';
    expect((await repository.getApplications()).single.statusLabel, 'Approved');
    final reads = backend.requests.where((r) => r.url.path == '/rest/v1/applications');
    expect(reads.every((r) => r.url.queryParameters['studentid'] == 'eq.$student'), isTrue);
  });
  test('Maintenance uses an active bed and stops after the allocation is released', () async {
    final backend = Backend(); addTearDown(backend.client.dispose); await backend.login();
    final row = {'bedid': bedId, 'bedlabel': 'Bed 2', 'studentid': student,
      'applicationid': applicationId, 'allocatedat': '2026-10-21T12:00:00Z', 'roomid': roomId, 'room': roomRow()};
    backend.assignments[bedId] = row;
    final repository = AccommodationRepository(client: backend.client);
    final beds = await repository.getAssignedBeds();
    expect(beds.single.label, 'Bed 2');
    await repository.submitMaintenance(id: '77777777-7777-4777-8777-777777777777', bed: beds.single,
      title: 'Broken Bulb', description: 'The room light does not turn on.', priority: 'Medium');
    final request = backend.maintenance.values.single;
    expect(request['bedid'], bedId); expect(request['studentid'], student);
    expect(request['roomid'], roomId); expect(request['landlordid'], landlord);
    backend.assignments.clear();
    await expectLater(repository.submitMaintenance(id: '88888888-8888-4888-8888-888888888888', bed: beds.single,
      title: 'Broken Bulb', description: 'Old allocation', priority: 'Medium'), throwsA(isA<IntegrationException>()));
    expect(backend.maintenance.length, 1);
    expect((await repository.getAssignedBeds()), isEmpty);
    final bedReads = backend.requests.where((r) => r.url.path == '/rest/v1/beds');
    expect(bedReads.every((r) => r.url.queryParameters['studentid'] == 'eq.$student'), isTrue);
  });
  test('Oversized or unsupported documents fail before any upload', () {
    expect(() => AccommodationRepository.documentMime('script.html'), throwsA(isA<IntegrationException>()));
    expect(() => AccommodationRepository.validateFile(PlatformFile(name: 'proof.pdf', size: 2,
      bytes: Uint8List.fromList([1, 2])), 1), throwsA(isA<IntegrationException>()));
  });
}
