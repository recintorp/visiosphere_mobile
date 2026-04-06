import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminGuardiansProvider extends ChangeNotifier {
  List<dynamic> _guardians = [];
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchTerm = '';
  String _sortOrder = 'default';

  List<dynamic> get guardians => _guardians;
  List<dynamic> get residents => _residents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchTerm => _searchTerm;
  String get sortOrder => _sortOrder;

  List<dynamic> get filteredGuardians {
    var filtered = _guardians.where((guardian) {
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
      final result = await ApiService.fetchAllGuardians();
      if (result['success']) {
        _guardians = result['data'] is List ? result['data'] : result['data']['guardians'] ?? [];
      } else {
        _errorMessage = result['message'];
      }
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
      final result = await ApiService.fetchAllResidents();
      if (result['success']) {
        _residents = result['data'] is List ? result['data'] : result['data']['residents'] ?? [];
        notifyListeners();
      }
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

  Future<bool> addGuardian(Map<String, dynamic> guardianData) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await ApiService.addGuardianAccount(guardianData);
      if (result['success']) {
        final newGuardian = result['data']['guardian'] ?? result['data'];
        _guardians.add(newGuardian);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = result['message'];
    } catch (e) {
      debugPrint('Error adding guardian: $e');
      _errorMessage = 'Failed to add guardian.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateGuardian(String id, Map<String, dynamic> updateData) async {
    try {
      final result = await ApiService.updateGuardianDetails(id, updateData);
      if (result['success']) {
        final updatedGuardian = result['data']['guardian'] ?? result['data'];
        final index = _guardians.indexWhere((g) => g['guardianId'] == id || g['_id'] == id);
        if (index != -1) {
          _guardians[index] = updatedGuardian;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating guardian: $e');
    }
    return false;
  }

  Future<bool> deleteMultipleGuardians(Set<String> ids) async {
    bool allSuccess = true;
    try {
      for (String id in ids) {
        final result = await ApiService.deleteGuardianAccount(id);
        if (!result['success']) {
          allSuccess = false;
        }
      }
      if (allSuccess) {
        _guardians.removeWhere((g) => ids.contains(g['guardianId']) || ids.contains(g['_id']));
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting guardians: $e');
    }
    return false;
  }

  Future<bool> linkResidentToGuardian(String guardianId, String residentId) async {
    try {
      final result = await ApiService.linkElderToGuardian(guardianId, residentId);
      if (result['success']) {
        final updatedGuardian = result['data']['guardian'] ?? result['data'];
        final index = _guardians.indexWhere((g) => g['guardianId'] == guardianId || g['_id'] == guardianId);
        if (index != -1) {
          _guardians[index] = updatedGuardian;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error linking resident: $e');
    }
    return false;
  }
}