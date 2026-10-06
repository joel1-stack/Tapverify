import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart' show kAccent, kAccentDark, kPrimary, kSuccess;
import '../utils/format.dart';

/// An interactive, offline demo of the TapVerify app, framed like a phone.
///
/// This is the web demo: visitors can tap through the real product flow
/// (collections, live list, marking a payment, sending an invite) without an
/// account. Everything runs on mock data, so nothing here touches the API.
class PhoneDemo extends StatefulWidget {
  const PhoneDemo({super.key, this.width = 300, this.height = 604});

  /// Screen size inside the bezel.
  final double width;
  final double height;

  @override
  State<PhoneDemo> createState() => _PhoneDemoState();
}

class _DemoMember {
  _DemoMember(this.name, this.phone, this.paid);

  final String name;
  final String phone;
  bool paid;
}

class _PhoneDemoState extends State<PhoneDemo> {
  // A welfare chama half-way to its target: 8 members, KES 500 each.
  static const int _amount = 500;
  static const String _title = 'September Welfare';

  late List<_DemoMember> _members;
  int _screen = 0; // 0 = collections, 1 = live list
  int? _sheetIndex;
  String? _toast;
  bool _toastIsSuccess = true;
  Timer? _toastTimer;
  Timer? _detectTimer;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _detectTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _toastTimer?.cancel();
    _detectTimer?.cancel();
    _members = [
      _DemoMember('Wanjiku Kamau', '0712 345 678', true),
      _DemoMember('Brian Otieno', '0722 118 450', false),
      _DemoMember('Jane Wanjiku', '0733 907 214', false),
      _DemoMember('Peter Mwangi', '0701 552 118', true),
      _DemoMember('Amina Hassan', '0748 330 917', false),
      _DemoMember('Kevin Ochieng', '0710 246 803', true),
      _DemoMember('Grace Njeri', '0726 774 019', true),
      _DemoMember('John Kiplagat', '0768 415 662', true),
    ];
    _screen = 0;
    _sheetIndex = null;
    _toast = null;
    _detected = false;
  }

  int get _paid => _members.where((m) => m.paid).length;
  int get _collected => _paid * _amount;
  int get _outstanding => (_members.length - _paid) * _amount;
  double get _progress => _members.isEmpty ? 0 : _paid / _members.length;

  void _showToast(String message, {bool success = true}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
      _toastIsSuccess = success;
    });
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _openList() {
    setState(() => _screen = 1);
    // The product's headline feature, dramatised: a payment lands on its own.
    if (!_detected) {
      _detectTimer?.cancel();
      _detectTimer = Timer(const Duration(milliseconds: 2800), () {
        if (!mounted || _screen != 1 || _detected) return;
        setState(() {
          _members[2].paid = true; // Jane Wanjiku
          _detected = true;
        });
        _showToast('Payment detected automatically - KES 500');
      });
    }
  }

  void _markPaid(int index) {
    setState(() => _members[index].paid = true);
    _sheetIndex = null;
    _showToast('${_members[index].name.split(' ').first} marked as Paid (Cash)');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _frame(),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_outlined, size: 16, color: kPrimary),
            const SizedBox(width: 6),
            Text(
              'Interactive demo - tap around',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 14),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(_reset),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _frame() {
    return Container(
      width: widget.width + 16,
      height: widget.height + 16,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 50,
            offset: const Offset(0, 26),
          ),
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.25),
            blurRadius: 60,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              Column(
                children: [
                  _statusBar(),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.06, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _screen == 0 ? _homeScreen() : _listScreen(),
                    ),
                  ),
                ],
              ),
              if (_sheetIndex != null)
                Positioned.fill(
                  child: _demoSheet(_sheetIndex!),
                ),
              if (_toast != null)
                Positioned(
                  top: 44,
                  left: 12,
                  right: 12,
                  child: _toastBanner(_toast!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBar() {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            '9:41',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
          ),
          const Spacer(),
          Icon(Icons.signal_cellular_alt, size: 13, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Icon(Icons.wifi, size: 13, color: Colors.grey[700]),
          const SizedBox(width: 5),
          Icon(Icons.battery_full, size: 13, color: Colors.grey[700]),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- home ---

  Widget _homeScreen() {
    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'My Collections',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
              ),
              _roundIcon(Icons.logout, tooltip: 'Logout (demo)', onTap: () => _showToast('This is a demo - stay as long as you like', success: false)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            children: [
              _collectionCard(),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'Demo data - open the collection',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: FilledButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Collection', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _showToast('The create form lives in the full app', success: false),
          ),
        ),
      ],
    );
  }

  Widget _collectionCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openList,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kPrimary.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimary.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _miniStat('Paid', '$_paid/${_members.length}', kPrimary),
                  const SizedBox(width: 10),
                  _miniStat('Collected', Format.kes(_collected), kSuccess),
                  const SizedBox(width: 10),
                  _miniStat('Outstanding', Format.kes(_outstanding), kAccent),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation(kPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- list ---

  Widget _listScreen() {
    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 14, 8, 6),
          child: Row(
            children: [
              _roundIcon(Icons.arrow_back, tooltip: 'Back', onTap: () => setState(() => _screen = 0)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  _title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
              ),
              _roundIcon(Icons.share_outlined, tooltip: 'Share', onTap: () => _showToast('Share link copied (demo)')),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            children: [
              _statsCard(),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Members',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                  Text(
                    '$_paid paid - ${_members.length - _paid} pending',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._members.asMap().entries.map((e) => _memberTile(e.key, e.value)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: FilledButton.icon(
            icon: const Icon(Icons.notifications_active_outlined, size: 17),
            label: const Text('Send Reminder to Unpaid', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _members.length == _paid
                ? () => _showToast('Everyone has paid. Nice work!')
                : () => _showToast('${_members.length - _paid} reminders sent by SMS (demo)'),
          ),
        ),
      ],
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, Color(0xFF007A4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${Format.kes(_amount)} per person - Till 8877441',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          const Text(
            'Payments appear here automatically',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _headerStat('Paid', '$_paid/${_members.length}')),
              Container(width: 1, height: 34, color: Colors.white24),
              Expanded(child: _headerStat('Collected', Format.kes(_collected))),
              Container(width: 1, height: 34, color: Colors.white24),
              Expanded(child: _headerStat('Outstanding', Format.kes(_outstanding))),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _progress >= 1
                ? 'All paid, well done!'
                : '${(_progress * 100).round()}% collected',
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _memberTile(int index, _DemoMember m) {
    final color = m.paid ? kSuccess : const Color(0xFF00A86B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _sheetIndex = index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Text(
                    Format.initial(m.name),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      ),
                      Text(
                        Format.phone(m.phone),
                        style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: (m.paid ? kSuccess : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    m.paid ? 'Paid' : 'Pending',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: m.paid ? kSuccess : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, {String? tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- sheet ---

  Widget _demoSheet(int index) {
    final m = _members[index];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _sheetIndex = null),
              child: Container(color: Colors.black.withValues(alpha: 0.45 * t)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.6 + 0.4 * t,
                child: Transform.translate(
                  offset: Offset(0, 60 * (1 - t)),
                  child: Opacity(
                    opacity: t.clamp(0, 1),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: (m.paid ? kSuccess : kPrimary).withValues(alpha: 0.14),
                            child: Text(
                              Format.initial(m.name),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: m.paid ? kSuccess : kPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            m.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Format.phone(m.phone),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: (m.paid ? kSuccess : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    m.paid ? Icons.check_circle : Icons.schedule,
                                    size: 14,
                                    color: m.paid ? kSuccess : const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    m.paid ? 'Paid KES $_amount' : 'Not paid yet',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: m.paid ? kSuccess : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (!m.paid) ...[
                            FilledButton.icon(
                              icon: const Icon(Icons.payments_outlined, size: 16),
                              label: const Text('Mark as Paid (Cash)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: kAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
                              onPressed: () => _markPaid(index),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.sms_outlined, size: 16),
                              label: const Text('Send reminder SMS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kAccentDark,
                                side: BorderSide(color: kAccent.withValues(alpha: 0.7), width: 1.4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                              ),
                              onPressed: () => _showToast('Reminder sent to ${m.name.split(' ').first} (demo)'),
                            ),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kSuccess.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: kSuccess.withValues(alpha: 0.25)),
                              ),
                              child: const Text(
                                'Received. The live list updates the moment a payment lands.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------- toast ---

  Widget _toastBanner(String message) {
    final color = _toastIsSuccess ? kSuccess : const Color(0xFF00A86B);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => Transform.translate(
        offset: Offset(0, -30 * (1 - t)),
        child: Opacity(
          opacity: t.clamp(0, 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_toastIsSuccess ? Icons.check_circle : Icons.info_outline,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
