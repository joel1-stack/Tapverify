import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/member.dart';
import '../models/pending_event.dart';
import 'hive_service.dart';

class ApiService {
  static const String baseUrl = 'https://tverify.co.ke';

  static Map<String, String> get _headers {
    final token = HiveService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String phone, String pin) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'pin': pin}),
    );
    return jsonDecode(resp.body);
  }

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
        await HiveService.cacheMembers(members);
        return members;
      }
    } catch (e) {
      // Return cached on error
    }
    return HiveService.getCachedMembers();
  }

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
      );
      await HiveService.queueEvent(pending);
      return {
        'success': true,
        'queued': true,
        'message': 'Saved offline. Will sync when online.',
      };
    }
  }

  static Future<int> syncPending() async {
    final pending = HiveService.getPendingEvents();
    int synced = 0;
    for (int i = 0; i < pending.length; i++) {
      final event = pending[i];
      try {
        final body = {
          'workspace_id': HiveService.getStaff()?['workspace']?['id'] ?? '',
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
    final resp = await http.get(
      Uri.parse('$baseUrl/api/v1/stats/?workspace_id=$workspaceId'),
      headers: _headers,
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed to load stats');
  }

  static Future<Map<String, dynamic>> createDemo() async {
    final resp = await http.post(
      Uri.parse('$baseUrl/api/v1/demo/setup/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': 'Demo Chama', 'phone': '254712345678'}),
    );
    return jsonDecode(resp.body);
  }
}
