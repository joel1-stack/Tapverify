import 'package:hive_flutter/hive_flutter.dart';
import '../models/member.dart';
import '../models/pending_event.dart';

class HiveService {
  static late Box<Member> _membersBox;
  static late Box<PendingEvent> _pendingBox;
  static late Box _settingsBox;

  static Future<void> init() async {
    Hive.registerAdapter(MemberAdapter());
    Hive.registerAdapter(PendingEventAdapter());
    _membersBox = await Hive.openBox<Member>('members');
    _pendingBox = await Hive.openBox<PendingEvent>('pending_events');
    _settingsBox = await Hive.openBox('settings');
  }

  static Future<void> saveAuth(String token, Map<String, dynamic> staff) async {
    await _settingsBox.put('auth_token', token);
    await _settingsBox.put('staff', staff);
  }

  static Future<void> clearAuth() async {
    await _settingsBox.delete('auth_token');
    await _settingsBox.delete('staff');
  }

  static Future<bool> isLoggedIn() async {
    return _settingsBox.get('auth_token') != null;
  }

  static String? getToken() => _settingsBox.get('auth_token');
  static Map? getStaff() => _settingsBox.get('staff');

  static Future<void> cacheMembers(List<Member> members) async {
    await _membersBox.clear();
    for (var m in members) {
      await _membersBox.put(m.id, m);
    }
  }

  static List<Member> getCachedMembers() {
    return _membersBox.values.toList();
  }

  static Future<void> clearMembers() async => await _membersBox.clear();

  static Future<void> queueEvent(PendingEvent event) async {
    await _pendingBox.add(event);
  }

  static List<PendingEvent> getPendingEvents() {
    return _pendingBox.values.where((e) => !e.synced).toList();
  }

  static Future<void> markSynced(int index) async {
    final event = _pendingBox.getAt(index);
    if (event != null) {
      event.synced = true;
      await _pendingBox.putAt(index, event);
    }
  }

  static Future<void> clearPending() async => await _pendingBox.clear();

  static int pendingCount() => getPendingEvents().length;
}
