import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';

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

/// TapVerify color system, derived from the brand logo (green shield +
/// checkmark with an orange accent). Every screen reads from these constants,
/// so a palette change is one edit here.
const kPrimary = Color(0xFF00A86B); // TapVerify Green: brand, buttons, paid
const kPrimaryDark = Color(0xFF007A4D); // Deep Green: pressed, headers, footer
const kDarkGreen = Color(0xFF005F3C); // Dark Green: gradients, photo overlays
const kPrimaryLight = Color(0xFFE6F7F0); // Light Green: soft highlights, bg
const kSoftGreen = Color(0xFFC8E6D7); // Soft Green: secondary light green
const kAccent = Color(0xFFF5A623); // Orange: reminders, outstanding, badges
const kAccentDark = Color(0xFFE08E0B); // Orange: hover / pressed / link text
const kSuccess = Color(0xFF00A86B); // Paid, verified, completed
const kWarning = Color(0xFFF5A623); // Pending, needs attention
const kDanger = Color(0xFFEF4444); // Failed, overdue, delete
const kInfo = Color(0xFF3B82F6); // Neutral information
const kBrandInk = Color(0xFF1A1A1A); // Near Black: main text
const kTextDark = Color(0xFF333333); // Dark Gray: secondary text
const kSurface = Color(0xFFF8FAF9); // Off White: app background
const kHairline = Color(0xFFE5E7EB); // Borders, dividers
const kMuted = Color(0xFF6B7280); // Placeholders, icons
const kPrimaryBorder = Color(0xFFA7F3D0); // Soft green outline on white

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
  /// token and unwinds to the root, which reappears as Login on mobile and the
  /// landing page on web.
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

/// Shows Home when a login token exists.
///
/// Signed out: the landing/demo page on web, the login screen on mobile.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AuthState.signedIn,
      builder: (context, signedIn, _) {
        // Mobile is the product: straight to login, no marketing demo.
        // Web is the demo: landing page first, login pushed from it.
        final child = signedIn
            ? const HomeScreen()
            : kIsWeb
                ? const LandingScreen()
                : const LoginScreen();
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
