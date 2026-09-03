import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../nurse/services/nurse_api_service.dart';
import '../../residents/services/resident_api_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Pull the backend's own explanation out of a failure.
///
/// provisionNurse() used to swallow the exception into a debugPrint and return
/// a bare `false`, which the panel turned into "Failed to provision account" —
/// the same sentence for a duplicate email, an expired session and a dead
/// network. The backend sends a specific `message` for each; it was simply
/// being discarded.
String _failureMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (error.response == null) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return '$fallback (HTTP ${error.response?.statusCode}).';
  }
  return fallback;
}

class AdminNursesProvider extends ChangeNotifier {
  final _nurseService = NurseApiService();
  final _residentService = ResidentApiService();

  List<dynamic> _nurses = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchTerm = '';
  String _filterStatus = 'All';
  String _sortOrder = 'default';

  List<dynamic> get nurses {
    var filtered = _nurses.where((nurse) {
      // Searching and sorting run on the SAME name the card prints. Filtering
      // on the legal name while showing the Display Name means typing the name
      // you can see returns nothing, and the list sorts in an order that looks
      // random on screen.
      final fullName = AuthProvider.resolveName(nurse).toLowerCase();
      final nurseId = (nurse['nurseId'] ?? '').toLowerCase();
      final searchLower = _searchTerm.toLowerCase();

      final matchesSearch = fullName.contains(searchLower) || nurseId.contains(searchLower);
      final matchesStatus = _filterStatus == 'All' || nurse['status'] == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    if (_sortOrder == 'asc') {
      filtered.sort((a, b) => AuthProvider.resolveName(a).toLowerCase().compareTo(AuthProvider.resolveName(b).toLowerCase()));
    } else if (_sortOrder == 'desc') {
      filtered.sort((a, b) => AuthProvider.resolveName(b).toLowerCase().compareTo(AuthProvider.resolveName(a).toLowerCase()));
    }

    return filtered;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;

  Future<void> fetchNurses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _nurses = await _nurseService.fetchAllNurses();
    } catch (e) {
      debugPrint('Fetch Nurses Error: $e');
      _errorMessage = 'Secure connection timeout. Verify network status.';
      _nurses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void toggleSortOrder() {
    if (_sortOrder == 'default') {
      _sortOrder = 'asc';
    } else if (_sortOrder == 'asc') {
      _sortOrder = 'desc';
    } else {
      _sortOrder = 'default';
    }
    notifyListeners();
  }

  Future<bool> provisionNurse(Map<String, dynamic> nurseData) async {
    _errorMessage = null;
    try {
      final result = await _nurseService.provisionNurse(nurseData);
      final newNurse = result['nurse'] ?? result;
      _nurses.insert(0, newNurse);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Provision Error: $e');
      _errorMessage = _failureMessage(e, 'Failed to provision account.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNurseProfile(String nurseId, Map<String, dynamic> updatedData) async {
    try {
      final result = await _nurseService.updateNurse(nurseId, updatedData);
      final index = _nurses.indexWhere((n) => n['nurseId'] == nurseId);
      if (index != -1) {
        _nurses[index] = result['nurse'] ?? result;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Profile update error: $e');
      return false;
    }
  }

  Future<bool> deleteNurse(String nurseId) async {
    try {
      await _nurseService.deleteNurse(nurseId);
      _nurses.removeWhere((n) => n['nurseId'] == nurseId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }

  Future<List<dynamic>> fetchAvailableElders() async {
    try {
      return await _residentService.fetchAllResidents();
    } catch (e) {
      debugPrint('Fetch Elders Error: $e');
      return [];
    }
  }

  Future<bool> assignElderToNurse(String nurseId, String elderId) async {
    try {
      final result = await _nurseService.assignElder(nurseId, elderId);
      final index = _nurses.indexWhere((n) => n['nurseId'] == nurseId);
      if (index != -1) {
        _nurses[index] = result['nurse'] ?? result;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Assign Elder Error: $e');
      return false;
    }
  }

  Future<bool> unassignElderFromNurse(String nurseId, String elderId) async {
    try {
      final result = await _nurseService.unassignElder(nurseId, elderId);
      final index = _nurses.indexWhere((n) => n['nurseId'] == nurseId);
      if (index != -1) {
        _nurses[index] = result['nurse'] ?? result;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Unassign Elder Error: $e');
      return false;
    }
  }
}