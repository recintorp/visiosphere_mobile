import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final String _baseUrl = ApiConstants.baseUrl;

  int _totalElders = 0;
  int _activeNurses = 0;
  int _alertsToday = 0;
  List<dynamic> _recentActivities = [];
  bool _isLoading = true;
  String? _errorMessage;

  int get totalElders => _totalElders;
  int get activeNurses => _activeNurses;
  int get alertsToday => _alertsToday;
  List<dynamic> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$_baseUrl/admin/stats')).timeout(const Duration(seconds: 8)),
        http.get(Uri.parse('$_baseUrl/audit-logs')).timeout(const Duration(seconds: 8)),
      ]);

      final statsRes = responses[0];
      final logsRes = responses[1];

      if (statsRes.statusCode == 200) {
        final statsData = json.decode(statsRes.body);
        _totalElders = statsData['elders'] ?? 0;
        _activeNurses = statsData['nurses'] ?? 0;
        _alertsToday = 0; 
      } else {
        throw Exception('Failed to load stats');
      }

      if (logsRes.statusCode == 200) {
        final List<dynamic> logsData = json.decode(logsRes.body);
        _recentActivities = logsData.take(4).toList();
      } else {
        throw Exception('Failed to load logs');
      }

    } catch (e) {
      print('Dashboard Error: $e');
      _errorMessage = 'Failed to load dashboard data. Please check your connection.';
      _totalElders = 0;
      _activeNurses = 0;
      _alertsToday = 0;
      _recentActivities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void retry() {
    fetchDashboardData();
  }
}