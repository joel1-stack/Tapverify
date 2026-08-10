import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController(text: '2547');
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.login(_phoneCtrl.text.trim(), _pinCtrl.text.trim());
      if (result['success'] == true) {
        await HiveService.saveAuth(result['token'], result['staff']);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        setState(() => _error = result['error'] ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Check connection.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'TapVerify',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0f172a),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Proof of payment for Kenya\'s groups',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),
              // Phone
              Text(
                'Phone Number',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '254712345678',
                  prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF059669)),
                ),
              ),
              const SizedBox(height: 20),
              // PIN
              Text(
                'PIN Code',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.inter(fontSize: 16, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '••••',
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                  counterText: '',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Text(_error!, style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 28),
              // Login button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Login'),
                ),
              ),
              const SizedBox(height: 40),
              // Demo button
              TextButton(
                onPressed: () async {
                  setState(() => _loading = true);
                  try {
                    await ApiService.createDemo();
                    _phoneCtrl.text = '254712345678';
                    _pinCtrl.text = '1234';
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Demo workspace created! Use PIN: 1234', style: GoogleFonts.inter()),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not create demo. Check server URL.', style: GoogleFonts.inter()),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                  setState(() => _loading = false);
                },
                child: Text(
                  'Create Demo Workspace',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
