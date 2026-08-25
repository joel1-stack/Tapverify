import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';
import '../workforce/workforce_service.dart';
import 'app_background.dart';
import 'notification_center.dart';

/// How the collector actually receives money. Members pay into these account
/// details — the collector never touches cash. In production SasaPay handles
/// checkout links; USSD, SMS and Avalanche badges ride on top.
class CollectionSettingsScreen extends StatefulWidget {
  const CollectionSettingsScreen({super.key});

  @override
  State<CollectionSettingsScreen> createState() =>
      _CollectionSettingsScreenState();
}

class _CollectionSettingsScreenState extends State<CollectionSettingsScreen> {
  late final TextEditingController _till;
  late final TextEditingController _paybill;
  late final TextEditingController _paybillAccount;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccount;
  late final TextEditingController _sasapayMerchant;
  late final TextEditingController _sasapayAccount;

  @override
  void initState() {
    super.initState();
    final r = WorkforceService.railsConfig;
    _till = TextEditingController(text: r.till);
    _paybill = TextEditingController(text: r.paybill);
    _paybillAccount = TextEditingController(text: r.paybillAccount);
    _bankName = TextEditingController(text: r.bankName);
    _bankAccount = TextEditingController(text: r.bankAccount);
    _sasapayMerchant = TextEditingController(text: r.sasapayMerchant);
    _sasapayAccount = TextEditingController(text: r.sasapayAccount);
  }

  @override
  void dispose() {
    _till.dispose();
    _paybill.dispose();
    _paybillAccount.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    _sasapayMerchant.dispose();
    _sasapayAccount.dispose();
    super.dispose();
  }

  void _save() {
    WorkforceService.saveRailsConfig(RailsConfig(
      till: _till.text.trim(),
      paybill: _paybill.text.trim(),
      paybillAccount: _paybillAccount.text.trim(),
      bankName: _bankName.text.trim(),
      bankAccount: _bankAccount.text.trim(),
      sasapayMerchant: _sasapayMerchant.text.trim(),
      sasapayAccount: _sasapayAccount.text.trim(),
    ));
    NotificationCenter.instance.notify(
      title: 'Collection details saved',
      body:
          'Members will pay into these Till / Paybill / bank details from now on.',
      icon: Icons.settings_rounded,
      color: AppColors.primary,
    );
    Navigator.pop(context);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = WorkforceService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'Collection details',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: AppBackground(
        image: AppImages.marketStall,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            u != null
                                ? '${u.name} · ${u.position}\nCollecting as ${u.orgName}. You never touch the money — members pay into the details below.'
                                : 'You never touch the money — members pay into the details below.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.text,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'MOBILE MONEY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    controller: _till,
                    label: 'M-Pesa Till number',
                    icon: Icons.storefront_rounded,
                    hint: 'e.g. 9415678',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  _field(
                    controller: _paybill,
                    label: 'M-Pesa Paybill number',
                    icon: Icons.receipt_rounded,
                    hint: 'e.g. 522033',
                    keyboard: TextInputType.number,
                    formatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  _field(
                    controller: _paybillAccount,
                    label: 'Paybill account no.',
                    icon: Icons.tag_rounded,
                    hint: 'e.g. TV01',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BANK',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    controller: _bankName,
                    label: 'Bank name',
                    icon: Icons.account_balance_rounded,
                    hint: 'e.g. KCB',
                  ),
                  _field(
                    controller: _bankAccount,
                    label: 'Account number',
                    icon: Icons.numbers_rounded,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SASAPAY (WALLET / CARD)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _field(
                    controller: _sasapayMerchant,
                    label: 'SasaPay merchant code',
                    icon: Icons.business_rounded,
                  ),
                  _field(
                    controller: _sasapayAccount,
                    label: 'SasaPay account number',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.secondary.withOpacity(0.25)),
                    ),
                    child: Text(
                      'In production these rails are wired to SasaPay — checkout links, USSD, SMS reminders and Avalanche badge attestations are included.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.text,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent),
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save collection details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}