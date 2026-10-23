import 'package:flutter/foundation.dart';
import '../models/accommodation.dart';
import '../services/accommodation_repository.dart';

/// Owns listing/search state; the view renders state and forwards user actions.
class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel({AccommodationRepository? repository}) : _repository = repository ?? AccommodationRepository();
  final AccommodationRepository _repository;
  List<Accommodation> _all = [];
  List<Accommodation> _visible = [];
  String _query = '';
  bool _loading = false;
  String? _error;
  List<Accommodation> get accommodations => List.unmodifiable(_visible);
  bool get isLoading => _loading;
  String? get error => _error;
  String get query => _query;

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try { _all = await _repository.getAccommodations(); _filter(); }
    catch (_) { _error = 'Could not load accommodation. Please try again.'; }
    finally { _loading = false; notifyListeners(); }
  }
  void search(String value) { _query = value; _filter(); notifyListeners(); }
  void _filter() { final q = _query.trim().toLowerCase(); _visible = _all.where((a) => a.title.toLowerCase().contains(q) || a.type.toLowerCase().contains(q)).toList(); }
}
