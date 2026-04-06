import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminEldersProvider extends ChangeNotifier {
  List<dynamic> _residents = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedHouse = 'House of St. Charble';
  String _searchTerm = '';
  String _filterAttendance = 'All';
  String _filterNotes = 'All';

  final List<String> houses = [
    'House of St. Charble',
    'House of St. Gabriell',
    'House of St. Rose of Lima',
    'House of St. Sebastian',
  ];

  List<dynamic> get residents => _residents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedHouse => _selectedHouse;
  String get filterAttendance => _filterAttendance;
  String get filterNotes => _filterNotes;

  List<dynamic> get houseResidents {
    return _residents.where((r) => r['house'] == _selectedHouse).toList();
  }

  List<dynamic> get filteredResidents {
    return houseResidents.where((resident) {
      final firstName = resident['firstName'] ?? '';
      final middleName = resident['middleName'] ?? '';
      final lastName = resident['lastName'] ?? '';
      final fullName = '$firstName $middleName $lastName'.toLowerCase();
      final searchLower = _searchTerm.toLowerCase();

      final matchesSearch = fullName.contains(searchLower);
      
      final attendance = resident['attendance'] ?? '';
      final matchesAttendance = _filterAttendance == 'All' || 
          (_filterAttendance == 'Present' && attendance == 'Present') ||
          (_filterAttendance == 'Not Present' && attendance == 'Not Present');

      final notes = resident['notes'] ?? '';
      final hasNotes = notes.toString().trim().isNotEmpty;
      final matchesNotes = _filterNotes == 'All' ||
          (_filterNotes == 'WithNotes' && hasNotes) ||
          (_filterNotes == 'NoNotes' && !hasNotes);

      return matchesSearch && matchesAttendance && matchesNotes;
    }).toList();
  }

  int get houseHeadcount => houseResidents.length;
  int get presentCount => houseResidents.where((r) => r['attendance'] == 'Present').length;
  int get notPresentCount => houseResidents.where((r) => r['attendance'] == 'Not Present').length;
  int get withNotesCount => houseResidents.where((r) => (r['notes'] ?? '').toString().trim().isNotEmpty).length;

  Future<void> fetchResidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.fetchAllResidents();
      if (result['success']) {
        _residents = result['data'] is List ? result['data'] : result['data']['residents'] ?? [];
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      debugPrint('Error fetching residents: $e');
      _errorMessage = 'Failed to load residents. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setHouse(String house) {
    _selectedHouse = house;
    notifyListeners();
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setFilterAttendance(String filter) {
    _filterAttendance = filter;
    notifyListeners();
  }

  void setFilterNotes(String filter) {
    _filterNotes = filter;
    notifyListeners();
  }

  Future<bool> addResident(Map<String, dynamic> residentData) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await ApiService.addResident(residentData);
      if (result['success']) {
        final newResident = result['data']['resident'] ?? result['data'];
        _residents.add(newResident);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = result['message'];
    } catch (e) {
      debugPrint('Error adding resident: $e');
      _errorMessage = 'Failed to add resident.';
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateResident(String id, Map<String, dynamic> updateData) async {
    try {
      final result = await ApiService.updateResident(id, updateData);
      if (result['success']) {
        final updatedResident = result['data']['resident'] ?? result['data'];
        final index = _residents.indexWhere((r) => r['_id'] == id || r['id'] == id);
        if (index != -1) {
          _residents[index] = updatedResident;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error updating resident: $e');
    }
    return false;
  }

  Future<bool> deleteResident(String id) async {
    try {
      final result = await ApiService.deleteResident(id);
      if (result['success']) {
        _residents.removeWhere((r) => r['_id'] == id || r['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting resident: $e');
    }
    return false;
  }

  Future<bool> updateAttendance(String id, String? status) async {
    final updateData = {'attendance': status};
    
    final index = _residents.indexWhere((r) => r['_id'] == id || r['id'] == id);
    if (index != -1) {
      _residents[index]['attendance'] = status;
      notifyListeners();
    }
    
    final success = await updateResident(id, updateData);
    if (!success) {
      await fetchResidents();
    }
    return success;
  }

  Future<bool> saveNotes(String id, String notes) async {
    return await updateResident(id, {'notes': notes});
  }
}