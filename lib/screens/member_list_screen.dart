import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/hive_service.dart';
import 'confirm_screen.dart';
import 'qr_scan_screen.dart';
import 'import_members_screen.dart';
import 'add_member_screen.dart';

/// Members tab — roster for the active workspace.
///
/// Fetches (and caches) members, searchable, each row shows the member QR,
/// phone, code and any outstanding balance. Tapping a member opens the
/// payment collection flow; header actions cover QR scan and CSV import.
/// The `embedded` flag hides the top-level chrome when reused inside
/// [CreateOrganizationScreen] onboarding.
class MemberListScreen extends StatefulWidget {
  final bool embedded;
  const MemberListScreen({super.key, this.embedded = false});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<Member> _members = [];
  List<Member> _filtered = [];
  bool _loading = true;
  bool _animate = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  Future<void> _loadMembers() async {
    final wsId = HiveService.activeWorkspaceId ?? '';
    final members = await ApiService.fetchMembers(wsId);
    setState(() {
      _members = members;
      _filtered = members;
      _loading = false;
    });
  }

  void _filter(String q) {
    setState(() {
      _filtered = _members
          .where((m) =>
              m.name.toLowerCase().contains(q.toLowerCase()) ||
              m.phone.contains(q) ||
              m.memberCode.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  /// Opens the payment-collection flow for one member. Suspended / banned /
  /// left members cannot contribute until the board reinstates them.
  void _openMember(Member m) {
    if (m.status == 'suspended' || m.status == 'banned') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            m.status == 'banned'
                ? '${m.name} is banned from this group.'
                : '${m.name} is suspended. Reinstate before collecting.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ConfirmScreen(member: m),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );
  }

  /// Member lifecycle controls: suspend, reinstate, mark as left, ban.
  void _lifecycleActions(Member m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text)),
                        Text(
                          '${m.memberCode} · ${m.status.toUpperCase()}',
                          style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.muted,
                              letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (m.status == 'active' || m.status == 'invited')
                _lifecycleTile(
                  icon: Icons.pause_circle_rounded,
                  color: AppColors.warning,
                  title: 'Suspend membership',
                  subtitle: 'Freezes contributions. Member can request reinstatement.',
                  onTap: () => _setStatus(m, 'suspended'),
                ),
              if (m.status == 'suspended')
                _lifecycleTile(
                  icon: Icons.restart_alt_rounded,
                  color: AppColors.primary,
                  title: 'Reinstate membership',
                  subtitle: 'Restores the member to active with a notification.',
                  onTap: () => _setStatus(m, 'active'),
                ),
              _lifecycleTile(
                icon: Icons.exit_to_app_rounded,
                color: AppColors.muted,
                title: 'Mark as left',
                subtitle: 'Member exited the group voluntarily.',
                onTap: () => _setStatus(m, 'left'),
              ),
              _lifecycleTile(
                icon: Icons.block_rounded,
                color: AppColors.danger,
                title: 'Ban from group',
                subtitle: 'Permanent removal. This cannot be undone without manual review.',
                onTap: () => _setStatus(m, 'banned'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lifecycleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.text)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
      onTap: onTap == null
          ? null
          : () {
              Navigator.pop(context);
              onTap();
            },
    );
  }

  Future<void> _setStatus(Member m, String status) async {
    await HiveService.addMember(m.copyWith(status: status));
    if (mounted) {
      _loadMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(status == 'active' || status == 'invited'
                  ? Icons.check_circle
                  : Icons.info_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${m.name} is now ${status.toUpperCase()} — SMS notification queued',
                  style: GoogleFonts.inter(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: status == 'banned'
              ? const Color(0xFFDC2626)
              : AppColors.deep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _memberStatusChip(String status) {
    final (label, color) = switch (status) {
      'suspended' => ('Suspended', AppColors.danger),
      'invited' => ('Invited — awaiting first payment', AppColors.gold),
      'left' => ('Left', AppColors.muted),
      'banned' => ('Banned', AppColors.danger),
      _ => ('Active', AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'invited'
                ? Icons.mark_email_unread_rounded
                : Icons.circle,
            size: 9,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }

  void _showQr(Member m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m.name,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text),
            ),
            const SizedBox(height: 4),
            Text(
              '${m.memberCode} · ${m.phone}',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: QrImageView(
                data: m.memberCode,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.deep,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.deep,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Show this QR to the treasurer to collect your payment',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // Quick action toolbar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR',
                  color: AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QrScanScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.upload_file_rounded,
                  label: 'Import CSV',
                  color: AppColors.accent,
                  onTap: () async {
                    final imported = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ImportMembersScreen()),
                    );
                    if (imported != null && imported > 0) {
                      _loadMembers();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Add manually',
                  color: const Color(0xFF2563EB),
                  onTap: () async {
                    final added = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddMemberScreen()),
                    );
                    if (added != null && added > 0) {
                      _loadMembers();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            style: GoogleFonts.inter(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search by name, phone, or code...',
              hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
              prefixIcon:
                  Icon(Icons.search_rounded, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.accent, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),

        // Member List
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg?auto=compress&cs=tinysrgb&w=800',
                              width: 160,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.search_off_rounded,
                                      size: 48, color: Color(0xFFCBD5E1)),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No members found',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final m = _filtered[i];
                        return AnimatedOpacity(
                          opacity: _animate ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 300 + (i * 50)),
                          child: AnimatedSlide(
                            offset:
                                _animate ? Offset.zero : const Offset(0, 0.1),
                            duration: Duration(milliseconds: 300 + (i * 50)),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () => _openMember(m),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: m.isActive
                                                ? AppColors.primary
                                                : AppColors.muted,
                                            child: Text(
                                              m.name.isNotEmpty
                                                  ? m.name[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  m.name,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                        0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  m.phone,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: const Color(
                                                        0xFF94A3B8),
                                                  ),
                                                ),
                                                if (!m.isActive ||
                                                    m.status == 'invited') ...[
                                                  const SizedBox(height: 4),
                                                  _memberStatusChip(m.status),
                                                ],
                                              ],
                                            ),
                                          ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Ksh ${m.balanceDue.toStringAsFixed(0)}',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: m.isActive
                                                    ? const Color(
                                                        0xFFDC2626)
                                                    : const Color(
                                                        0xFF94A3B8),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _showQr(m),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                        Icons.qr_code_2_rounded,
                                                        size: 16,
                                                        color: AppColors.primary),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _lifecycleActions(m),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.accent
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                        Icons.more_vert_rounded,
                                                        size: 16,
                                                        color:
                                                            AppColors.accent),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF1F5F9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    m.memberCode,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                          0xFF64748B),
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: const Color(0xFFF8FAFC),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Select Member',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: content,
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
