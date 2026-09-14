import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/services/global_notification_manager.dart';
import 'core/providers/notification_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/reports/providers/report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Firestore settings for web to prevent cache issues
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled:
            false, // Disable persistence on web to avoid cache issues
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const IpilaApp());
}

class IpilaApp extends StatelessWidget {
  const IpilaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = createRouter(authProvider);
    
    // Initialize global notification manager with root navigator key
    GlobalNotificationManager.initialize(rootNavigatorKey);
    
    // Listen for auth changes
    authProvider.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    final user = authProvider.user;
    
    if (user == null) {
      // User logged out - stop polling
      notificationProvider.stopPolling();
    } else {
      // User logged in - start polling for notifications
      notificationProvider.startPolling(user.uid);
    }
  }

  @override
  void dispose() {
    final authProvider = context.read<AuthProvider>();
    authProvider.removeListener(_onAuthChanged);
    context.read<NotificationProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iPILA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      builder: (context, child) {
        // Start notification polling when user is authenticated
        final user = context.watch<AuthProvider>().user;
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notificationProvider = context.read<NotificationProvider>();
            notificationProvider.startPolling(user.uid);
            // Process any pending notifications
            GlobalNotificationManager.processPendingNotifications();
          });
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
