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

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

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
        return authProvider.isAdmin ? '/admin' : '/home';
      }
      if (isAuthenticated &&
          !authProvider.isAdmin &&
          loc.startsWith('/admin')) {
        return '/home';
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-reports',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const MyReportsScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ordinances',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const OrdinancesScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alerts',
                pageBuilder: (_, s) =>
                    NoTransitionPage(child: const AlertsScreen()),
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
        path: '/community-reports',
        pageBuilder: (_, s) => _fadePage(const CommunityReportsScreen(), s),
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
                    parentNavigatorKey: _rootNavigatorKey,
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
    ],
  );
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your email to receive a password reset link.'),
            const SizedBox(height: 16),
            if (_sent)
              const Text(
                'Reset email sent! Check your inbox.',
                style: TextStyle(color: Colors.green),
              )
            else ...[
              TextField(
                controller: _ctrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final ok = await auth.sendPasswordReset(_ctrl.text.trim());
                  if (ok) setState(() => _sent = true);
                },
                child: const Text('Send Reset Link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF0038A8),
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Brgy. ${user.barangay}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: const Text('Phone'),
                        subtitle: Text(user.phone),
                      ),
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Role'),
                        subtitle: Text(user.role.toUpperCase()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => auth.signOut(),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
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
