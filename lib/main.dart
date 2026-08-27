import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'workforce/workforce_login_screen.dart';

/// TapVerify — verified revenue history for manufacturing SMEs, jua kali
/// workshops, and businesses. Customers pay via WhatsApp links or USSD;
/// business owners track everything in the app or on the web dashboard.
void main() {
  runApp(const TapVerifyApp());
}

/// Root widget. Applies the global TapVerify Material 3 theme (Trust Teal seed,
/// Inter font, custom button/input/card styling).
class TapVerifyApp extends StatelessWidget {
  const TapVerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapVerify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
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
            side: BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const WorkforceLoginScreen(),
    );
  }
}