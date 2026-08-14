import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/hive_service.dart';

/// Manual single-member entry — the "no CSV today" path.
///
/// The treasurer types a member's name + phone (optionally their member code
/// and opening balance); TapVerify generates a member code when none is given
/// and persists the member via [HiveService.addMember]. Pops with `1` on save
/// so the member list can refresh.
class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  bool _saving = false;
  bool _withBalance = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      _toast('Name and phone are required', AppColors.danger);
      return;
    }
    setState(() => _saving = true);
    final wsId = HiveService.activeWorkspaceId ?? 'ws-default';
    final existing = HiveService.getMembersForWorkspace(wsId);
    final orgCode =
        HiveService.getActiveWorkspace()?['org_code']?.toString() ?? 'TV';
    var code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      var n = existing.length + 1;
      code = '$orgCode$n';
      while (existing.any((m) => m.memberCode == code)) {
        n++;
        code = '$orgCode$n';
      }
    } else if (existing.any((m) => m.memberCode == code)) {
      _toast('Member code $code already exists', AppColors.danger);
      setState(() => _saving = false);
      return;
    }
    final balance =
        _withBalance ? (double.tryParse(_balanceCtrl.text.trim()) ?? 0.0) : 0.0;
    await HiveService.addMember(Member(
      id: '$wsId-member-$code',
      name: name,
      phone: phone,
      memberCode: code,
      balanceDue: balance,
      workspaceId: wsId,
    ));
    if (!mounted) return;
    Navigator.pop(context, 1);
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wsName =
        HiveService.getActiveWorkspace()?['name']?.toString() ?? 'your group';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Add Member',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C2D12), AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add to $wsName',
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          'Manual entry — no CSV needed. A member code is auto-generated when left blank.',
                          style: GoogleFonts.inter(
                              fontSize: 11.5, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Full name',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Grace Wanjiku',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Phone number',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: '2547XXXXXXXX',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Member code (optional)',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Auto-generated if blank (e.g. TV13)',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text('Opening balance',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ),
                Switch(
                  value: _withBalance,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _withBalance = v),
                ),
              ],
            ),
            if (_withBalance) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 15),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.person_add_rounded),
                label: Text('ADD MEMBER',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Members are invited by SMS and appear in every group they belong to.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 11, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
