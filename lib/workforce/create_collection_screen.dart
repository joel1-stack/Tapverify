import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import 'collection_detail_screen.dart';

/// Foreman creates a new obligation. Rail selection is UI-only for now; real
/// payment keys are wired server-side later.
class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String _type = 'Welfare';
  String _railId = 'loop-prompt';
  DateTime _due = DateTime.now().add(const Duration(days: 7));

  static const _types = ['Welfare', 'Medical', 'Emergency', 'Trip'];

  static const _rails = [
    ('loop-prompt', 'LOOP M-Pesa Prompt', Icons.bolt_rounded,
        AppColors.loop, 'STK push to each worker phone'),
    ('sasapay', 'SasaPay Checkout link', Icons.link_rounded,
        AppColors.sasapay, 'MPESA/Equity link sent by SMS'),
    ('till', 'M-PESA Till 9415678', Icons.storefront_rounded,
        AppColors.success, 'Workers pay via till'),
    ('paybill', 'M-PESA Paybill 522033', Icons.receipt_rounded,
        AppColors.secondary, 'Paybill account KM01'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Add a title and a valid amount',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final rail = _rails.firstWhere((r) => r.$1 == _railId);
    final c = WorkforceService.createCollection(
      title: title,
      type: _type,
      amount: amount,
      due: _due,
      railId: rail.$1,
      railName: rail.$2,
      message: _message.text.trim().isEmpty
          ? '$_type collection for ${WorkforceService.orgName} — Ksh ${amount.round()}.'
          : _message.text.trim(),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: c)),
    );
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.loop, primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _due = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text(
          'New collection',
          style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Type', style: _sectionTitle()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _types)
                  ChoiceChip(
                    label: Text(t),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: _type == t ? Colors.white : AppColors.text,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.border),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Title', style: _sectionTitle()),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                hintText: 'e.g. September welfare levy',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Amount per worker (Ksh)', style: _sectionTitle()),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'e.g. 500',
                prefixIcon: Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Text('Deadline', style: _sectionTitle()),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text(
                      '${_due.day} ${_monthName(_due.month)} ${_due.year}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Payment rail', style: _sectionTitle()),
            const SizedBox(height: 8),
            for (final r in _rails) ...[
              _railTile(r.$1, r.$2, r.$3, r.$4, r.$5),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 20),
            Text('SMS message to workers', style: _sectionTitle()),
            const SizedBox(height: 8),
            TextField(
              controller: _message,
              maxLines: 3,
              maxLength: 160,
              decoration: const InputDecoration(
                hintText: 'Short message delivered via Africa\u2019s Talking SMS',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Raising this notifies all ${WorkforceService.workers.length} workers (simulated SMS — Africa\u2019s Talking keys are wired later).',
              style:
                  GoogleFonts.inter(fontSize: 11.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Raise & notify all workers'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _railTile(
      String id, String name, IconData icon, Color color, String desc) {
    final selected = _railId == id;
    return GestureDetector(
      onTap: () => setState(() => _railId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style:
                        GoogleFonts.inter(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? color : AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _sectionTitle() => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: AppColors.muted,
      letterSpacing: 0.4);

  static String _monthName(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}
