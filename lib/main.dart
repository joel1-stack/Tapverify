import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/member_home_screen.dart';
import 'services/hive_service.dart';
import 'constants.dart';

/// Application entry point: boots Hive, then hands off to [TapVerifyApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveService.init();
  runApp(const TapVerifyApp());
}

/// Root widget. Applies the global TapVerify Material 3 theme (Trust Teal seed,
/// Inter font, custom button/input/card styling) and starts at [SplashScreen].
class TapVerifyApp extends StatelessWidget {
  const TapVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapVerify',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Desktop web: cap the app to a centered 960px column so forms, tables
        // and demo mockups never stretch edge-to-edge. Phones/tablets keep the
        // full-width layout.
        return LayoutBuilder(
          builder: (context, constraints) {
            if (child == null) return const SizedBox.shrink();
            if (constraints.maxWidth <= 1000) return child;
            return ColoredBox(
              color: AppColors.deep,
              child: Center(
                child: SizedBox(
                  width: 960,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 40,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.loop,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.deep,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// Route guard: checks the persisted login token and shows [HomeShell] for
/// logged-in treasurers, otherwise the [LoginScreen]. Renders a small loading
/// spinner while the token check is pending.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: HiveService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          if (HiveService.isMemberSession) {
            final staff = HiveService.getStaff();
            return MemberHomeScreen(
              phone: staff?['phone']?.toString() ?? '',
              name: staff?['name']?.toString() ?? 'Member',
            );
          }
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}
