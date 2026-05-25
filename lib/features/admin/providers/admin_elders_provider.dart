import 'package:flutter/material.dart';
import '../../residents/services/resident_api_service.dart';
import '../../nurse/services/nurse_api_service.dart';

class AdminEldersProvider extends ChangeNotifier {
  final _residentService = ResidentApiService();
  final _nurseService = NurseApiService();

  List<dynamic> _residents = [];
  List<dynamic> _archivedReports = [];

  bool _isLoading = true;
  bool _isLoadingArchives = false;
  String? _errorMessage;

  String _selectedHouse = 'House of St. Charbel';
  String _searchTerm = '';
  String _filterAttendance = 'All';
  String _filterNotes = 'All';

  final List<String> houses = [
    'House of St. Charbel',
    'House of St. Francis',
    'House of St. Gabriel',
    'House of St. Rose of Lima',
    'House of St. Sebastian',
    'Louis S. Coson Hall'
  ];

  List<dynamic> get residents => _residents;
  List<dynamic> get archivedReports => _archivedReports;
  bool get isLoading => _isLoading;
  bool get isLoadingArchives => _isLoadingArchives;
  String? get errorMessage => _errorMessage;
  String get selectedHouse => _selectedHouse;
  String get filterAttendance => _filterAttendance;
  String get filterNotes => _filterNotes;

  List<dynamic> get houseResidents {
    if (_selectedHouse == 'Overall Facility') return _residents;
    return _residents.where((r) => r['house'] == _selectedHouse).toList();
  }

  List<dynamic> get filteredResidents {
    return houseResidents.where((resident) {
      final firstName = resident['firstName'] ?? '';
      final middleName = resident['middleName'] ?? '';
      final lastName = resident['lastName'] ?? '';
      final residentId = resident['residentId'] ?? '';
      final fullName = '$firstName $middleName $lastName'.toLowerCase();
      final searchLower = _searchTerm.toLowerCase();

      final matchesSearch = fullName.contains(searchLower) || residentId.toLowerCase().contains(searchLower);

      final attendance = resident['attendance'];
      final matchesAttendance = _filterAttendance == 'All' ||
          (_filterAttendance == 'Present' && attendance == 'Present') ||
          (_filterAttendance == 'Not Present' && (attendance == 'Not Present' || attendance == null));

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
  int get notPresentCount => houseResidents.where((r) => r['attendance'] == 'Not Present' || r['attendance'] == null).length;
  int get withNotesCount => houseResidents.where((r) => (r['notes'] ?? '').toString().trim().isNotEmpty).length;

  Future<void> fetchResidents({String? userRole, String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (userRole == 'Nurse' && userId != null) {
        final nurseData = await _nurseService.getNurseProfile(userId);
        _residents = nurseData['assignedElders'] ?? [];
      } else {
        _residents = await _residentService.fetchAllResidents();
      }
    } catch (e) {
      debugPrint('Fetch Residents Error: $e');
      _errorMessage = 'Secure connection timeout. Verify network status.';
      _residents = [];
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
    try {
      final result = await _residentService.addResident(residentData);
      final newResident = result['resident'] ?? result;
      _residents.insert(0, newResident);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Add Resident Error: $e');
      return false;
    }
  }

  Future<bool> updateResident(String id, Map<String, dynamic> updateData) async {
    try {
      final result = await _residentService.updateResident(id, updateData);
      final updatedResident = result['resident'] ?? result;
      final index = _residents.indexWhere((r) => r['_id'] == id);
      if (index != -1) {
        _residents[index] = updatedResident;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Update Resident Error: $e');
      return false;
    }
  }

  Future<bool> deleteResident(String id) async {
    try {
      await _residentService.deleteResident(id);
      _residents.removeWhere((r) => r['_id'] == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Delete Resident Error: $e');
      return false;
    }
  }

  Future<bool> updateAttendance(String id, String? status) async {
    final index = _residents.indexWhere((r) => r['_id'] == id);
    String? previousStatus;
    if (index != -1) {
      previousStatus = _residents[index]['attendance'];
      _residents[index]['attendance'] = status;
      notifyListeners();
    }

    final success = await updateResident(id, {'attendance': status});

    if (!success && index != -1) {
      _residents[index]['attendance'] = previousStatus;
      notifyListeners();
    }
    return success;
  }

  Future<bool> saveNotes(String id, String notes) async {
    return await updateResident(id, {'notes': notes});
  }

  Future<void> fetchArchivedReports() async {
    _isLoadingArchives = true;
    notifyListeners();

    try {
      _archivedReports = await _residentService.fetchArchivedReports();
    } catch (e) {
      debugPrint('Fetch Archives Error: $e');
      _archivedReports = [];
    } finally {
      _isLoadingArchives = false;
      notifyListeners();
    }
  }

  Future<bool> saveReport(Map<String, dynamic> reportData) async {
    try {
      await _residentService.saveReport(reportData);
      await fetchArchivedReports();
      return true;
    } catch (e) {
      debugPrint('Save Report Error: $e');
      return false;
    }
  }
}