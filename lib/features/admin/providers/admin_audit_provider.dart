import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../audit/services/audit_api_service.dart';

class AdminAuditProvider extends ChangeNotifier {
  final _auditService = AuditApiService();

  List<dynamic> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _filterCategory = 'All';
  String _filterStatus = 'All';
  String _searchQuery = '';
  String _dateFilter = 'all';

  List<dynamic> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get filterCategory => _filterCategory;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;
  String get dateFilter => _dateFilter;

  List<String> get categories {
    final Set<String> cats = {'All'};
    for (var log in _logs) {
      if (log['category'] != null && log['category'].toString().isNotEmpty) {
        cats.add(log['category'].toString());
      }
    }
    return cats.toList();
  }

  List<String> get statuses => ['All', 'success', 'alert', 'failed'];

  List<dynamic> get filteredLogs {
    var result = _logs.toList();

    if (_filterCategory != 'All') {
      result = result.where((log) => log['category'] == _filterCategory).toList();
    }

    if (_filterStatus != 'All') {
      result = result.where((log) => log['status'] == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((log) {
        final event = (log['event'] ?? '').toString().toLowerCase();
        final actor = (log['actorName'] ?? '').toString().toLowerCase();
        final newVals = (log['newValues'] ?? {}).toString().toLowerCase();
        final oldVals = (log['oldValues'] ?? {}).toString().toLowerCase();

        return event.contains(query) ||
               actor.contains(query) ||
               newVals.contains(query) ||
               oldVals.contains(query);
      }).toList();
    }

    if (_dateFilter != 'all') {
      final now = DateTime.now();
      result = result.where((log) {
        final logStr = log['timestamp'] ?? log['createdAt'];
        if (logStr == null) return false;

        DateTime logDate;
        try {
          logDate = DateTime.parse(logStr.toString());
        } catch (_) {
          return true;
        }

        if (_dateFilter == 'today') {
          return logDate.year == now.year && logDate.month == now.month && logDate.day == now.day;
        } else if (_dateFilter == 'week') {
          return logDate.isAfter(now.subtract(const Duration(days: 7)));
        } else if (_dateFilter == 'month') {
          return logDate.isAfter(now.subtract(const Duration(days: 30)));
        }
        return true;
      }).toList();
    }

    return result;
  }

  Future<void> fetchAuditLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _auditService.fetchAuditLogs();
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      _errorMessage = 'Failed to load audit logs.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterCategory(String category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateFilter(String dateFilter) {
    _dateFilter = dateFilter;
    notifyListeners();
  }

  void clearFilters() {
    _filterCategory = 'All';
    _filterStatus = 'All';
    _searchQuery = '';
    _dateFilter = 'all';
    notifyListeners();
  }

  Future<String?> exportToCSV() async {
    if (filteredLogs.isEmpty) return null;

    try {
      final headers = ['ID', 'Timestamp', 'Category', 'Event', 'Actor Name', 'Status', 'Purpose', 'Old Values', 'New Values'];

      final rows = filteredLogs.map((log) {
        final dateStr = log['createdAt'] ?? log['timestamp'];
        final formattedDate = dateStr != null ? DateTime.parse(dateStr.toString()).toString() : '';

        String escapeCSV(dynamic value) {
          if (value == null) return '""';
          return '"${value.toString().replaceAll('"', '""')}"';
        }

        return [
          escapeCSV(log['_id']),
          escapeCSV(formattedDate),
          escapeCSV(log['category']),
          escapeCSV(log['event']),
          escapeCSV(log['actorName']),
          escapeCSV(log['status']),
          escapeCSV(log['purpose']),
          escapeCSV(log['oldValues']),
          escapeCSV(log['newValues']),
        ].join(',');
      }).toList();

      final csvContent = [headers.join(','), ...rows].join('\n');

      final directory = await getApplicationDocumentsDirectory();
      final dateString = DateTime.now().toIso8601String().split('T')[0];
      final file = File('${directory.path}/VisioSphere_Audit_Logs_$dateString.csv');

      await file.writeAsString(csvContent);
      return file.path;
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }
}