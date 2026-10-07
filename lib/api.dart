import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'demo.dart';
import 'main.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// True when the server rejected the stored token.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class Api {
  /// Nothing used to time out, so a dead backend left spinners turning forever.
  static const Duration _timeout = Duration(seconds: 30);

  /// Set by the app shell so a rejected token can send the user back to login
  /// instead of leaving every screen stuck on "Session expired".
  static void Function()? onUnauthorized;

  static Future<String?> get _token async =>
      (await SharedPreferences.getInstance()).getString('auth_token');

  static Future<void> saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString('auth_token', token);

  static Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).remove('auth_token');

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Uri _u(String path) => Uri.parse('$kApiBaseUrl$path');

  /// Mobile normally talks to Django. The web build is the public demo with
  /// no server behind it, and a shareable APK can force the same in-memory
  /// backend with --dart-define=DEMO=true so it works on any phone without
  /// hosting.
  static const bool _forceDemo = bool.fromEnvironment('DEMO');

  static bool get _demo => kIsWeb || _forceDemo;

  static dynamic _decode(http.Response resp) {
    if (resp.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(resp.bodyBytes));
    } on FormatException {
      // Django error pages and proxies answer with HTML, not JSON.
      return null;
    }
  }

  static Future<dynamic> _handle(http.Response resp) async {
    final body = _decode(resp);
    if (resp.statusCode >= 200 && resp.statusCode < 300) return body;

    if (resp.statusCode == 401) {
      await clearToken();
      onUnauthorized?.call();
      throw ApiException('Session expired. Please log in again.',
          statusCode: 401);
    }

    final message = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'Something went wrong (${resp.statusCode})';
    throw ApiException(message, statusCode: resp.statusCode);
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  /// Returns {'sent': bool, 'dev_code': String?} (dev_code only in sandbox).
  static Future<Map<String, dynamic>> requestOtp(String phone) async {
    if (_demo) return Demo.instance.requestOtp(phone);
    final resp = await http
        .post(_u('/api/auth/otp/'),
            headers: await _headers(auth: false),
            body: jsonEncode({'phone': phone}))
        .timeout(_timeout);
    final data = await _handle(resp);
    if (data is! Map) throw ApiException('Unexpected reply from TapVerify');
    return Map<String, dynamic>.from(data);
  }

  static Future<String> verifyOtp(String phone, String code) async {
    if (_demo) {
      final token = Demo.instance.verifyOtp(phone, code);
      await saveToken(token);
      final profile = Demo.instance.me();
      await saveProfile(
        name: (profile['name'] ?? '') as String,
        group: (profile['group_name'] ?? '') as String,
      );
      return token;
    }
    final resp = await http
        .post(_u('/api/auth/verify/'),
            headers: await _headers(auth: false),
            body: jsonEncode({'phone': phone, 'code': code}))
        .timeout(_timeout);
    final data = await _handle(resp);
    final token = data is Map ? data['token'] : null;
    if (token is! String || token.isEmpty) {
      throw ApiException('Unexpected reply from TapVerify');
    }
    await saveToken(token);
    if (data is Map) {
      await saveProfile(
        name: (data['name'] ?? '') as String,
        group: (data['group_name'] ?? '') as String,
      );
    }
    return token;
  }

  /// Create Account: name + phone + group name. Returns the OTP payload
  /// ({'sent': bool, 'dev_code': String?}) because the next step is always
  /// entering the code that was just sent.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String group = '',
  }) async {
    if (_demo) return Demo.instance.register(name: name, phone: phone, group: group);
    final resp = await http
        .post(_u('/api/auth/register/'),
            headers: await _headers(auth: false),
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'group_name': group,
            }))
        .timeout(_timeout);
    final data = await _handle(resp);
    if (data is! Map) throw ApiException('Unexpected reply from TapVerify');
    return Map<String, dynamic>.from(data);
  }

  /// Session check plus profile: {'phone', 'name', 'group_name'}.
  static Future<Map<String, dynamic>> me() async {
    if (_demo) return Demo.instance.me();
    final resp =
        await http.get(_u('/api/me/'), headers: await _headers()).timeout(_timeout);
    final data = await _handle(resp);
    if (data is! Map) throw ApiException('Unexpected reply from TapVerify');
    return Map<String, dynamic>.from(data);
  }

  // ── Profile cache ─────────────────────────────────────────────────────

  /// The signed-in secretary's name and group, kept locally so Home can show
  /// them without a round trip on every open.
  static Future<void> saveProfile({String name = '', String group = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('me_name', name);
    await prefs.setString('me_group', group);
  }

  static Future<Map<String, String>> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('me_name') ?? '',
      'group': prefs.getString('me_group') ?? '',
    };
  }

  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('me_name');
    await prefs.remove('me_group');
  }

  // ── Collections ───────────────────────────────────────────────────────

  static Future<List<CollectionSummary>> listCollections() async {
    if (_demo) return Demo.instance.listCollections();
    final resp = await http
        .get(_u('/api/collections/'), headers: await _headers())
        .timeout(_timeout);
    final data = await _handle(resp);
    if (data is! List) throw ApiException('Unexpected reply from TapVerify');
    return data
        .whereType<Map>()
        .map((e) => CollectionSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<CollectionDetail> getCollection(int id) async {
    if (_demo) return Demo.instance.getCollection(id);
    final resp = await http
        .get(_u('/api/collections/$id/'), headers: await _headers())
        .timeout(_timeout);
    final data = await _handle(resp);
    if (data is! Map) throw ApiException('Unexpected reply from TapVerify');
    return CollectionDetail.fromJson(Map<String, dynamic>.from(data));
  }

  /// Returns the created collection detail plus a notification summary.
  static Future<CollectionDetail> createCollection({
    required String title,
    required String amount,
    String? dueDate,
    required String payoutMethod,
    Map<String, String> payoutFields = const {},
    required String membersText,
  }) async {
    if (_demo) {
      return Demo.instance.createCollection(
        title: title,
        amount: amount,
        dueDate: dueDate,
        payoutMethod: payoutMethod,
        payoutFields: payoutFields,
        membersText: membersText,
      );
    }
    final resp = await http
        .post(_u('/api/collections/'),
            headers: await _headers(),
            body: jsonEncode({
              'title': title,
              'amount': amount,
              if (dueDate != null) 'due_date': dueDate,
              'payout_method': payoutMethod,
              ...payoutFields,
              'members_text': membersText,
            }))
        .timeout(_timeout);
    final data = await _handle(resp);
    if (data is! Map) throw ApiException('Unexpected reply from TapVerify');
    return CollectionDetail.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<int> remindUnpaid(int collectionId) async {
    if (_demo) return Demo.instance.remindUnpaid(collectionId);
    final resp = await http
        .post(_u('/api/collections/$collectionId/remind-unpaid/'),
            headers: await _headers())
        .timeout(_timeout);
    final data = await _handle(resp);
    final sent = data is Map ? data['sent'] : null;
    return sent is int ? sent : 0;
  }

  static Future<List<int>> exportCsv(int collectionId) async {
    if (_demo) return Demo.instance.exportCsv(collectionId);
    final resp = await http
        .get(_u('/api/collections/$collectionId/export.csv'),
            headers: await _headers())
        .timeout(_timeout);
    if (resp.statusCode != 200) await _handle(resp);
    return resp.bodyBytes;
  }

  // ── Members ───────────────────────────────────────────────────────────

  static Future<Member> markPaid(int memberId, String method,
      {double? amount}) async {
    if (_demo) {
      return Demo.instance.markPaid(memberId, method, amount: amount);
    }
    final resp = await http
        .post(_u('/api/members/$memberId/mark-paid/'),
            headers: await _headers(),
            body: jsonEncode({
              'method': method,
              if (amount != null) 'amount': amount,
            }))
        .timeout(_timeout);
    final data = await _handle(resp);
    if (data is! Map) throw ApiException('Unexpected reply from TapVerify');
    return Member.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<bool> remindMember(int memberId) async {
    if (_demo) return Demo.instance.remindMember(memberId);
    final resp = await http
        .post(_u('/api/members/$memberId/remind/'), headers: await _headers())
        .timeout(_timeout);
    final data = await _handle(resp);
    return data is Map && data['sent'] == true;
  }
}
