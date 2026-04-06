import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminAssessmentsProvider extends ChangeNotifier {
  List<dynamic> _assessments = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _reportTitle = '';
  List<Map<String, dynamic>> _blocks = [];

  List<dynamic> get assessments => _assessments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get reportTitle => _reportTitle;
  List<Map<String, dynamic>> get blocks => _blocks;

  void setReportTitle(String title) {
    _reportTitle = title;
    notifyListeners();
  }

  void resetBuilder() {
    _reportTitle = '';
    _blocks = [];
    notifyListeners();
  }

  Future<void> fetchAssessments(String residentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.fetchAssessments(residentId);
      if (result['success']) {
        _assessments = result['data'] is List ? result['data'] : [];
      } else {
        _assessments = [];
      }
    } catch (e) {
      _assessments = [];
      debugPrint('Error fetching assessments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addBlock(String type) {
    final Map<String, dynamic> newBlock = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'content': type == 'checklist' 
          ? [{'text': '', 'checked': false}] 
          : type == 'chart' 
              ? {
                  'chartType': 'temperature',
                  'chartTitle': 'Temperature Tracking',
                  'dataPoints': [{'label': '', 'value': 0.0}]
                }
              : '',
      'fileUrl': null,
    };
    _blocks.add(newBlock);
    notifyListeners();
  }

  void removeBlock(String id) {
    _blocks.removeWhere((b) => b['id'] == id);
    notifyListeners();
  }

  void updateBlockContent(String id, dynamic newContent) {
    final index = _blocks.indexWhere((b) => b['id'] == id);
    if (index != -1) {
      _blocks[index]['content'] = newContent;
      notifyListeners();
    }
  }

  void updateBlockFile(String id, String? url) {
    final index = _blocks.indexWhere((b) => b['id'] == id);
    if (index != -1) {
      _blocks[index]['fileUrl'] = url;
      notifyListeners();
    }
  }

  Future<bool> submitReport({
    required String residentId,
    required String residentName,
    required String authorId,
    required String authorName,
  }) async {
    if (_reportTitle.trim().isEmpty || _blocks.isEmpty) return false;

    final payload = {
      'residentId': residentId,
      'residentName': residentName,
      'authorId': authorId,
      'authorName': authorName,
      'title': _reportTitle,
      'blocks': _blocks.map((b) => {
        'type': b['type'],
        'content': b['content'],
        'fileUrl': b['fileUrl'],
      }).toList(),
    };

    try {
      final result = await ApiService.addAssessment(payload);
      if (result['success']) {
        resetBuilder();
        await fetchAssessments(residentId);
        return true;
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
    }
    return false;
  }

  Future<bool> deleteAssessment(String assessmentId, String residentId) async {
    try {
      final result = await ApiService.deleteAssessment(assessmentId);
      if (result['success']) {
        await fetchAssessments(residentId);
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting assessment: $e');
    }
    return false;
  }
}