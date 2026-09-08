import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  Future<AuditExportResult> exportToCSV() async {
    if (filteredLogs.isEmpty) return AuditExportResult.empty();

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

      // WHERE THE FILE GOES
      //
      // This used to write into getApplicationDocumentsDirectory() —
      // /data/user/0/<package>/app_flutter/. That path is inside the app's
      // private sandbox: no file manager can browse it, no spreadsheet app can
      // open it, and uninstalling the app deletes it. The export reported
      // success and handed the admin a path they could not reach.
      //
      // saveFile() hands the bytes to the platform's own save dialog, so the
      // admin picks Downloads (or anywhere else) and the CSV lands in real,
      // user-visible storage. It needs no storage permission, which matters:
      // writing straight to /storage/emulated/0/Download is blocked by scoped
      // storage on Android 10+ unless the app asks for broad file access.
      //
      // A BOM prefix keeps Excel from mangling non-ASCII names in the log.
      final bytes = utf8.encode('\uFEFF$csvContent');
      final dateString = DateTime.now().toIso8601String().split('T')[0];

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Audit Trail',
        fileName: 'VisioSphere_Audit_Logs_$dateString.csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: bytes,
      );

      // null means the admin backed out of the save dialog. That is not a
      // failure and must not be reported as one.
      if (savedPath == null) return AuditExportResult.cancelled();

      return AuditExportResult.saved(savedPath);
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return AuditExportResult.failed();
    }
  }
}

/// What came of an export attempt.
///
/// The screen used to get a bare `String?` back and had no way to separate
/// "nothing to export", "you cancelled the save dialog" and "it broke" — all
/// three arrived as null and were announced as a failure.
class AuditExportResult {
  const AuditExportResult._(this.status, this.path);

  final AuditExportStatus status;
  final String? path;

  factory AuditExportResult.saved(String path) =>
      AuditExportResult._(AuditExportStatus.saved, path);
  factory AuditExportResult.cancelled() =>
      const AuditExportResult._(AuditExportStatus.cancelled, null);
  factory AuditExportResult.empty() =>
      const AuditExportResult._(AuditExportStatus.empty, null);
  factory AuditExportResult.failed() =>
      const AuditExportResult._(AuditExportStatus.failed, null);
}

enum AuditExportStatus { saved, cancelled, empty, failed }