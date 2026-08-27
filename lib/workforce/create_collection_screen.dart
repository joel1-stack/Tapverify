import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_service.dart';
import 'collection_detail_screen.dart';

enum PaymentMethod {
  mpesaStk('M-Pesa STK Push', Icons.phone_android_rounded, 'mpesa_stk', 'Send STK Push'),
  sasaPay('SasaPay Link', Icons.link_rounded, 'sasapay', 'Generate Link & Send'),
  mpesaTill('M-Pesa Till', Icons.store_rounded, 'mpesa_till', 'Show Till Number'),
  mpesaPaybill('M-Pesa Paybill', Icons.receipt_long_rounded, 'mpesa_paybill', 'Show Paybill'),
  card('Card Payment', Icons.credit_card_rounded, 'card', 'Process Card Payment'),
  airtel('Airtel Money', Icons.phone_iphone_rounded, 'airtel', 'Send Airtel Request');

  final String label;
  final IconData icon;
  final String railId;
  final String buttonText;

  const PaymentMethod(this.label, this.icon, this.railId, this.buttonText);
}

class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key});
  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  final _minInstallment = TextEditingController();
  final _numInstallments = TextEditingController();
  bool _loading = false;
  bool _allowPartial = false;
  PaymentMethod _selectedMethod = PaymentMethod.mpesaStk;
  DateTime? _dueDate;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _desc.dispose();
    _minInstallment.dispose();
    _numInstallments.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (title.isEmpty) {
      _snack('Enter customer name', AppColors.danger);
      return;
    }
    if (amount <= 0) {
      _snack('Enter a valid amount', AppColors.danger);
      return;
    }
    if (_allowPartial) {
      final minInst = double.tryParse(_minInstallment.text.trim()) ?? 0;
      final numInst = int.tryParse(_numInstallments.text.trim()) ?? 0;
      if (minInst <= 0) {
        _snack('Enter a valid minimum installment', AppColors.danger);
        return;
      }
      if (minInst >= amount) {
        _snack('Installment must be less than total amount', AppColors.danger);
        return;
      }
      if (numInst < 2) {
        _snack('Allow at least 2 installments', AppColors.danger);
        return;
      }
    }
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      final due = _dueDate ?? DateTime.now().add(const Duration(days: 7));
      final c = WorkforceService.createCollection(
        title: title,
        type: 'Order',
        amount: amount,
        due: due,
        railId: _selectedMethod.railId,
        railName: _selectedMethod.label,
        message: _desc.text.trim().isEmpty
            ? 'Order for $title — Ksh ${amount.round()}'
            : _desc.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CollectionDetailScreen(collection: c)),
        );
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${_selectedMethod.buttonText} sent for $title',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = _dueDate != null
        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
        : 'Select date';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        title: Text('Record customer payment',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Choose a payment method and enter the order details below.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.primary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer name
            _label('Customer name'),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('e.g. St. Mary\'s School', Icons.person_rounded),
            ),
            const SizedBox(height: 20),

            // Amount
            _label('Amount (KES)'),
            const SizedBox(height: 8),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: _inputDecoration('e.g. 50000', Icons.payments_rounded),
            ),
            const SizedBox(height: 20),

            // Description
            _label('Description'),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 160,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: _inputDecoration(
                  'e.g. 200 desks for classroom', Icons.description_rounded),
            ),
            const SizedBox(height: 24),

            // Payment method
            _label('Payment method'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((m) {
                final selected = _selectedMethod == m;
                return ChoiceChip(
                  label: Text(m.label, style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : AppColors.text,
                  )),
                  avatar: Icon(m.icon, size: 16,
                      color: selected ? Colors.white : AppColors.muted),
                  selected: selected,
                  selectedColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _selectedMethod = m),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Due date
            _label('Due date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDueDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _inputDecoration('Select date', Icons.calendar_today_rounded)
                    .copyWith(hintText: dateFormat),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormat,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _dueDate != null ? AppColors.text : AppColors.muted)),
                    Icon(Icons.arrow_drop_down, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Partial payment toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Allow partial payments?',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      Switch.adaptive(
                        value: _allowPartial,
                        onChanged: (v) => setState(() => _allowPartial = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  if (_allowPartial) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    _label('Minimum installment (KES)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _minInstallment,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration(
                          'e.g. 5000', Icons.monetization_on_rounded),
                    ),
                    const SizedBox(height: 16),
                    _label('Number of installments'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _numInstallments,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: _inputDecoration('e.g. 3', Icons.format_list_numbered_rounded),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_selectedMethod.icon, color: Colors.white),
                label: Text(_loading ? 'Processing...' : _selectedMethod.buttonText,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text));
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
          color: AppColors.muted.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.muted, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
