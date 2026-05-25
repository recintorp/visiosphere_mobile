import 'dart:io';
import 'package:flutter/material.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import '../../assessment/services/assessment_api_service.dart';

class AdminAssessmentsProvider extends ChangeNotifier {
  final _assessmentService = AssessmentApiService();

  List<dynamic> _assessments = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _reportTitle = '';
  List<String> _reportTags = [];
  List<Map<String, dynamic>> _blocks = [];
  String? _editingId;

  final Map<String, QuillEditorController> _quillControllers = {};

  List<dynamic> get assessments => _assessments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get reportTitle => _reportTitle;
  List<String> get reportTags => _reportTags;
  List<Map<String, dynamic>> get blocks => _blocks;
  String? get editingId => _editingId;

  void setReportTitle(String title) {
    _reportTitle = title;
    notifyListeners();
  }

  void setReportTags(List<String> tags) {
    _reportTags = tags;
    notifyListeners();
  }

  void resetBuilder() {
    _reportTitle = '';
    _reportTags = [];
    _blocks = [];
    _editingId = null;
    for (var controller in _quillControllers.values) {
      controller.dispose();
    }
    _quillControllers.clear();
    notifyListeners();
  }

  void registerQuillController(String blockId, QuillEditorController controller) {
    _quillControllers[blockId] = controller;
  }

  Future<void> syncHtmlContentBeforeSave() async {
    for (var block in _blocks) {
      if (block['type'] == 'text') {
        final controller = _quillControllers[block['id']];
        if (controller != null) {
          block['content'] = await controller.getText();
        }
      }
    }
  }

  void loadReportForEditing(Map<String, dynamic> assessment) {
    _reportTitle = assessment['title'] ?? '';
    _reportTags = List<String>.from(assessment['tags'] ?? []);
    _editingId = assessment['_id'];

    for (var controller in _quillControllers.values) {
      controller.dispose();
    }
    _quillControllers.clear();

    if (assessment['blocks'] != null) {
      _blocks = List<Map<String, dynamic>>.from(
        (assessment['blocks'] as List).map((b) => {
          'id': b['_id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
          'type': b['type'],
          'content': b['content'],
          'fileUrl': b['fileUrl'],
        })
      );
    } else {
      _blocks = [];
    }
    notifyListeners();
  }

  Future<void> fetchAssessments(String residentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assessments = await _assessmentService.fetchByResident(residentId);
    } catch (e) {
      _assessments = [];
      _errorMessage = 'Failed to load assessments';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addBlock(String type) {
    final Map<String, dynamic> newBlock = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
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
    if (_quillControllers.containsKey(id)) {
      _quillControllers[id]?.dispose();
      _quillControllers.remove(id);
    }
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

  Future<bool> uploadFileToBlock(String id, File file) async {
    try {
      final result = await _assessmentService.uploadFile(file);
      updateBlockFile(id, result['fileUrl'] as String?);
      return true;
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }
    return false;
  }

  Future<bool> submitReport({
    required String residentId,
    required String residentName,
    required String authorId,
    required String authorName,
  }) async {
    if (_reportTitle.trim().isEmpty || _blocks.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    final payload = {
      'residentId': residentId,
      'residentName': residentName,
      'authorId': authorId,
      'authorName': authorName,
      'title': _reportTitle,
      'tags': _reportTags,
      'blocks': _blocks.map((b) => {
        'type': b['type'],
        'content': b['content'],
        'fileUrl': b['fileUrl'],
      }).toList(),
    };

    try {
      if (_editingId != null) {
        await _assessmentService.updateAssessment(_editingId!, payload);
      } else {
        await _assessmentService.addAssessment(payload);
      }
      resetBuilder();
      await fetchAssessments(residentId);
      return true;
    } catch (e) {
      debugPrint('Error submitting report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> deleteAssessment(String assessmentId, String residentId) async {
    try {
      await _assessmentService.deleteAssessment(assessmentId);
      await fetchAssessments(residentId);
      return true;
    } catch (e) {
      debugPrint('Error deleting assessment: $e');
    }
    return false;
  }

  Future<bool> sendComment({
    required String assessmentId,
    required String residentId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    try {
      await _assessmentService.addComment(assessmentId, {
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
      });
      await fetchAssessments(residentId);
      return true;
    } catch (e) {
      debugPrint('Error sending comment: $e');
    }
    return false;
  }
} 