import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../data/models/report_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/widgets/mobile_shell.dart';
import '../providers/report_provider.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Pending', 'In Progress', 'Completed'];

  // Map filter label to actual statuses
  List<String> get _matchStatuses {
    switch (_filter) {
      case 'Pending':
        return [
          AppConstants.statusSubmitted,
          AppConstants.statusSeen,
          AppConstants.statusValidated,
          AppConstants.statusQueued,
        ];
      case 'In Progress':
        return [AppConstants.statusInProgress];
      case 'Completed':
        return [AppConstants.statusCompleted];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    final provider = context.read<ReportProvider>();

    return MobileShell(
      title: 'My Reports',
      currentIndex: 1,
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Track the live status of your submitted reports.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                // Filter tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.textDark : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? AppTheme.textDark
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: active ? Colors.white : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: provider.getUserReports(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var reports = snapshot.data ?? [];
                if (_filter != 'All') {
                  reports = reports
                      .where((r) => _matchStatuses.contains(r.currentStatus))
                      .toList();
                }
                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_filter reports.',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ReportCard(
                    report: reports[i],
                    onTap: () => context.push('/report/${reports[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  static const _steps = [
    'Submitted',
    'Validated',
    'Queued',
    'In Progress',
    'Completed',
  ];

  static const _categoryIcons = {
    'Road Damage': '🚧',
    'Drainage / Flooding': '🌊',
    'Broken Streetlight': '💡',
    'Garbage / Waste': '🗑️',
    'Public Facility': '🏛️',
    'Water Supply': '💧',
    'Illegal Structure': '🏗️',
    'Other': '❓',
  };

  int get _currentStep {
    final idx = _steps.indexOf(report.currentStatus);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.statusColor(report.currentStatus);
    final isDone = report.currentStatus == AppConstants.statusCompleted;
    final isProgress = report.currentStatus == AppConstants.statusInProgress;
    final emoji = _categoryIcons[report.category] ?? '📋';
    final date = DateFormat('MMM d, y').format(report.createdAt);

    return PressCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Brgy. ${report.barangay} · $date',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isDone
                      ? 'Done'
                      : isProgress
                      ? 'In Progress'
                      : report.currentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress tracker
          _ProgressTracker(steps: _steps, currentStep: _currentStep),
          if (isDone && report.afterPhotoUrl != null) ...[
            const SizedBox(height: 10),
            const Text(
              '✓ Completion photo attached',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressTracker extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const _ProgressTracker({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final label = e.value;
        final done = i <= currentStep;
        final active = i == currentStep;
        final color = done ? AppTheme.primaryBlue : const Color(0xFFD1D5DB);

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: active ? 14 : 10,
                      height: active ? 14 : 10,
                      decoration: BoxDecoration(
                        color: done ? color : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        color: done ? AppTheme.textDark : AppTheme.textMuted,
                        fontWeight: done ? FontWeight.w500 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < currentStep
                        ? AppTheme.primaryBlue
                        : const Color(0xFFD1D5DB),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
