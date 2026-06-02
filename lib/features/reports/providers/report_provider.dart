import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/report_service.dart';

enum ReportSubmitStatus { idle, loading, success, error }

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  ReportSubmitStatus _submitStatus = ReportSubmitStatus.idle;
  String? _errorMessage;
  String? _lastReportId;

  ReportSubmitStatus get submitStatus => _submitStatus;
  String? get errorMessage => _errorMessage;
  String? get lastReportId => _lastReportId;

  Future<bool> submitReport({
    required String userId,
    required String userFullName,
    required String userBarangay,
    required String category,
    required String description,
    required String barangay,
    required double latitude,
    required double longitude,
    required String address,
    required List<File> photos,
    bool isAnonymous = false,
  }) async {
    _submitStatus = ReportSubmitStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastReportId = await _service.submitReport(
        userId: userId,
        userFullName: userFullName,
        userBarangay: userBarangay,
        category: category,
        description: description,
        barangay: barangay,
        latitude: latitude,
        longitude: longitude,
        address: address,
        photos: photos,
        isAnonymous: isAnonymous,
      );
      _submitStatus = ReportSubmitStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit report. Please try again.';
      _submitStatus = ReportSubmitStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _submitStatus = ReportSubmitStatus.idle;
    _errorMessage = null;
    _lastReportId = null;
    notifyListeners();
  }

  Stream<List<ReportModel>> getUserReports(String userId) =>
      _service.getUserReports(userId);

  Stream<List<ReportModel>> getAllReports({
    String? statusFilter,
    String? barangayFilter,
  }) => _service.getAllReports(
    statusFilter: statusFilter,
    barangayFilter: barangayFilter,
  );

  Stream<ReportModel?> getReport(String id) => _service.getReport(id);

  Future<void> updateStatus({
    required String reportId,
    required String newStatus,
    required String updatedBy,
    String? note,
    File? afterPhoto,
  }) => _service.updateStatus(
    reportId: reportId,
    newStatus: newStatus,
    updatedBy: updatedBy,
    note: note,
    afterPhoto: afterPhoto,
  );
}
