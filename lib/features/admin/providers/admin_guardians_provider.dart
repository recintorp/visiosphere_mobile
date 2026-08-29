import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../guardian/services/guardian_api_service.dart';
import '../../residents/services/resident_api_service.dart';

/// Pull the backend's own explanation out of a failure.
///
/// WHY THIS EXISTS
///
/// Every write in this provider used to swallow the exception into a
/// debugPrint and hand the UI a bare `false`, which the panels turned into
/// "Failed to provision account." — a sentence that is true of a duplicate
/// email, an expired session, a rejected field and a dead network alike. The
/// backend already sends a specific `message` on every one of those; it was
/// simply being thrown away, and the operator was left guessing.
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

class AdminGuardiansProvider extends ChangeNotifier {
  final _guardianService = GuardianApiService();
  final _residentService = ResidentApiService();

  List<dynamic> _guardians = [];
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchTerm = '';
  String _sortOrder = 'default';
  String _statusFilter = 'ALL';

  List<dynamic> get guardians => _guardians;
  List<dynamic> get residents => _residents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchTerm => _searchTerm;
  String get sortOrder => _sortOrder;
  String get statusFilter => _statusFilter;

  List<dynamic> get filteredGuardians {
    var filtered = _guardians.where((guardian) {
      if (_statusFilter != 'ALL' && (guardian['status'] ?? '').toString().toUpperCase() != _statusFilter) {
        return false;
      }

      final firstName = guardian['firstName'] ?? '';
      final middleName = guardian['middleName'] ?? '';
      final lastName = guardian['lastName'] ?? '';
      final fullName = '$firstName $middleName $lastName'.toLowerCase();

      final guardianId = (guardian['guardianId'] ?? '').toString().toLowerCase();
      final email = (guardian['email'] ?? '').toString().toLowerCase();

      final eldersList = guardian['assignedElders'] as List<dynamic>? ?? [];
      final assignedStr = eldersList.map((e) => '${e['firstName']} ${e['lastName']}').join(', ').toLowerCase();

      final searchLower = _searchTerm.toLowerCase();

      return fullName.contains(searchLower) ||
             guardianId.contains(searchLower) ||
             email.contains(searchLower) ||
             assignedStr.contains(searchLower);
    }).toList();

    if (_sortOrder == 'asc') {
      filtered.sort((a, b) {
        final nameA = '${a['firstName']} ${a['lastName']}'.toLowerCase();
        final nameB = '${b['firstName']} ${b['lastName']}'.toLowerCase();
        return nameA.compareTo(nameB);
      });
    } else if (_sortOrder == 'desc') {
      filtered.sort((a, b) {
        final nameA = '${a['firstName']} ${a['lastName']}'.toLowerCase();
        final nameB = '${b['firstName']} ${b['lastName']}'.toLowerCase();
        return nameB.compareTo(nameA);
      });
    }

    return filtered;
  }

  Future<void> fetchGuardians() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _guardians = await _guardianService.fetchAllGuardians();
    } catch (e) {
      debugPrint('Error fetching guardians: $e');
      _errorMessage = 'Failed to load guardians.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchResidents() async {
    try {
      _residents = await _residentService.fetchAllResidents();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching residents: $e');
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void toggleSortOrder(String order) {
    _sortOrder = _sortOrder == order ? 'default' : order;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    notifyListeners();
  }

  Future<bool> addGuardian(Map<String, dynamic> guardianData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _guardianService.addGuardian(guardianData);
      final newGuardian = result['guardian'] ?? result;
      _guardians.add(newGuardian);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding guardian: $e');
      _errorMessage = _failureMessage(e, 'Failed to provision account.');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateGuardian(String id, Map<String, dynamic> updateData) async {
    _errorMessage = null;

    try {
      final result = await _guardianService.updateGuardian(id, updateData);
      final updatedGuardian = result['guardian'] ?? result;
      final index = _guardians.indexWhere((g) => g['guardianId'] == id || g['_id'] == id);
      if (index != -1) {
        _guardians[index] = updatedGuardian;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error updating guardian: $e');
      _errorMessage = _failureMessage(e, 'Failed to update account.');
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteMultipleGuardians(Set<String> ids) async {
    try {
      await Future.wait(ids.map((id) => _guardianService.deleteGuardian(id)));
      _guardians.removeWhere((g) => ids.contains(g['guardianId']) || ids.contains(g['_id']));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting guardians: $e');
    }
    return false;
  }

  Future<bool> linkResidentToGuardian(String guardianId, String residentId) async {
    try {
      final result = await _guardianService.linkElder(guardianId, residentId);
      final updatedGuardian = result['guardian'] ?? result;
      final index = _guardians.indexWhere((g) => g['guardianId'] == guardianId || g['_id'] == guardianId);
      if (index != -1) {
        _guardians[index] = updatedGuardian;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error linking resident: $e');
    }
    return false;
  }

  Future<bool> unlinkResidentFromGuardian(String guardianId, String residentId) async {
    try {
      final result = await _guardianService.unlinkElder(guardianId, residentId);
      final updatedGuardian = result['guardian'] ?? result;
      final index = _guardians.indexWhere((g) => g['guardianId'] == guardianId || g['_id'] == guardianId);
      if (index != -1) {
        _guardians[index] = updatedGuardian;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error unlinking resident: $e');
    }
    return false;
  }
}