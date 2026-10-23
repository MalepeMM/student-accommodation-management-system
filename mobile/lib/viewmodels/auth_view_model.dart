import 'package:flutter/foundation.dart';
import '../services/student_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Future<bool> validateCredentials(String email, String password) async {
    if (_isLoading) return false;
    _isLoading = true; _error = null; notifyListeners();
    try {
      await StudentAuthService.login(email, password);
      return true;
    } catch (error) {
      _error = StudentAuthService.errorMessage(error);
      return false;
    } finally { _isLoading = false; notifyListeners(); }
  }
}
