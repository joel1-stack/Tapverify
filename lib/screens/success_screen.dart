import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard_screen.dart';

class SuccessScreen extends StatelessWidget {
  final String memberName;
  final double amount;
  final String receiptUrl;
  final String pin;
  final bool queued;

  const SuccessScreen({
    super.key,
    required this.memberName,
    required this.amount,
    required this.receiptUrl,
    required this.pin,
    this.queued = false,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A4F),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 24),
                Text(
                  queued ? 'Saved Offline' : 'APPROVED',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ksh ${amount.toStringAsFixed(0)} from $memberName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                if (!queued) ...[
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFFFFF8E7),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Receipt PIN', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(pin, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8)),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: receiptUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receipt link copied')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy Receipt Link'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B6914)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    (route) => false,
                  ),
                  child: const Text('COLLECT NEXT MEMBER'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
