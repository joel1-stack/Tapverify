import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/app_feedback.dart';

/// Which legal document to show.
enum LegalDoc { terms, privacy }

/// Public Terms of Service and Privacy Policy pages.
///
/// Reachable in-app from the create-account screen and on the web at
/// `#/terms` and `#/privacy` (same hash routing as the payment page).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  /// Returns the doc for a `#/terms` or `#/privacy` URL, else null.
  static LegalDoc? parseRoute(Uri uri) {
    if (uri.fragment == '/terms') return LegalDoc.terms;
    if (uri.fragment == '/privacy') return LegalDoc.privacy;
    return null;
  }

  String get _title =>
      doc == LegalDoc.terms ? 'Terms of Service' : 'Privacy Policy';

  IconData get _icon => doc == LegalDoc.terms
      ? Icons.description_outlined
      : Icons.privacy_tip_outlined;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: kSurface,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(8, top + 8, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryDark, kPrimary],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const AppLogo(height: 24, onDark: true),
                const Spacer(),
                const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  doc == LegalDoc.terms ? 'Terms' : 'Privacy',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
              children: [
                _introCard(),
                const SizedBox(height: 14),
                for (final section in _sections) ...[
                  _sectionCard(section),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: kPrimaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: kBrandInk,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Effective 7 October 2026',
                  style: TextStyle(fontSize: 12.5, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(_Section section) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: kPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final paragraph in section.paragraphs) ...[
            Text(
              paragraph,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[800],
                height: 1.55,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (section.paragraphs.length > 1)
            const SizedBox(height: -8),
        ],
      ),
    );
  }

  List<_Section> get _sections =>
      doc == LegalDoc.terms ? _termsSections : _privacySections;
}

class _Section {
  const _Section(this.title, this.paragraphs);

  final String title;
  final List<String> paragraphs;
}

const List<_Section> _termsSections = [
  _Section('1. About TapVerify', [
    'TapVerify is a payment tracking tool for chamas and savings groups. It helps a treasurer send payment links, keep track of who has paid, and confirm M-Pesa and manual payments.',
    'TapVerify is operated from Kenya. By creating an account or using the service you agree to these terms.',
  ]),
  _Section('2. Your account', [
    'You sign in with your phone number and a one-time code sent by SMS. You are responsible for anything done from your account, so keep the code to yourself.',
    'You must be at least 18 years old to use TapVerify. Give accurate information and keep it up to date.',
  ]),
  _Section('3. What TapVerify does not do', [
    'TapVerify does not hold your money, act as a bank, or issue credit. The money you collect goes directly to the till number, paybill, personal number, or bank account you configured for the collection.',
    'TapVerify only records and reports the payments you and your members report, and the payments detected from M-Pesa confirmations.',
  ]),
  _Section('4. Collections and members', [
    'You are responsible for the collection titles, amounts, and due dates you create, and for making sure they are accurate before you send them out.',
    'You confirm that you have a legitimate reason to contact the people you add as members, and that you are allowed to send them SMS messages and payment links.',
  ]),
  _Section('5. Payments and confirmations', [
    'M-Pesa payments are processed by Safaricom. The PIN is entered only on the M-Pesa prompt on the member\'s phone. TapVerify never asks for or stores an M-Pesa PIN.',
    'When a member taps "I have already paid" or sends a partial payment from their link, the claim waits for you to confirm it. Marks you make as cash or other are your own records.',
    'Payment details you enter for manual payments, such as bank instructions, are your responsibility to keep correct.',
  ]),
  _Section('6. Payment links', [
    'A payment link shows the collection amount and lets that member submit a claim. Anyone who obtains the link can see those details, so send links only to the right person.',
    'A payment link does not give anyone access to your money or your account.',
  ]),
  _Section('7. SMS and notifications', [
    'TapVerify sends one-time codes, invitations, reminders, payment links, and payment confirmations by SMS through messaging providers. Standard network charges for SMS may apply to the recipient.',
  ]),
  _Section('8. Acceptable use', [
    'You agree not to use TapVerify to run fraudulent collections, submit false payment claims, harass anyone, send spam, break the law, or interfere with the service.',
    'We may suspend or close an account that breaks these rules.',
  ]),
  _Section('9. Fees', [
    'The service may be free during testing. We may introduce paid features, such as a small activation fee per collection, with clear notice before they take effect.',
  ]),
  _Section('10. Availability', [
    'We work to keep TapVerify running, but the service may be unavailable during maintenance or because of factors outside our control, including mobile networks and Safaricom services.',
  ]),
  _Section('11. Disclaimers and liability', [
    'TapVerify is provided as is and as available. To the maximum extent allowed by Kenyan law, TapVerify is not liable for indirect or consequential losses, such as missed contributions or delays in receiving money.',
    'You remain responsible for the money you collect and for how you use the records TapVerify gives you.',
  ]),
  _Section('12. Changes to these terms', [
    'We may update these terms from time to time. The current version always lives at tapverify.vercel.app/#/terms. Continuing to use TapVerify after a change means you accept the updated terms.',
  ]),
  _Section('13. Contact and applicable law', [
    'These terms are governed by the laws of Kenya. Questions about TapVerify can be raised through our website at tapverify.co.ke.',
  ]),
];

const List<_Section> _privacySections = [
  _Section('1. Who we are', [
    'This policy explains what TapVerify collects when you use the TapVerify app, website, and payment pages, and how that information is used. TapVerify is operated from Kenya.',
  ]),
  _Section('2. What we collect', [
    'Account details: your name, phone number, and group or chama name.',
    'Collection data: the titles, amounts, and due dates you create, and the names and phone numbers of the members you add.',
    'Payment records: amounts, payment status, M-Pesa receipt numbers, transaction references, and the times payments were recorded.',
    'Messages you send: payment claims, notes, and issues submitted from a payment page.',
    'Technical data: app version, device type, and, on the website, your IP address and session information needed to keep you signed in.',
  ]),
  _Section('3. How we use it', [
    'To run the service: creating your account, signing you in with an SMS code, showing your collections, and keeping your records accurate.',
    'To send messages: invitations, reminders, payment links, one-time codes, and payment confirmations by SMS.',
    'To detect and reconcile payments, prevent fraud and misuse, improve the product, and comply with legal obligations.',
  ]),
  _Section('4. M-Pesa and payments', [
    'When a member taps "Pay with M-Pesa", Safaricom sends a payment prompt to that person\'s phone. The PIN is entered only on Safaricom\'s prompt.',
    'TapVerify receives the outcome of the payment: the amount, the M-Pesa receipt number, the phone number, and the time. TapVerify never sees or stores M-Pesa PINs, card numbers, or bank passwords.',
  ]),
  _Section('5. Who we share it with', [
    'Safaricom, to process and confirm M-Pesa payments. Messaging providers such as Sozuri and Africa\'s Talking, to deliver SMS. Infrastructure providers that host the service, under agreements that require them to protect your data.',
    'Authorities, when disclosure is required by law. We do not sell your personal information or your members\' personal information.',
  ]),
  _Section('6. How long we keep it', [
    'While your account is active, and after that only for as long as needed for financial records and legal obligations. You can ask us to delete your account and personal data, except records we must keep by law.',
  ]),
  _Section('7. Security', [
    'We use access controls, signed tokens, and encrypted connections to protect your data. No method of storage is completely secure, so we also limit who inside the service can see your information.',
  ]),
  _Section('8. Your rights', [
    'You can ask for a copy of your data, correct anything wrong, or ask us to delete it. Requests can be raised through our website at tapverify.co.ke.',
  ]),
  _Section('9. Children', [
    'TapVerify is not aimed at children. Members you add must be adults you are allowed to contact.',
  ]),
  _Section('10. Where data is processed', [
    'Your data is processed in Kenya and by the providers listed above, which may operate in other countries. Those providers are required to protect your data under their agreements with us.',
  ]),
  _Section('11. Cookies and local storage', [
    'The TapVerify website stores only what is needed to keep you signed in and to remember your preferences. We do not use advertising trackers.',
  ]),
  _Section('12. Changes and contact', [
    'We may update this policy from time to time. The current version always lives at tapverify.vercel.app/#/privacy. Questions can be raised through our website at tapverify.co.ke.',
  ]),
];
