import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/accommodation.dart';
import '../services/accommodation_repository.dart';
import '../services/student_auth_service.dart';

class ApplicationViewModel extends ChangeNotifier {
  ApplicationViewModel({AccommodationRepository? repository}) : _repository = repository ?? AccommodationRepository();
  final AccommodationRepository _repository;
  bool isSubmitting = false;
  String? error, applicationId;
  Future<bool> submit({required String id, required Accommodation room,
    required Map<String, dynamic> details, required List<PlatformFile> documents}) async {
    if (isSubmitting) return false;
    isSubmitting = true; error = null; notifyListeners();
    try { applicationId = await _repository.submitApplication(id: id, room: room, details: details, files: documents); return true; }
    catch (e) { error = StudentAuthService.errorMessage(e); return false; }
    finally { isSubmitting = false; notifyListeners(); }
  }
}
