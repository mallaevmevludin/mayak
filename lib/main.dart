import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/auth_service.dart';
import 'services/supabase_config.dart';
import 'services/social_service.dart';
import 'services/job_service.dart';
import 'services/chat_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/pending_verification_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  await NotificationService().init();

  // Request permissions asynchronously on startup
  _requestPermissionsOnStartup();

  // Initialize Supabase only if configured
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('Supabase successfully initialized.');
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  } else {
    debugPrint('Supabase URL/Key not set. Running in offline mock mode.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService()..initializeAuth(),
        ),
        ChangeNotifierProxyProvider<AuthService, SocialService>(
          create: (context) =>
              SocialService(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previousSocialService) =>
              previousSocialService ?? SocialService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, JobService>(
          create: (context) =>
              JobService(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previousJobService) =>
              previousJobService ?? JobService(authService),
        ),
        ChangeNotifierProxyProvider<AuthService, ChatService>(
          create: (context) =>
              ChatService(Provider.of<AuthService>(context, listen: false)),
          update: (context, authService, previousChatService) =>
              previousChatService ?? ChatService(authService),
        ),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          navigatorKey: AuthService.navigatorKey,
          title: 'Mayak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: Consumer<AuthService>(
            builder: (context, auth, _) {
              if (!auth.isInitialized) {
                return const SplashScreen();
              }
              if (auth.isInPasswordRecovery) {
                return const ResetPasswordScreen();
              }
              if (auth.pendingEmail != null) {
                return const PendingVerificationScreen();
              }
              return auth.currentUser != null
                  ? const MainNavigationScreen()
                  : const LoginScreen();
            },
          ),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/profile': (context) => const MainNavigationScreen(),
            '/pending-verification': (context) =>
                const PendingVerificationScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feed_rounded, size: 80, color: AppTheme.primary),
            SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _requestPermissionsOnStartup() async {
  try {
    await [
      Permission.camera,
      Permission.photos,
    ].request();
  } catch (e) {
    debugPrint('Error requesting startup permissions: $e');
  }
}
