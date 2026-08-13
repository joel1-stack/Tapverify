import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';
import 'confirm_screen.dart';

/// QR scanner that maps a scanned member code straight into the payment flow.
///
/// Uses [MobileScanner] to read a member's QR, looks up the member in the
/// workspace cache and pushes [ConfirmScreen] for them. Guards against double
/// scans while a member is being processed.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  MobileScannerController? _controller;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Member? _findByValue(String value) {
    final code = value.trim().toUpperCase();
    final members =
        HiveService.getMembersForWorkspace(HiveService.activeWorkspaceId ?? '');
    for (final m in members) {
      if (m.memberCode.toUpperCase() == code) return m;
    }
    // Also try matching by phone
    for (final m in members) {
      if (m.phone.replaceAll(RegExp(r'[\s\-]'), '') == value.trim()) return m;
    }
    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      final member = _findByValue(value);
      if (member != null) {
        _processing = true;
        if (mounted) {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ConfirmScreen(member: member)),
          ).then((_) {
            _processing = false;
          });
        }
        return;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unknown code: $value', style: GoogleFonts.inter()),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan Member QR',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                ),
                // Scan overlay
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.qr_code_2,
                        color: Colors.white54, size: 80),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'Hold QR card inside the box',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Member QR codes look like TV001',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Demo fallback
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                Text(
                  'No QR? Tap a member code to demo-scan',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCodePicker(),
                    icon:
                        const Icon(Icons.numbers_rounded, color: Colors.white),
                    label: Text(
                      'Enter member code instead',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCodePicker() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter member code',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'TV001',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final member = _findByValue(controller.text.trim());
              if (member != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ConfirmScreen(member: member)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Member not found', style: GoogleFonts.inter()),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text('Continue',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
