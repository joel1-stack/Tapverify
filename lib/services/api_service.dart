import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/member.dart';
import '../models/pending_event.dart';
import 'hive_service.dart';
import 'demo_service.dart';

/// Backend client for TapVerify (base: https://tverify.co.ke).
///
/// Every call is written to degrade gracefully offline:
///  - [login] falls back to demo auth when the server rejects/absent demo creds
///  - [fetchMembers] returns the Hive cache when the network fails
///  - [verifyMember] attaches GPS, and when the POST fails it either simulates
///    an approved receipt (demo mode) or queues a [PendingEvent] for later
///    [syncPending] upload
///
/// Staff credentials + bearer token come from [HiveService].
class ApiService {
  static const String baseUrl = 'https://tverify.co.ke';

  static Map<String, String> get _headers {
    final token = HiveService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Authenticates the treasurer. On success expects `{success, token, staff}`.
  /// Demo credentials (`254712345678` / `1234`) work either when the server
  /// rejects them or when the device is offline — both paths seed demo data.
  static Future<Map<String, dynamic>> login(String phone, String pin) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'pin': pin}),
      );
      final result = jsonDecode(resp.body);
      if (result['success'] == true) {
        return result;
      }
      // Fall back to demo auth if server is reachable but rejects demo creds
      if (phone == DemoService.demoPhone && pin == DemoService.demoPin) {
        await DemoService.seed();
        return {
          'success': true,
          'token': 'demo-token',
          'staff': DemoService.demoStaff()
        };
      }
      return result;
    } catch (e) {
      // Offline: use demo credentials
      if (phone == DemoService.demoPhone && pin == DemoService.demoPin) {
        await DemoService.seed();
        return {
          'success': true,
          'token': 'demo-token',
          'staff': DemoService.demoStaff()
        };
      }
      return {'success': false, 'error': 'Network error. Check connection.'};
    }
  }

  /// Fetches the member roster for a workspace and caches it. Offline → cached.
  static Future<List<Member>> fetchMembers(String workspaceId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/v1/members/?workspace_id=$workspaceId'),
        headers: _headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List results = data is List ? data : (data['results'] ?? []);
        final members = results.map((j) => Member.fromJson(j)).toList();
        await HiveService.cacheMembersForWorkspace(workspaceId, members);
        return members;
      }
    } catch (e) {
      // Return cached on error
    }
    return HiveService.getMembersForWorkspace(workspaceId);
  }

  /// Verifies one member's payment against the backend.
  ///
  /// Captures optional GPS, then POSTs to `/api/v1/verify/`. On success returns
  /// the server receipt. On failure: in demo mode it fabricates an approved
  /// receipt (ref + pin + SMS sent); otherwise it queues the event for offline
  /// sync and still hands back a local receipt object.
  static Future<Map<String, dynamic>> verifyMember({
    required String workspaceId,
    required String memberId,
    required double amount,
    String eventType = 'payment_cash',
    String verificationMethod = 'manual',
    String? notes,
  }) async {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // GPS optional
    }

    final staff = HiveService.getStaff();
    final body = {
      'workspace_id': workspaceId,
      'member_id': memberId,
      'amount': amount,
      'event_type': eventType,
      'verification_method': verificationMethod,
      if (position != null) 'gps_lat': position.latitude,
      if (position != null) 'gps_lng': position.longitude,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'verifier_phone': staff?['phone'] ?? '',
    };

    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/api/v1/verify/'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201) {
        return jsonDecode(resp.body);
      }
      throw Exception('Server error: ${resp.statusCode}');
    } catch (e) {
      final demoMode = HiveService.getToken() == 'demo-token';
      final ref = 'TV${_randomRef()}';
      final pin = _randomPin();
      final ws = HiveService.getActiveWorkspace();
      final name = ws?['name'] ?? 'Group';
      final till = ws?['till_number']?.toString() ?? '';
      final receipt = {
        'reference': ref,
        'pin': pin,
        'url': 'https://tverify.co.ke/r/$ref?pin=$pin',
        'group_name': name,
        'organization': name,
        if (till.isNotEmpty) 'till_number': till,
        'sms': {'status': 'sent', 'phone': _memberPhone(memberId)},
      };

      if (demoMode) {
        // Demo mode: simulate a fully approved payment + SMS sent
        return {
          'success': true,
          'queued': false,
          'message': 'Payment approved',
          'sms': {'status': 'sent', 'phone': _memberPhone(memberId)},
          'receipt': receipt,
        };
      }

      final pending = PendingEvent(
        memberId: memberId,
        memberCode: '',
        amount: amount,
        eventType: eventType,
        verificationMethod: verificationMethod,
        gpsLat: position?.latitude,
        gpsLng: position?.longitude,
        notes: notes,
        createdAt: DateTime.now(),
        workspaceId: HiveService.activeWorkspaceId ?? '',
      );
      await HiveService.queueEvent(pending);
      return {
        'success': true,
        'queued': true,
        'message': 'Saved offline. Will sync when online.',
        'receipt': receipt,
      };
    }
  }

  static String _memberPhone(String memberId) {
    for (final m in HiveService.getCachedMembers()) {
      if (m.id == memberId) return m.phone;
    }
    return '0712 345 678';
  }

  static String _randomRef() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    final buf = StringBuffer('R');
    for (int i = 0; i < 6; i++) {
      buf.write(chars[(rand + i * 7) % chars.length]);
    }
    return buf.toString();
  }

  static String _randomPin() {
    final rand = DateTime.now().millisecondsSinceEpoch % 10000;
    return rand.toString().padLeft(4, '0');
  }

  static Future<int> syncPending() async {
    final pending = HiveService.getPendingEvents();
    int synced = 0;
    for (int i = 0; i < pending.length; i++) {
      final event = pending[i];
      try {
        final body = {
          'workspace_id': event.workspaceId.isNotEmpty
              ? event.workspaceId
              : HiveService.activeWorkspaceId ?? '',
          'member_id': event.memberId,
          'amount': event.amount,
          'event_type': event.eventType,
          'verification_method': event.verificationMethod,
          if (event.gpsLat != null) 'gps_lat': event.gpsLat,
          if (event.gpsLng != null) 'gps_lng': event.gpsLng,
          if (event.notes != null) 'notes': event.notes,
        };
        final resp = await http.post(
          Uri.parse('$baseUrl/api/v1/verify/'),
          headers: _headers,
          body: jsonEncode(body),
        );
        if (resp.statusCode == 201) {
          await HiveService.markSynced(i);
          synced++;
        }
      } catch (e) {
        // Keep as pending
      }
    }
    return synced;
  }

  static Future<Map<String, dynamic>> fetchStats(String workspaceId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/v1/stats/?workspace_id=$workspaceId'),
        headers: _headers,
      );
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (e) {
      // Offline: fall through to demo stats
    }
    return DemoService.stats();
  }

  static Future<Map<String, dynamic>> createPaymentLink({
    required String workspaceId,
    required String memberId,
    required double amount,
  }) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/payment-link/create/'),
      headers: _headers,
      body: jsonEncode({
        'workspace_id': workspaceId,
        'member_id': memberId,
        'amount': amount,
      }),
    );
    return jsonDecode(resp.body);
  }

  static Future<Map<String, dynamic>> getPaymentRailInfo() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/api/v1/rail/info/'),
        headers: _headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == false && data['error'] != null) {
          return {'rail': 'loop', 'status': 'active', 'mode': 'demo'};
        }
        return data;
      }
    } catch (e) {
      // Offline: demo Loop rail is always active
    }
    return {'rail': 'loop', 'status': 'active', 'mode': 'demo'};
  }
}
