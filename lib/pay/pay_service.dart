import 'dart:math';
import 'package:flutter/material.dart';
import 'pay_models.dart';

/// In-memory source of truth for TapVerify Pay. A seller generates a payment
/// link, the buyer pays through it, and both sides earn a verified streak.
class PayService {
  PayService._();
  static final PayService instance = PayService._();

  final List<PaymentLink> _links = [];
  final Map<String, StreakProfile> _profiles = {};

  static const String demoBuyerName = 'Amina Yusuf';
  static const String demoBuyerPhone = '254700111222';

  static final List<Map<String, Object>> _channels = [
    {'id': 'till', 'label': 'M-Pesa Till', 'icon': Icons.storefront_rounded},
    {'id': 'paybill', 'label': 'M-Pesa Paybill', 'icon': Icons.receipt_rounded},
    {'id': 'bank', 'label': 'Bank Account', 'icon': Icons.account_balance_rounded},
    {'id': 'sasapay', 'label': 'SasaPay Wallet', 'icon': Icons.account_balance_wallet_rounded},
  ];

  static List<Map<String, Object>> get channels => _channels;

  List<PaymentLink> get links => List.unmodifiable(_links);

  /// Merchant (or foreman) profile — the receiver side.
  StreakProfile sellerProfile(String name) =>
      _profile(name, '254712345678');

  /// Buyer profile — anyone paying a link.
  StreakProfile buyerProfile(String name) => _profile(name, '254700111222');

  StreakProfile _profile(String name, String phone) {
    return _profiles.putIfAbsent(
      '$name|$phone',
      () => StreakProfile(name: name, phone: phone),
    );
  }

  PaymentLink? byToken(String token) {
    final t = token.trim().toUpperCase();
    for (final l in _links) {
      if (l.token.toUpperCase() == t) return l;
    }
    return null;
  }

  /// Create a payment link and return it.
  PaymentLink createLink({
    required String sellerName,
    required double amount,
    required String description,
    required String channel,
    required String channelDetails,
  }) {
    final link = PaymentLink(
      token: _token(),
      sellerName: sellerName,
      amount: amount,
      description: description,
      channel: channel,
      channelDetails: channelDetails,
      createdAt: DateTime.now(),
    );
    _links.insert(0, link);
    return link;
  }

  /// Pay a link as the buyer; both buyer and seller streaks advance.
  ({String ref, String attestation}) payLink(PaymentLink link, String buyerName) {
    link.paidCount++;
    final buyer = buyerProfile(buyerName);
    final seller = sellerProfile(link.sellerName);
    buyer.payments++;
    seller.payments++;
    final streakUp = buyer.payments % 3 == 0 || seller.payments % 3 == 0;
    if (streakUp) {
      buyer.streakMonths++;
      seller.streakMonths++;
    }
    final ref = 'TVP-${Random().nextInt(90000) + 10000}';
    final attestation =
        '0x${List.generate(12, (_) => Random().nextInt(16).toRadixString(16)).join()}';
    return (ref: ref, attestation: attestation);
  }

  static String _token() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }
}