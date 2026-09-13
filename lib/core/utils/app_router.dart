import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/modern_login_screen.dart';
import '../../features/auth/screens/modern_register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/reports/screens/submit_report_screen.dart';
import '../../features/reports/screens/report_detail_screen.dart';
import '../../features/reports/screens/my_reports_screen.dart';
import '../../features/reports/screens/community_reports_screen.dart';
import '../../features/ordinances/screens/ordinances_screen.dart';
import '../../features/ordinances/screens/ordinance_detail_screen.dart';
import '../../features/admin/screens/admin_scaffold.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_report_detail_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_alerts_screen.dart';
import '../../features/admin/screens/admin_ordinances_screen.dart';
import '../../features/admin/screens/admin_map_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/help/screens/faq_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/department/screens/department_scaffold_widget.dart';
import '../../features/department/screens/department_dashboard_screen.dart';
import '../../features/department/screens/department_reports_screen.dart';
import '../../features/department/screens/department_report_detail_screen.dart';
import '../../features/department/screens/department_map_screen.dart';
import '../../features/department/screens/department_notifications_screen.dart';
import '../../features/department/screens/department_settings_screen.dart';
import '../../features/department/screens/department_analytics_screen.dart';
import '../../features/barangay/screens/barangay_scaffold_widget.dart';
import '../../features/barangay/screens/barangay_dashboard_screen.dart';
import '../../features/barangay/screens/barangay_reports_screen.dart';
import '../../features/barangay/screens/barangay_report_detail_screen.dart';
import '../../features/barangay/screens/barangay_map_screen.dart';
import '../../features/barangay/screens/barangay_notifications_screen.dart';
import '../../features/barangay/screens/barangay_analytics_screen.dart';
import '../../features/barangay/screens/barangay_settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _fadePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

// Branch navigator keys — must be top-level to avoid duplicate key errors
final _adminDashKey = GlobalKey<NavigatorState>();
final _adminReportsKey = GlobalKey<NavigatorState>();
final _adminUsersKey = GlobalKey<NavigatorState>();
final _adminAnalyticsKey = GlobalKey<NavigatorState>();
final _adminMapKey = GlobalKey<NavigatorState>();
final _adminOrdinancesKey = GlobalKey<NavigatorState>();
final _adminAlertsKey = GlobalKey<NavigatorState>();
final _adminSettingsKey = GlobalKey<NavigatorState>();
final _deptDashKey = GlobalKey<NavigatorState>();
final _deptReportsKey = GlobalKey<NavigatorState>();
final _deptAnalyticsKey = GlobalKey<NavigatorState>();
final _deptMapKey = GlobalKey<NavigatorState>();
final _deptNotificationsKey = GlobalKey<NavigatorState>();
final _deptSettingsKey = GlobalKey<NavigatorState>();
final _brgyDashKey = GlobalKey<NavigatorState>();
final _brgyReportsKey = GlobalKey<NavigatorState>();
final _brgyAnalyticsKey = GlobalKey<NavigatorState>();
final _brgyMapKey = GlobalKey<NavigatorState>();
final _brgyNotificationsKey = GlobalKey<NavigatorState>();
final _brgySettingsKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final status = authProvider.status;
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/pending-approval';

      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      final isAuthenticated = authProvider.isAuthenticated;
      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && (loc == '/login' || loc == '/register')) {
        if (authProvider.isAdmin) return '/admin';
        if (authProvider.isDepartment) return '/department';
        if (authProvider.isBarangay) return '/barangay';
        return '/home';
      }
      if (isAuthenticated &&
          !authProvider.isAdmin &&
          !authProvider.isDepartment &&
          loc.startsWith('/admin')) {
        return '/home';
      }
      if (isAuthenticated &&
          !authProvider.isAdmin &&
          loc.startsWith('/admin')) {
        return '/department';
      }
      if (isAuthenticated &&
          !authProvider.isDepartment &&
          loc.startsWith('/department')) {
        return authProvider.isAdmin ? '/admin' : '/home';
      }
      if (isAuthenticated &&
          !authProvider.isBarangay &&
          loc.startsWith('/barangay')) {
        return authProvider.isAdmin ? '/admin' : '/home';
      }
      return null;
    },
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (_, s) => _fadePage(const ModernLoginScreen(), s),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, s) => _fadePage(const ModernRegisterScreen(), s),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (_, s) => _fadePage(const ForgotPasswordScreen(), s),
      ),

      // Mobile shell with persistent bottom nav
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) => shell,
        branches: [
          // index 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const HomeScreen()),
              ),
            ],
          ),
          // index 1 — My Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-reports',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const MyReportsScreen()),
              ),
            ],
          ),
          // index 2 — Ordinances / Laws
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ordinances',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const OrdinancesScreen()),
              ),
            ],
          ),
          // index 3 — Community Reports
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community-reports',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const CommunityReportsScreen()),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/report/new',
        pageBuilder: (_, s) => _fadePage(const SubmitReportScreen(), s),
      ),
      GoRoute(
        path: '/alerts',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, s) => _fadePage(const AlertsScreen(), s),
      ),
      GoRoute(
        path: '/report/:id',
        pageBuilder: (_, s) =>
            _fadePage(ReportDetailScreen(reportId: s.pathParameters['id']!), s),
      ),
      GoRoute(
        path: '/ordinance/:id',
        pageBuilder: (_, s) => _fadePage(
          OrdinanceDetailScreen(ordinanceId: s.pathParameters['id']!),
          s,
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (_, s) => _fadePage(const ProfileScreen(), s),
      ),
      GoRoute(
        path: '/faq',
        pageBuilder: (_, s) => _fadePage(const FaqScreen(), s),
      ),
      GoRoute(
        path: '/pending-approval',
        pageBuilder: (_, s) => _fadePage(const PendingApprovalScreen(), s),
      ),

      // Admin shell with persistent sidebar + animated content
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) =>
            AdminScaffoldWidget(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _adminDashKey,
            routes: [
              GoRoute(
                path: '/admin',
                builder: (_, s) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminReportsKey,
            routes: [
              GoRoute(
                path: '/admin/reports',
                builder: (_, s) => const AdminReportsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => AdminReportDetailScreen(
                      reportId: s.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminUsersKey,
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (_, s) => const AdminUsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminAnalyticsKey,
            routes: [
              GoRoute(
                path: '/admin/analytics',
                builder: (_, s) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminMapKey,
            routes: [
              GoRoute(
                path: '/admin/map',
                builder: (_, s) => const AdminMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminOrdinancesKey,
            routes: [
              GoRoute(
                path: '/admin/ordinances',
                builder: (_, s) => const AdminOrdinancesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminAlertsKey,
            routes: [
              GoRoute(
                path: '/admin/alerts',
                builder: (_, s) => const AdminAlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _adminSettingsKey,
            routes: [
              GoRoute(
                path: '/admin/settings',
                builder: (_, s) => const AdminSettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Department portal — sidebar shell (same pattern as admin)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) =>
            DepartmentScaffoldWidget(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _deptDashKey,
            routes: [
              GoRoute(
                path: '/department',
                builder: (_, s) => const DepartmentDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _deptReportsKey,
            routes: [
              GoRoute(
                path: '/department/reports',
                builder: (_, s) => const DepartmentReportsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => DepartmentReportDetailScreen(
                      reportId: s.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _deptAnalyticsKey,
            routes: [
              GoRoute(
                path: '/department/analytics',
                builder: (_, s) => const DepartmentAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _deptMapKey,
            routes: [
              GoRoute(
                path: '/department/map',
                builder: (_, s) => const DepartmentMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _deptNotificationsKey,
            routes: [
              GoRoute(
                path: '/department/notifications',
                builder: (_, s) => const DepartmentNotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _deptSettingsKey,
            routes: [
              GoRoute(
                path: '/department/settings',
                builder: (_, s) => const DepartmentSettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Barangay portal — sidebar shell (mirrors department)
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) =>
            BarangayScaffoldWidget(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _brgyDashKey,
            routes: [
              GoRoute(
                path: '/barangay',
                builder: (_, s) => const BarangayDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _brgyReportsKey,
            routes: [
              GoRoute(
                path: '/barangay/reports',
                builder: (_, s) => const BarangayReportsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) => BarangayReportDetailScreen(
                      reportId: s.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _brgyAnalyticsKey,
            routes: [
              GoRoute(
                path: '/barangay/analytics',
                builder: (_, s) => const BarangayAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _brgyMapKey,
            routes: [
              GoRoute(
                path: '/barangay/map',
                builder: (_, s) => const BarangayMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _brgyNotificationsKey,
            routes: [
              GoRoute(
                path: '/barangay/notifications',
                builder: (_, s) => const BarangayNotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _brgySettingsKey,
            routes: [
              GoRoute(
                path: '/barangay/settings',
                builder: (_, s) => const BarangaySettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendPasswordReset(_emailCtrl.text.trim());
    if (mounted) {
      setState(() {
        _loading = false;
        if (ok) {
          _sent = true;
        } else {
          _error = 'No account found for that email. Please check and try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
        title: const Text('Forgot Password',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: _sent ? _SuccessView(email: _emailCtrl.text.trim()) : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock_reset_rounded, size: 48, color: Color(0xFF6366F1)),
                const SizedBox(height: 16),
                const Text(
                  'Reset your password',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the email address you used when signing up. We\'ll send you a link to reset your password.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Reset Link',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 72, color: Color(0xFF10B981)),
        const SizedBox(height: 20),
        const Text(
          'Check your inbox',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'A password reset link has been sent to\n$email\n\nClick the link in the email to set a new password.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back to Login',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 72,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Registration Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your registration is under review. The LGU admin will verify your valid ID and approve your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will be able to log in once your account is approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
