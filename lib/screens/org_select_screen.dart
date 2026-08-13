import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../services/hive_service.dart';
import '../services/contribution_service.dart';
import 'home_shell.dart';

/// Org picker shown when a treasurer can access several workspaces.
///
/// Lists accessible orgs, lets the treasurer pick one (sets the active
/// workspace + marks selection done) and smoothly replaces itself with
/// [HomeShell]. Also offers creating a brand-new organization.
class OrgSelectScreen extends StatefulWidget {
  const OrgSelectScreen({super.key});

  @override
  State<OrgSelectScreen> createState() => _OrgSelectScreenState();
}

class _OrgSelectScreenState extends State<OrgSelectScreen> {
  bool _loading = false;

  List<Map> get _orgs => HiveService.getAccessibleWorkspaces();

  Future<void> _pick(Map org) async {
    if (_loading) return;
    setState(() => _loading = true);
    await HiveService.setActiveWorkspace(org['id'].toString());
    await HiveService.markOrgSelectionDone();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (route) => false,
    );
  }

  Future<void> _createNew() async {
    if (_loading) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _NewOrgSheet(),
      ),
    );
    if (created == true && mounted) {
      // Newly created org was granted access — switch into it directly
      final active = HiveService.getActiveWorkspace();
      if (active != null) {
        await HiveService.markOrgSelectionDone();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeShell(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgs = _orgs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF064E3B),
                    Color(0xFF059669),
                    Color(0xFF10B981)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(AppAssets.logoFull,
                            fit: BoxFit.contain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Opening which organisation?',
                      style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.15)),
                  const SizedBox(height: 6),
                  Text('Tap the one you want to manage today.',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(height: 14),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text('You can only see this org\u2019s members & money',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('YOUR ORGANISATIONS  (${orgs.length})',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                          letterSpacing: 0.6)),
                  const SizedBox(height: 10),
                  ...orgs.map((org) {
                    final type = org['type']?.toString() ?? 'Chama';
                    final rules = OrgRules.rulesFor(type);
                    final name = org['name']?.toString() ?? 'Organisation';
                    final sub = rules['description'];
                    final image = OrgRules.imageFor(type);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _pick(org),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    image,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 64,
                                      height: 64,
                                      color:
                                          AppColors.primary.withOpacity(0.12),
                                      child: const Icon(Icons.groups_rounded,
                                          color: AppColors.primary, size: 28),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(name,
                                                style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.text)),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(type.toUpperCase(),
                                                style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.primary)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(sub,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _createNew,
                      icon: const Icon(Icons.add_business_rounded),
                      label: Text('Create a new organisation',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewOrgSheet extends StatefulWidget {
  const _NewOrgSheet();

  @override
  State<_NewOrgSheet> createState() => _NewOrgSheetState();
}

class _NewOrgSheetState extends State<_NewOrgSheet> {
  final _nameCtrl = TextEditingController();
  final _contributionCtrl = TextEditingController(text: '5000');
  String _type = 'Chama';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contributionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty ||
        double.tryParse(_contributionCtrl.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a name and a valid contribution',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final rules = OrgRules.rulesFor(_type);
    final workspace = <String, dynamic>{
      'id': 'ws-${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'contribution': int.tryParse(_contributionCtrl.text) ?? 5000,
      'rails': {'loop': true, 'till': true, 'paybill': false, 'bank': false},
      'till_number': '9415678',
      'paybill_number': '',
      'account_number': '',
      'created_at': DateTime.now().toIso8601String(),
      'image': OrgRules.imageFor(_type),
      'rules': rules,
    };
    await HiveService.addWorkspace(workspace);
    await HiveService.grantWorkspaceAccess(workspace['id']);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('New Organisation',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Organisation type',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrgRules.orgTypes.map((t) {
              final active = _type == t;
              return ChoiceChip(
                label: Text(t,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 12.5)),
                selected: active,
                selectedColor: AppColors.primary,
                labelStyle:
                    TextStyle(color: active ? Colors.white : AppColors.text),
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: active ? AppColors.primary : AppColors.border),
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(OrgRules.rulesFor(_type)['description'],
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          Text('Organisation name',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Milimani Chama, Sunrise Academy',
              hintStyle:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Default contribution (Ksh)',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const SizedBox(height: 8),
          TextField(
            controller: _contributionCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '5000',
              hintStyle:
                  GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submit,
              child: Text('CREATE & SWITCH',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}
