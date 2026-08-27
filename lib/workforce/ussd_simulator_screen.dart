import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

/// USSD Simulator — matches real shortcode 14434 (*384*123#) flow.
/// Stateful session with PIN auth, incremental numbered responses.
class UssdSimulatorScreen extends StatefulWidget {
  const UssdSimulatorScreen({super.key});
  @override
  State<UssdSimulatorScreen> createState() => _UssdSimulatorScreenState();
}

enum _SessionState {
  start,
  loginPin,
  mainMenu,
  clockInConfirm,
  clockOutConfirm,
  balance,
  incidentCategory,
  incidentDesc,
  reminderConfirm,
}

class _UssdSimulatorScreenState extends State<UssdSimulatorScreen> {
  final List<_UssdEntry> _log = [];
  bool _loading = false;
  _SessionState _state = _SessionState.start;
  int _step = 0;
  String _sessionPhone = '254715641339';
  int _retryCount = 0;
  final List<String> _processingSteps = [];

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    _log.clear();
    _state = _SessionState.start;
    _step = 0;
    _retryCount = 0;
    _log.add(_UssdEntry(
      type: _UssdType.network,
      text: 'USSD code: *384*123#',
      step: 0,
    ));
    _log.add(_UssdEntry(
      type: _UssdType.system,
      text: 'Connecting to shortcode 14434...',
      step: 1,
    ));
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _loading = false;
        _log.add(_UssdEntry(
          type: _UssdType.menu,
          text: 'CON Welcome to TapVerify\nEnter your 4-digit PIN to login:',
          step: 2,
        ));
        _state = _SessionState.loginPin;
      });
    });
    setState(() => _loading = true);
  }

  void _handleInput(String input) async {
    setState(() {
      _loading = true;
      _step++;
      _log.add(_UssdEntry(
        type: _UssdType.user,
        text: input,
        step: _step,
      ));
    });

    // Simulate incremental network response
    await _showProcessing('Verifying request', 3);
    await _showProcessing('Processing', 5);

    switch (_state) {
      case _SessionState.start:
        break;
      case _SessionState.loginPin:
        _handleLoginPin(input);
        break;
      case _SessionState.mainMenu:
        _handleMainMenu(input);
        break;
      case _SessionState.clockInConfirm:
        _handleClockIn(input);
        break;
      case _SessionState.clockOutConfirm:
        _handleClockOut(input);
        break;
      case _SessionState.balance:
        _handleBalance(input);
        break;
      case _SessionState.incidentCategory:
        _handleIncidentCategory(input);
        break;
      case _SessionState.incidentDesc:
        _handleIncidentDesc(input);
        break;
      case _SessionState.reminderConfirm:
        _handleReminder(input);
        break;
    }
  }

  Future<void> _showProcessing(String label, int maxCount) async {
    for (int i = 1; i <= maxCount; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          _processingSteps.clear();
          _processingSteps.add('$label... ($i/$maxCount)');
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _processingSteps.clear());
  }

  void _handleLoginPin(String input) {
    if (input == '1234') {
      _retryCount = 0;
      _state = _SessionState.mainMenu;
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON [MAIN MENU]\n'
            '1. Clock In\n'
            '2. Clock Out\n'
            '3. View Balance\n'
            '4. Report Safety Incident\n'
            '5. View Announcements',
        step: _step,
      ));
    } else {
      _retryCount++;
      if (_retryCount >= 3) {
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'END Too many incorrect PIN attempts. Session closed.',
          step: _step,
        ));
        _state = _SessionState.start;
        _retryCount = 0;
      } else {
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Incorrect PIN. Enter your 4-digit PIN to login:',
          step: _step,
        ));
      }
    }
    setState(() => _loading = false);
  }

  void _handleMainMenu(String input) {
    switch (input) {
      case '1': // Clock In
        _state = _SessionState.clockInConfirm;
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Confirm Clock In?\n'
              '1. Yes — Clock In Now\n'
              '2. No — Go Back',
          step: _step,
        ));
        break;
      case '2': // Clock Out
        _state = _SessionState.clockOutConfirm;
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Confirm Clock Out?\n'
              '1. Yes — Clock Out Now\n'
              '2. No — Go Back',
          step: _step,
        ));
        break;
      case '3': // Balance
        _state = _SessionState.balance;
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Select balance type:\n'
              '1. Payment Balance\n'
              '2. Leave Balance\n'
              '3. Streak & Points\n'
              '0. Go Back',
          step: _step,
        ));
        break;
      case '4': // Incident
        _state = _SessionState.incidentCategory;
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Select Category:\n'
              '1. Safety Incident\n'
              '2. Equipment Issue\n'
              '3. Payment Dispute\n'
              '0. Go Back',
          step: _step,
        ));
        break;
      case '5': // Announcements
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'END [ANNOUNCEMENT]\n'
              'TapVerify v2.0: Revenue proof for your business.\n'
              'New: USSD balance check now available.\n'
              'Contact admin for support.',
          step: _step,
        ));
        _state = _SessionState.mainMenu;
        break;
      default:
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Invalid choice. Select option:\n'
              '1. Clock In\n'
              '2. Clock Out\n'
              '3. View Balance\n'
              '4. Report Safety Incident\n'
              '5. View Announcements',
          step: _step,
        ));
    }
    setState(() => _loading = false);
  }

  void _handleClockIn(String input) {
    if (input == '2') {
      _state = _SessionState.mainMenu;
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON [MAIN MENU]\n'
            '1. Clock In\n'
            '2. Clock Out\n'
            '3. View Balance\n'
            '4. Report Safety Incident\n'
            '5. View Announcements',
        step: _step,
      ));
    } else if (input == '1') {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'END Clocked in [ON TIME] at $timeStr.\n'
            'Date: $dateStr\n'
            'Channel: USSD (shortcode 14434)\n'
            'Employee: Peter Kaunda',
        step: _step,
      ));
      _state = _SessionState.mainMenu;
    } else {
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON Invalid choice. Confirm Clock In?\n'
            '1. Yes — Clock In Now\n'
            '2. No — Go Back',
        step: _step,
      ));
    }
    setState(() => _loading = false);
  }

  void _handleClockOut(String input) {
    if (input == '2') {
      _state = _SessionState.mainMenu;
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON [MAIN MENU]\n'
            '1. Clock In\n'
            '2. Clock Out\n'
            '3. View Balance\n'
            '4. Report Safety Incident\n'
            '5. View Announcements',
        step: _step,
      ));
    } else if (input == '1') {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'END Clocked out [ON TIME] at $timeStr.\n'
            'Hours worked: 8h 23m\n'
            'Channel: USSD (shortcode 14434)',
        step: _step,
      ));
      _state = _SessionState.mainMenu;
    } else {
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON Invalid choice. Confirm Clock Out?\n'
            '1. Yes — Clock Out Now\n'
            '2. No — Go Back',
        step: _step,
      ));
    }
    setState(() => _loading = false);
  }

  void _handleBalance(String input) {
    switch (input) {
      case '0':
        _state = _SessionState.mainMenu;
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON [MAIN MENU]\n'
              '1. Clock In\n'
              '2. Clock Out\n'
              '3. View Balance\n'
              '4. Report Safety Incident\n'
              '5. View Announcements',
          step: _step,
        ));
        break;
      case '1':
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'END [PAYMENT BALANCE]\n'
              'Total earned: Ksh 2,400,000\n'
              'Total paid: Ksh 2,400,000\n'
              'Balance: Ksh 0\n'
              'Consistency: 94%\n'
              'Channel: USSD (shortcode 14434)',
          step: _step,
        ));
        _state = _SessionState.mainMenu;
        break;
      case '2':
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'END [LEAVE BALANCE]\n'
              'Annual leave: 21 days\n'
              'Used: 8 days\n'
              'Remaining: 13 days\n'
              'Sick leave: 7 days remaining',
          step: _step,
        ));
        _state = _SessionState.mainMenu;
        break;
      case '3':
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'END [STREAK & POINTS]\n'
              'Current streak: 6 months\n'
              'Best streak: 6 months\n'
              'Points: 1,240 pts\n'
              'Rank: Gold Payer\n'
              'Next reward: Ksh 500 airtime at 2,000 pts',
          step: _step,
        ));
        _state = _SessionState.mainMenu;
        break;
      default:
        _log.add(_UssdEntry(
          type: _UssdType.system,
          text: 'CON Invalid choice. Select balance type:\n'
              '1. Payment Balance\n'
              '2. Leave Balance\n'
              '3. Streak & Points\n'
              '0. Go Back',
          step: _step,
        ));
    }
    setState(() => _loading = false);
  }

  void _handleIncidentCategory(String input) {
    if (input == '0') {
      _state = _SessionState.mainMenu;
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON [MAIN MENU]\n'
            '1. Clock In\n'
            '2. Clock Out\n'
            '3. View Balance\n'
            '4. Report Safety Incident\n'
            '5. View Announcements',
        step: _step,
      ));
    } else if (['1', '2', '3'].contains(input)) {
      _state = _SessionState.incidentDesc;
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON Enter brief description:\n(Enter 0 to go back)',
        step: _step,
      ));
    } else {
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON Invalid choice. Select Category:\n'
            '1. Safety Incident\n'
            '2. Equipment Issue\n'
            '3. Payment Dispute\n'
            '0. Go Back',
        step: _step,
      ));
    }
    setState(() => _loading = false);
  }

  void _handleIncidentDesc(String input) {
    if (input == '0') {
      _state = _SessionState.incidentCategory;
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON Select Category:\n'
            '1. Safety Incident\n'
            '2. Equipment Issue\n'
            '3. Payment Dispute\n'
            '0. Go Back',
        step: _step,
      ));
    } else if (input.isNotEmpty) {
      final cat = ['safety', 'equipment', 'payment dispute'][0];
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'END Incident reported [OPEN].\n'
            'Category: $cat\n'
            'Description: $input\n'
            'Reported via: USSD (shortcode 14434)\n'
            'Thank you.',
        step: _step,
      ));
      _state = _SessionState.mainMenu;
    } else {
      _log.add(_UssdEntry(
        type: _UssdType.system,
        text: 'CON Description cannot be empty.\nEnter brief description:\n(Enter 0 to go back)',
        step: _step,
      ));
    }
    setState(() => _loading = false);
  }

  void _handleReminder(String input) {
    _log.add(_UssdEntry(
      type: _UssdType.system,
      text: 'END Reminder sent to 12 members\nwho have not paid.',
      step: _step,
    ));
    _state = _SessionState.mainMenu;
    setState(() => _loading = false);
  }

  void _onReset() {
    _startSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('USSD Simulator',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            Text('Shortcode 14434 · *384*123#',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _onReset,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            tooltip: 'Reset session',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Session header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F3460),
            child: Row(
              children: [
                const Icon(Icons.phone_android_rounded,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text('Phone: $_sessionPhone',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('LIVE',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('STEP $_step',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ),
              ],
            ),
          ),

          // ── USSD log ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _log.length + _processingSteps.length,
              itemBuilder: (context, i) {
                if (i >= _log.length) {
                  final pIdx = i - _log.length;
                  return _processingEntry(_processingSteps[pIdx]);
                }
                return _logEntry(_log[i]);
              },
            ),
          ),

          // ── Input buttons ──
          if (!_loading) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    switch (_state) {
      case _SessionState.loginPin:
        return _pinPad();
      case _SessionState.mainMenu:
        return _mainMenuPad();
      case _SessionState.clockInConfirm:
      case _SessionState.clockOutConfirm:
        return _confirmPad();
      case _SessionState.balance:
        return _balancePad();
      case _SessionState.incidentCategory:
        return _categoryPad();
      case _SessionState.incidentDesc:
        return _textPad('Enter description');
      default:
        return _pinPad();
    }
  }

  Widget _pinPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter PIN (demo: 1234)',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white54)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (int i = 1; i <= 3; i++)
                  _numBtn('$i'),
                const SizedBox(width: 8),
                _actionBtn('CLR', AppColors.danger, () {
                  setState(() {
                    if (_log.isNotEmpty && _log.last.type == _UssdType.user) {
                      _log.removeLast();
                    }
                  });
                }),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 4; i <= 6; i++)
                  _numBtn('$i'),
                const SizedBox(width: 8),
                const SizedBox(width: 76),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 7; i <= 9; i++)
                  _numBtn('$i'),
                const SizedBox(width: 8),
                const SizedBox(width: 76),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 76 + 8),
                _numBtn('0'),
                const SizedBox(width: 8),
                _actionBtn('SEND', AppColors.primary, _submitInput),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainMenuPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 0; row < 3; row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    for (var col = 0; col < 2; col++)
                      Expanded(
                        child: (row * 2 + col) < 5
                            ? _menuBtn('${row * 2 + col + 1}',
                                _menuLabel(row * 2 + col))
                            : const SizedBox(),
                      ),
                    if (row < 2) const SizedBox(width: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _menuLabel(int idx) {
    const labels = [
      'Clock In', 'Clock Out', 'View Balance',
      'Report Incident', 'Announcements'
    ];
    return idx < labels.length ? labels[idx] : '';
  }

  Widget _confirmPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _actionBtn('1 — Yes', AppColors.success, () => _handleInput('1')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn('2 — No', AppColors.danger, () => _handleInput('2')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balancePad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _menuBtn('1', 'Payment')),
                const SizedBox(width: 8),
                Expanded(child: _menuBtn('2', 'Leave')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _menuBtn('3', 'Streak')),
                const SizedBox(width: 8),
                Expanded(child: _menuBtn('0', 'Back')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _menuBtn('1', 'Safety')),
                const SizedBox(width: 8),
                Expanded(child: _menuBtn('2', 'Equipment')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _menuBtn('3', 'Payment')),
                const SizedBox(width: 8),
                Expanded(child: _menuBtn('0', 'Back')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textPad(String hint) {
    final ctrl = TextEditingController();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _actionBtn('SEND', AppColors.primary, () {
              if (ctrl.text.isNotEmpty) {
                _handleInput(ctrl.text);
              }
            }),
          ],
        ),
      ),
    );
  }

  void _submitInput() {
    final lastUser = _log.lastWhere(
        (e) => e.type == _UssdType.user, orElse: () => _UssdEntry(type: _UssdType.user, text: '', step: 0));
    if (lastUser.text.isNotEmpty) {
      _handleInput(lastUser.text);
    }
  }

  Widget _numBtn(String n) {
    return SizedBox(
      width: 76, height: 48,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _log.add(_UssdEntry(type: _UssdType.user, text: n, step: _step + 1));
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F3460),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(n, style: GoogleFonts.inter(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }

  Widget _menuBtn(String n, String label) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () => _handleInput(n),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary.withOpacity(0.15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text('$n. $label', style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 76, height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }

  Widget _processingEntry(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(text,
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.white38, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _logEntry(_UssdEntry entry) {
    Color color;
    IconData icon;
    String label;
    Color bg;

    switch (entry.type) {
      case _UssdType.network:
        color = Colors.white38;
        icon = Icons.wifi_tethering_rounded;
        label = 'NETWORK';
        bg = const Color(0xFF0A1628);
        break;
      case _UssdType.system:
        color = Colors.white;
        icon = Icons.phone_rounded;
        label = 'USSD';
        bg = const Color(0xFF0F3460);
        break;
      case _UssdType.user:
        color = AppColors.primary;
        icon = Icons.smartphone_rounded;
        label = 'YOU';
        bg = AppColors.primary.withOpacity(0.08);
        break;
      case _UssdType.menu:
        color = Colors.amber;
        icon = Icons.menu_rounded;
        label = 'MENU';
        bg = Colors.amber.withOpacity(0.06);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: color, letterSpacing: 0.5)),
              const Spacer(),
              Text('#${entry.step}',
                  style: GoogleFonts.inter(
                      fontSize: 10, color: color.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 6),
          Text(entry.text,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.white, height: 1.4)),
        ],
      ),
    );
  }
}

enum _UssdType { network, system, user, menu }

class _UssdEntry {
  final _UssdType type;
  final String text;
  final int step;
  _UssdEntry({required this.type, required this.text, required this.step});
}
