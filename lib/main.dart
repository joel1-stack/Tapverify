import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';

/// Where the API lives.
///
/// Set it at build time:
///   flutter run   --dart-define=API_BASE_URL=http://10.0.2.2:8000   (Android)
///   flutter build web --release \
///       --dart-define=API_BASE_URL=https://your-backend-host
///
/// The default is the local Django dev server, so a fresh clone runs offline
/// against `python manage.py runserver` with no extra setup.
const kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

const kPrimary = Color(0xFF0D9488);
const kPrimaryDark = Color(0xFF0F766E);
const kSuccess = Color(0xFF16A34A);
const kDanger = Color(0xFFDC2626);
const kBrandInk = Color(0xFF111827);
const kSurface = Color(0xFFF9FAFB);
const kHairline = Color(0xFFE5E7EB);
const kMuted = Color(0xFF6B7280);

/// True while the app is pointed at a local development backend. The web build
/// then shows a small strip so nobody mistakes a dev build for production.
bool get kUsingLocalBackend =>
    kApiBaseUrl.contains('127.0.0.1') || kApiBaseUrl.contains('localhost');

/// A release build still aimed at localhost cannot reach any server. That was
/// silent, so the published site looked broken with no explanation.
bool get kBackendMisconfigured => kReleaseMode && kUsingLocalBackend;

/// The app-wide navigator, so a dead token can unwind to the landing page even
/// when the rejection happens deep inside a modal.
final GlobalKey<NavigatorState> kNavigatorKey = GlobalKey<NavigatorState>();

/// Single source of truth for "is somebody signed in".
class AuthState {
  AuthState._();

  static final ValueNotifier<bool> signedIn = ValueNotifier<bool>(false);

  /// Reads the stored token once at startup.
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    signedIn.value = token != null && token.isNotEmpty;
  }

  static void markSignedIn() => signedIn.value = true;

  static Future<void> signOut() async {
    await Api.clearToken();
    signedIn.value = false;
  }

  /// Called by [Api] when the server rejects the stored token. Clears the dead
  /// token and unwinds to the root, which now shows the landing page.
  static void expire() {
    Api.clearToken();
    signedIn.value = false;
    kNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TapVerifyApp());
}

class TapVerifyApp extends StatefulWidget {
  const TapVerifyApp({super.key});

  @override
  State<TapVerifyApp> createState() => _TapVerifyAppState();
}

class _TapVerifyAppState extends State<TapVerifyApp> {
  @override
  void initState() {
    super.initState();
    AuthState.restore();
    Api.onUnauthorized = AuthState.expire;
  }

  @override
  void dispose() {
    Api.onUnauthorized = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mixed typography: Plus Jakarta Sans for headings, Inter for body.
    final base = ThemeData(useMaterial3: true);
    final bodyTheme = GoogleFonts.interTextTheme(base.textTheme);
    final headingTheme = GoogleFonts.plusJakartaSansTextTheme(bodyTheme);

    return MaterialApp(
      title: 'TapVerify',
      debugShowCheckedModeBanner: false,
      navigatorKey: kNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary, primary: kPrimary),
        scaffoldBackgroundColor: kSurface,
        textTheme: bodyTheme.apply(
          bodyColor: kBrandInk,
          displayColor: kBrandInk,
        ).copyWith(
          headlineLarge: headingTheme.headlineLarge,
          headlineMedium: headingTheme.headlineMedium,
          headlineSmall: headingTheme.headlineSmall,
          titleLarge: headingTheme.titleLarge,
          titleMedium: headingTheme.titleMedium,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kHairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kHairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
            TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          },
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      home: const _Gate(),
    );
  }
}

/// Shows Home when a login token exists, otherwise the public landing page.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.signedIn,
      builder: (context, signedIn, _) {
        final child = signedIn ? const HomeScreen() : const LandingScreen();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<bool>(signedIn),
            child: child,
          ),
        );
      },
    );
  }
}
