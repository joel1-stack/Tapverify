import 'package:flutter/material.dart';

/// Universal payment-link model. A seller (factory, shop, chama, SACCO or
/// freelancer) generates a link; the buyer pays through it; both sides earn a
/// verified reputation streak.
class PaymentLink {
  PaymentLink({
    required this.token,
    required this.sellerName,
    required this.amount,
    required this.description,
    required this.channel,
    required this.channelDetails,
    required this.createdAt,
  });

  final String token;
  final String sellerName;
  final double amount;
  final String description;
  final String channel;
  final String channelDetails;
  final DateTime createdAt;
  int paidCount = 0;
  bool closed = false;
}

/// A reputation profile — the streak both the payer and the receiver build.
class StreakProfile {
  StreakProfile({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;
  int payments = 0;
  int streakMonths = 1;
  double onTimePct = 100;

  int get badgesEarned {
    var n = 0;
    if (streakMonths >= 3) n++;
    if (streakMonths >= 6) n++;
    if (streakMonths >= 12) n++;
    return n;
  }
}