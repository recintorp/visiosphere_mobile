import 'package:flutter/material.dart';
import '../../../core/constants/facilities.dart';
import '../../../core/services/secure_storage_service.dart';
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

  // Starts unfiltered rather than on a named house: which houses exist depends
  // on the signed-in user's facility, and Saint Anthony has no 'House of St.
  // Charbel' to default to.
  String _selectedHouse = Facilities.allHouses;
  String _searchTerm = '';
  String _filterAttendance = 'All';
  String _filterNotes = 'All';

  /// Houses for the signed-in user's facility, resolved in [loadHouses].
  /// Empty for an unknown facility rather than falling back to every house —
  /// an empty list is an obvious bug report, whereas a silent fallback would
  /// offer one facility's houses to the other.
  List<String> houses = const [];

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

  /// Resolve the house list for the signed-in user's facility. Cheap and
  /// idempotent, so it is simply re-run on each load.
  Future<void> loadHouses() async {
    houses = Facilities.housesFor(await SecureStorageService.getFacility());
    if (_selectedHouse != Facilities.allHouses && !houses.contains(_selectedHouse)) {
      _selectedHouse = Facilities.allHouses;
    }
    notifyListeners();
  }

  Future<void> fetchResidents({String? userRole, String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await loadHouses();

    try {
      // WHERE A NURSE'S RESIDENT LIST COMES FROM.
      //
      // At Grace's a nurse carries a named caseload, so her list is exactly the
      // residents assigned to her. At Saint Anthony there is no assignment step
      // at all — one building, one shared floor, every nurse on shift
      // responsible for everyone — so her list is every resident the facility
      // has. The backend already scopes that query to her facility
      // (models/plugins/facilityScope.js), so "all residents" can never mean
      // another facility's residents.
      //
      // This also brings mobile in line with the web, where EldersDashboard.jsx
      // has always called getAllResidents() regardless of role.
      final assignsElders = Facilities.assignsEldersToNurses(
          Facilities.facilityOf(userId));

      if (userRole == 'Nurse' && userId != null && assignsElders) {
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