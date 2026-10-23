import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/shared_records.dart';
import '../services/accommodation_repository.dart';
import '../services/student_auth_service.dart';

class MaintenanceViewModel extends ChangeNotifier {
  MaintenanceViewModel({AccommodationRepository? repository}) : _repository = repository ?? AccommodationRepository();
  final AccommodationRepository _repository;
  List<SharedMaintenance> requests = [];
  bool busy = false;
  String? error;
  Future<void> load() async {
    try { requests = await _repository.getRequests(); error = null; }
    catch (e) { error = StudentAuthService.errorMessage(e); }
    notifyListeners();
  }
  Future<bool> addRequest({required String id, required AssignedBed bed,
    required String category, required String description, required String priority, PlatformFile? photo}) async {
    if (busy) return false;
    busy = true; error = null; notifyListeners();
    try {
      await _repository.submitMaintenance(id: id, bed: bed, title: category, description: description, priority: priority, photo: photo);
      await load(); return true;
    } catch (e) { error = StudentAuthService.errorMessage(e); return false; }
    finally { busy = false; notifyListeners(); }
  }
}
