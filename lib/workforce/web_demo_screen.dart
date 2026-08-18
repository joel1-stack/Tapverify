import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../workforce/workforce_models.dart';

/// Web demo — an auto-playing story of what the TapVerify mobile app serves.
/// For the web build this is the marketing/demo surface; on the phone it runs
/// from the More screen so the team can present it anywhere.
class WebDemoScreen extends StatefulWidget {
  const WebDemoScreen({super.key});

  @override
  State<WebDemoScreen> createState() => _WebDemoScreenState();
}

class _WebDemoScreenState extends State<WebDemoScreen> {
  int _step = 0;
  bool _playing = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  void _startAuto() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_playing) {
        setState(() => _step = (_step + 1) % _steps.length);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _go(int i) {
    setState(() => _step = i.clamp(0, _steps.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1713),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(AppAssets.logoFull, fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'TapVerify Workforce — demo',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white),
                    tooltip: _playing ? 'Pause' : 'Play',
                    onPressed: () => setState(() => _playing = !_playing),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _steps.length,
                  minHeight: 6,
                  backgroundColor: Colors.white.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                itemCount: _steps.length,
                controller: PageController(initialPage: 0),
                onPageChanged: (i) => setState(() => _step = i),
                itemBuilder: (context, i) =>
                    _stepView(_steps[i], i == _step),
              ),
            ),
            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => _go(_step - 1),
                  ),
                  const Spacer(),
                  for (int i = 0; i < _steps.length; i++)
                    GestureDetector(
                      onTap: () => _go(i),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? AppColors.accent
                              : Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => _go(_step + 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepView(_DemoStep s, bool active) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: s.color.withOpacity(0.4)),
                      ),
                      child: Text(
                        s.phase,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: s.color,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      s.title,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.body,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in s.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.15)),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(flex: 4, child: _phoneMock(s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phoneMock(_DemoStep s) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF241F1A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 5,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: 210,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: s.mock,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DemoStep {
  const _DemoStep({
    required this.phase,
    required this.title,
    required this.body,
    required this.tags,
    required this.color,
    required this.mock,
  });

  final String phase;
  final String title;
  final String body;
  final List<String> tags;
  final Color color;
  final Widget mock;
}

final _steps = [
  _DemoStep(
    phase: '1 · OBLIGATION',
    title: 'The foreman raises a collection',
    body:
        'Juma Kamau opens the mobile app and raises the August welfare levy for all 47 workers at Kamau Metalworks. Amount, deadline and payment rail in seconds.',
    tags: ['Foreman app', '47 workers', 'Ksh 200 each'],
    color: AppColors.accent,
    mock: _obligationMock(),
  ),
  _DemoStep(
    phase: '2 · NOTIFY',
    title: 'Every worker gets the prompt',
    body:
        'Each phone receives the obligation: a LOOP M-Pesa prompt or a SasaPay checkout link, delivered over Africa\u2019s Talking SMS. No one can say "I didn\u2019t know".',
    tags: ['SMS', 'STK prompt', 'Checkout link'],
    color: AppColors.secondary,
    mock: _notifyMock(),
  ),
  _DemoStep(
    phase: '3 · PAY',
    title: 'Ochieng pays from his phone',
    body:
        'Ochieng taps Pay now and completes the Ksh 200 payment through the checkout link. The rail confirms instantly — no queues, no cash envelopes, no Excel.',
    tags: ['M-PESA', 'SasaPay', 'Payment confirmed'],
    color: AppColors.sasapay,
    mock: _payMock(),
  ),
  _DemoStep(
    phase: '4 · PROOF',
    title: 'The foreman sees proof in real time',
    body:
        'The collection page fills green as payments land — each with its rail and transfer ID. Reminders go only to the workers who have not paid.',
    tags: ['Who paid', 'Transfer IDs', 'Live status'],
    color: AppColors.success,
    mock: _proofMock(),
  ),
  _DemoStep(
    phase: '5 · REWARD',
    title: 'Streaks, badges and rewards',
    body:
        'On-time payers grow their streak and unlock badges. The 12-month gold streak is attested on Avalanche as optional proof. Paying on time becomes a habit.',
    tags: ['Streak', 'Badge', 'Avalanche attestation'],
    color: const Color(0xFFC9A227),
    mock: _rewardMock(),
  ),
];

Widget _obligationMock() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 16),
          const SizedBox(width: 6),
          Text('New collection',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text)),
        ],
      ),
      const SizedBox(height: 10),
      _mockField('August welfare levy'),
      const SizedBox(height: 8),
      _mockField('Ksh 200'),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.loop.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.loop.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text('LOOP M-Pesa Prompt',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('RAISE & NOTIFY ALL 47',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    ],
  );
}

Widget _notifyMock() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.sms_rounded, color: AppColors.secondary, size: 18),
      const SizedBox(height: 8),
      _smsBubble('August welfare levy — Ksh 200 due. Pay via your LOOP prompt or the checkout link. — Kamau Metalworks'),
      const SizedBox(height: 8),
      _smsBubble('Pay now: km.co.ke/pay/ae71', bold: true),
      const SizedBox(height: 8),
      Center(
        child: Text('SMS delivered via Africa\u2019s Talking',
            style: GoogleFonts.inter(
                fontSize: 10, color: AppColors.muted, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _payMock() {
  return Column(
    children: [
      Text('Ksh 200',
          style: GoogleFonts.inter(
              fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
      const SizedBox(height: 2),
      Text('Ochieng Odhiambo · KM47',
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.muted)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.sasapay.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.sasapay.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.link_rounded, size: 14, color: AppColors.sasapay),
            const SizedBox(width: 6),
            Text('SasaPay Checkout',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text('PAID & VERIFIED',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text('ref TAM202608141181682087',
          style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.muted)),
    ],
  );
}

Widget _proofMock() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text('WHO PAID · 47',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text)),
          const Spacer(),
          Text('32/47',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A))),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: 0.68,
          minHeight: 6,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          valueColor: const AlwaysStoppedAnimation(Color(0xFF16A34A)),
        ),
      ),
      const SizedBox(height: 10),
      for (final row in const [
        ('Ochieng Odhiambo', 'COMPLETED', 'TAM...087'),
        ('Wanjiru Kiprop', 'VERIFIED', 'TAM...747'),
        ('Mwangi Okoth', 'PENDING', 'remind'),
        ('Chebet Rono', 'NOTIFIED', 'sent'),
      ]) ...[
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(row.$1,
                    style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text)),
              ),
              Text(row.$2,
                  style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: row.$2 == 'COMPLETED'
                          ? const Color(0xFF16A34A)
                          : row.$2 == 'VERIFIED'
                              ? const Color(0xFF0F766E)
                              : row.$2 == 'PENDING'
                                  ? AppColors.warning
                                  : AppColors.secondary)),
              const SizedBox(width: 6),
              Text(row.$3,
                  style: GoogleFonts.inter(
                      fontSize: 9.5, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    ],
  );
}

Widget _rewardMock() {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final e in const [true, true, false, true]) ...[
            if (e != true || true)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (e ? const Color(0xFFC9A227) : AppColors.muted)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: (e ? const Color(0xFFC9A227) : AppColors.muted)
                          .withOpacity(0.4)),
                ),
                child: Icon(
                  e
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_rounded,
                  size: 18,
                  color: e ? const Color(0xFFC9A227) : AppColors.muted,
                ),
              ),
          ],
        ],
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFC9A227).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC9A227).withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department_rounded,
                size: 14, color: Color(0xFFC9A227)),
            const SizedBox(width: 6),
            Text('12-month Gold Streak',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text('Attested on Avalanche (optional)',
          style: GoogleFonts.inter(
              fontSize: 9.5, color: AppColors.muted, fontStyle: FontStyle.italic)),
    ],
  );
}

Widget _mockField(String label) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text)),
  );
}

Widget _smsBubble(String text, {bool bold = false}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 170),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
          bottomLeft: Radius.circular(2),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9.5,
          height: 1.35,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: AppColors.text,
        ),
      ),
    ),
  );
}
