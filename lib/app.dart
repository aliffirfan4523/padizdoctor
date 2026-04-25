import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:padizdoctor/l10n/app_localizations.dart';
import 'package:padizdoctor/features/auth/screens/signin_screen.dart';
import 'package:padizdoctor/features/auth/screens/signup_screen.dart';
import 'package:padizdoctor/features/auth/screens/change_password_page.dart';
import 'package:padizdoctor/features/camera_gallery/screens/analysis_confirmation.dart';
import 'package:padizdoctor/features/user/screens/all_scans_history.dart';
import 'package:padizdoctor/features/user/screens/detection_analysis_result.dart';
import '../../../model/model.dart';

import 'features/main_wrapper/app_navigation_view.dart';
import 'core/theme/app_fonts.dart';
import 'features/onboarding/screens/intro_page.dart';
import 'features/onboarding/services/splash_decider.dart';
import 'features/settings/services/settings_controller.dart';
import 'features/settings/screens/settings_view.dart';

// ─── Route name constants ────────────────────────────────────────────────────
/// Central registry of all named routes in the app.
/// Use these constants everywhere — never hard-code the strings.

// ─── Typed argument classes ──────────────────────────────────────────────────

// ─── App widget ──────────────────────────────────────────────────────────────

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            fontFamilyFallback: [AppFonts.displayFont, AppFonts.bodyFont],
          ),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,
          home: const SplashDecider(),

          // ── Simple routes (no required constructor arguments) ─────────────
          routes: {
            AppRoutes.intro: (_) => IntroPage(controller: settingsController),
            AppRoutes.home: (_) =>
                MainNavigationView(controller: settingsController),
            AppRoutes.login: (ctx) =>
                SignInScreen(ctx, controller: settingsController),
            AppRoutes.signup: (ctx) =>
                SignUpScreen(ctx, controller: settingsController),
            AppRoutes.changePassword: (_) => const ChangePasswordPage(),
            AppRoutes.allScans: (_) => const AllScansHistoryScreen(),
            AppRoutes.settings: (_) =>
                SettingsView(controller: settingsController),
          },

          // ── Parametric routes (require typed arguments) ───────────────────
          onGenerateRoute: (RouteSettings routeSettings) {
            switch (routeSettings.name) {
              case AppRoutes.analysisResult:
                final args = routeSettings.arguments as AnalysisResultsArgs;
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (_) => AnalysisResultsScreen(
                    recordId: args.recordId,
                    imageId: args.imageId,
                    userId: args.userId,
                  ),
                );

              case AppRoutes.analysisConfirmation:
                final args =
                    routeSettings.arguments as AnalysisConfirmationArgs;
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (_) => AnalysisConfirmationScreen(
                    state: args.state,
                    imageFile: args.imageFile,
                    recordId: args.recordId,
                    imageId: args.imageId,
                    errorMessage: args.errorMessage,
                    onRetry: args.onRetry,
                  ),
                );

              case SettingsView.routeName:
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (_) => SettingsView(controller: settingsController),
                );

              default:
                return MaterialPageRoute<void>(
                  settings: routeSettings,
                  builder: (_) =>
                      MainNavigationView(controller: settingsController),
                );
            }
          },
        );
      },
    );
  }
}
