import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/screens/admin/admin_dashboard_screen.dart';
import 'package:nyarongo_wholesale/screens/auth/auth_screen.dart';
import 'package:nyarongo_wholesale/screens/auth/splash_screen.dart';
import 'package:nyarongo_wholesale/screens/customer/customer_home_screen.dart';
import 'package:nyarongo_wholesale/screens/worker/worker_dashboard_screen.dart';
import 'package:nyarongo_wholesale/theme_manager.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/utils/enums.dart';

class NyarongoWholesaleApp extends StatefulWidget {
  final bool firebaseReady;
  final String? firebaseErrorMessage;

  const NyarongoWholesaleApp({
    super.key,
    required this.firebaseReady,
    this.firebaseErrorMessage,
  });

  @override
  State<NyarongoWholesaleApp> createState() => _NyarongoWholesaleAppState();
}

class _NyarongoWholesaleAppState extends State<NyarongoWholesaleApp> {
  bool _showSplash = true;
  UserRole? _activeRole;
  String _displayName = 'Guest User';

  void _handleSplashComplete() {
    setState(() => _showSplash = false);
  }

  void _handleAuthenticated({
    required UserRole role,
    required String displayName,
  }) {
    setState(() {
      _activeRole = role;
      _displayName = displayName;
    });
  }

  void _handleSignOut() {
    setState(() {
      _activeRole = null;
      _displayName = 'Guest User';
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
          themeMode: themeMode,
          theme: ThemeData(
            colorScheme: lightScheme,
            scaffoldBackgroundColor: AppConstants.backgroundColor,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppConstants.surfaceColor,
              foregroundColor: AppConstants.textPrimaryColor,
              elevation: 0,
              centerTitle: false,
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppConstants.textPrimaryColor,
              contentTextStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            cardTheme: CardThemeData(
              color: lightScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppConstants.primaryColor),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkScheme.surface,
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: darkScheme.surface,
              foregroundColor: darkScheme.onSurface,
              elevation: 0,
              centerTitle: false,
            ),
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: darkScheme.surface,
              contentTextStyle: TextStyle(color: darkScheme.onSurface),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            cardTheme: CardThemeData(
              color: darkScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: darkScheme.primary),
              ),
            ),
          ),
          builder: (context, child) {
            final content = child ?? const SizedBox.shrink();
            if (widget.firebaseReady) {
              return content;
            }

            return Column(
              children: [
                Material(
                  color: const Color(0xFFFFF4E5),
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        widget.firebaseErrorMessage == null
                            ? 'Firebase is unavailable right now. Core app screens will still work, but video upload/listing is disabled.'
                            : 'Firebase failed to start: ${widget.firebaseErrorMessage}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF8A4B00),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ),
                Expanded(child: content),
              ],
            );
          },
          home: _buildHome(),
        );
      },
    );
  }

  Widget _buildHome() {
    if (_showSplash) {
      return SplashScreen(onFinished: _handleSplashComplete);
    }

    if (_activeRole == null) {
      return AuthScreen(onAuthenticated: _handleAuthenticated);
    }

    switch (_activeRole!) {
      case UserRole.customer:
        return CustomerHomeScreen(
          displayName: _displayName,
          onSignOut: _handleSignOut,
          firebaseReady: widget.firebaseReady,
        );
      case UserRole.admin:
        return AdminDashboardScreen(
          displayName: _displayName,
          onSignOut: _handleSignOut,
          firebaseReady: widget.firebaseReady,
        );
      case UserRole.worker:
        return WorkerDashboardScreen(
          displayName: _displayName,
          onSignOut: _handleSignOut,
        );
    }
  }
}
