import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../../data/services/geofence_service.dart';
import '../../../data/services/report_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/mobile_shell.dart';
import '../providers/report_provider.dart';

class SubmitReportScreen extends StatefulWidget {
  const SubmitReportScreen({super.key});

  @override
  State<SubmitReportScreen> createState() => _SubmitReportScreenState();
}

class _SubmitReportScreenState extends State<SubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedBarangay;
  final List<File> _photos = [];
  final List<XFile> _photosWeb = [];
  double? _latitude;
  double? _longitude;
  String _address = '';
  bool _gettingLocation = false;
  bool _isInsidePila = false;
  List<ReportModel> _similarReports = [];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final photoCount = kIsWeb ? _photosWeb.length : _photos.length;
    if (photoCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 photos allowed.')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      if (kIsWeb) {
        setState(() => _photosWeb.add(picked));
      } else {
        final dir = await getTemporaryDirectory();
        final targetPath =
            '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          picked.path,
          targetPath,
          quality: 70,
          minWidth: 1280,
          minHeight: 720,
        );
        if (compressed != null) {
          setState(() => _photos.add(File(compressed.path)));
        }
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final result = await GeofenceService.checkCurrentLocation();

      if (result.error != null) {
        throw Exception(result.error);
      }

      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _isInsidePila = result.isInsidePila;
        _address = result.latitude != null && result.longitude != null
            ? '${result.latitude!.toStringAsFixed(5)}, ${result.longitude!.toStringAsFixed(5)}'
            : '';
      });

      if (!_isInsidePila && mounted) {
        _showLocationRestrictionDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  void _showLocationRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Restriction'),
        content: const Text(
          'Reporting is only available for users currently located within the Municipality of Pila.\n\nYou can still browse reports and updates, but cannot create new reports from your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForDuplicates() async {
    if (_selectedCategory == null ||
        _selectedBarangay == null ||
        _descCtrl.text.trim().isEmpty) {
      return;
    }

    try {
      final similar = await ReportService().findSimilarReports(
        category: _selectedCategory!,
        barangay: _selectedBarangay!,
        description: _descCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (similar.isNotEmpty && mounted) {
        setState(() => _similarReports = similar);
        _showDuplicateDialog();
      }
    } catch (e) {
      // Silent fail - duplicate check is not critical
    }
  }

  void _showDuplicateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            const Text('Similar Report Exists'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good news! This issue has already been reported and is being tracked by the community.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_outline,
                      color: AppTheme.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Follow the existing report to add your support and get updates on its progress. More followers = higher priority for admin!',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_similarReports.isNotEmpty) ...[
                const Text(
                  'Existing reports:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ..._similarReports
                    .take(3)
                    .map(
                      (report) => GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/report/${report.id}');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${report.category} - Brgy. ${report.barangay}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.statusColor(
                                          report.currentStatus,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        report.currentStatus,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.statusColor(
                                            report.currentStatus,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  report.description.length > 70
                                      ? '${report.description.substring(0, 70)}...'
                                      : report.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${report.followerCount} ${report.followerCount == 1 ? 'follower' : 'followers'}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              if (_similarReports.isNotEmpty) {
                context.go('/report/${_similarReports.first.id}');
              }
            },
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('View Report'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              if (_similarReports.isNotEmpty) {
                final auth = context.read<AuthProvider>();
                await ReportService().followReport(
                  _similarReports.first.id,
                  auth.user!.uid,
                );
                if (mounted) {
                  AppToast.show(
                    context,
                    'You\'re now following this report! Admin will be notified.',
                    type: ToastType.success,
                  );
                  context.go('/report/${_similarReports.first.id}');
                }
              }
            },
            icon: const Icon(Icons.notifications_active, size: 18),
            label: const Text('Follow & Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final photoCount = kIsWeb ? _photosWeb.length : _photos.length;
    if (photoCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }
    if (_latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your GPS location first.')),
      );
      return;
    }
    if (!_isInsidePila) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be within Pila municipality to submit a report.',
          ),
        ),
      );
      return;
    }

    // Check for duplicates before submitting
    await _checkForDuplicates();
    if (_similarReports.isNotEmpty) {
      // User will be shown duplicate dialog, don't proceed with submission
      return;
    }

    final auth = context.read<AuthProvider>();
    final provider = context.read<ReportProvider>();
    final user = auth.user!;
    final success = await provider.submitReport(
      userId: user.uid,
      userFullName: user.fullName,
      userBarangay: user.barangay,
      category: _selectedCategory!,
      description: _descCtrl.text.trim(),
      barangay: _selectedBarangay!,
      latitude: _latitude!,
      longitude: _longitude!,
      address: _address,
      photos: kIsWeb ? null : _photos,
      photosWeb: kIsWeb ? _photosWeb : null,
      isAnonymous: false, // Always show user's name
    );
    if (success && mounted) {
      AppToast.show(
        context,
        'Report submitted successfully!',
        type: ToastType.success,
      );
      context.go('/report/${provider.lastReportId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final isLoading = provider.submitStatus == ReportSubmitStatus.loading;

    return MobileShell(
      title: 'Report an Issue',
      currentIndex: -1,
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Submit a Report',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Help us improve Pila by reporting community issues.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),

              // Photos
              const Text(
                'PHOTOS *',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (kIsWeb)
                      ..._photosWeb.map(
                        (f) => _PhotoThumbnailWeb(
                          file: f,
                          onRemove: () => setState(() => _photosWeb.remove(f)),
                        ),
                      )
                    else
                      ..._photos.map(
                        (f) => _PhotoThumbnail(
                          file: f,
                          onRemove: () => setState(() => _photos.remove(f)),
                        ),
                      ),
                    if ((kIsWeb ? _photosWeb.length : _photos.length) < 3)
                      _AddPhotoButton(
                        onCamera: () => _pickImage(ImageSource.camera),
                        onGallery: () => _pickImage(ImageSource.gallery),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Issue Category *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.issueCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Barangay
              DropdownButtonFormField<String>(
                initialValue: _selectedBarangay,
                decoration: const InputDecoration(
                  labelText: 'Barangay *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: AppConstants.barangays
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBarangay = v),
                validator: (v) => v == null ? 'Please select a barangay' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 16),

              // GPS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _latitude != null
                      ? (_isInsidePila
                            ? AppTheme.successGreen.withValues(alpha: 0.08)
                            : AppTheme.primaryRed.withValues(alpha: 0.08))
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _latitude != null
                        ? (_isInsidePila
                              ? AppTheme.successGreen.withValues(alpha: 0.4)
                              : AppTheme.primaryRed.withValues(alpha: 0.4))
                        : AppTheme.borderColor,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _latitude != null
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed,
                          color: _latitude != null
                              ? (_isInsidePila
                                    ? AppTheme.successGreen
                                    : AppTheme.primaryRed)
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _latitude != null
                                ? (_isInsidePila
                                      ? 'Location: $_address'
                                      : 'Outside Pila municipality')
                                : 'GPS location not yet captured',
                            style: TextStyle(
                              fontSize: 13,
                              color: _latitude != null
                                  ? (_isInsidePila
                                        ? AppTheme.successGreen
                                        : AppTheme.primaryRed)
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _gettingLocation ? null : _getLocation,
                          child: _gettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _latitude != null ? 'Refresh' : 'Get GPS',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    if (_latitude != null && !_isInsidePila) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'You must be within Pila municipality to submit a report. You can still browse existing reports.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryRed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (provider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: AppTheme.primaryRed),
                  ),
                ),

              ElevatedButton.icon(
                onPressed: (isLoading || !_isInsidePila) ? null : _submit,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(isLoading ? 'Submitting...' : 'Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoThumbnail({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumbnailWeb extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _PhotoThumbnailWeb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  );
                }
                return Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _AddPhotoButton({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  onCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  onGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppTheme.textMuted),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
