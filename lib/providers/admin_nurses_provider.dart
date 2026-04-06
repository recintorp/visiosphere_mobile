import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class AdminNursesProvider extends ChangeNotifier {
  final String _baseUrl = ApiConstants.baseUrl;

  List<dynamic> _nurses = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _searchTerm = '';
  String _filterStatus = 'All';
  String _sortOrder = 'default';

  List<dynamic> get nurses {
    var filtered = _nurses.where((nurse) {
      final firstName = nurse['firstName'] ?? '';
      final lastName = nurse['lastName'] ?? '';
      final fullName = '$firstName $lastName'.toLowerCase();
      final nurseId = (nurse['nurseId'] ?? '').toLowerCase();
      final searchLower = _searchTerm.toLowerCase();

      final matchesSearch = fullName.contains(searchLower) || nurseId.contains(searchLower);
      final matchesStatus = _filterStatus == 'All' || nurse['status'] == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    if (_sortOrder == 'asc') {
      filtered.sort((a, b) => ('${a['firstName']} ${a['lastName']}').toLowerCase().compareTo(('${b['firstName']} ${b['lastName']}').toLowerCase()));
    } else if (_sortOrder == 'desc') {
      filtered.sort((a, b) => ('${b['firstName']} ${b['lastName']}').toLowerCase().compareTo(('${a['firstName']} ${a['lastName']}').toLowerCase()));
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
      final response = await http.get(Uri.parse('$_baseUrl/nurses/all')).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        _nurses = json.decode(response.body);
      } else {
        throw Exception('Failed to load nurses');
      }
    } catch (e) {
      debugPrint('Fetch Nurses Error: $e');
      _errorMessage = 'Failed to load nurses. Please check your connection.';
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

  Future<bool> deleteNurse(String nurseId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/nurses/$nurseId'));
      if (response.statusCode == 200) {
        _nurses.removeWhere((n) => n['nurseId'] == nurseId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete error: $e');
      return false;
    }
  }
}