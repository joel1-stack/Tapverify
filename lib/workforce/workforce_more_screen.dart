import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import 'workforce_login_screen.dart';

/// Settings screen — simplified for manufacturing SMEs.
class WorkforceMoreScreen extends StatelessWidget {
  const WorkforceMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deep, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child:
                          Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'TapVerify',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Revenue proof for manufacturing SMEs',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkforceLoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.text,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}