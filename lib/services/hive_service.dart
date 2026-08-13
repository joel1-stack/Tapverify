import 'package:hive_flutter/hive_flutter.dart';
import '../models/member.dart';
import '../models/pending_event.dart';

/// Local persistence layer (Hive) for everything the app needs offline.
///
/// Three boxes:
///  - `members`        — typed [Member] objects, cached per workspace
///  - `pending_events` — typed [PendingEvent] queue awaiting server sync
///  - `settings`       — raw maps: auth token, staff profile, workspaces,
///                       active workspace, contribution campaigns
///
/// Also owns the workspace/campaign CRUD used by the multi-org screens and the
/// offline contribution flow. [ApiService] is the only other file that talks to
/// this store.
class HiveService {
  static late Box<Member> _membersBox;
  static late Box<PendingEvent> _pendingBox;
  static late Box _settingsBox;

  /// Registers the Hive adapters and opens all three boxes. Called once from
  /// `main()` before the first frame.
  static Future<void> init() async {
    Hive.registerAdapter(MemberAdapter());
    Hive.registerAdapter(PendingEventAdapter());
    _membersBox = await Hive.openBox<Member>('members');
    _pendingBox = await Hive.openBox<PendingEvent>('pending_events');
    _settingsBox = await Hive.openBox('settings');
  }

  // ---- Auth session ----
  static Future<void> saveAuth(String token, Map<String, dynamic> staff) async {
    await _settingsBox.put('auth_token', token);
    await _settingsBox.put('staff', staff);
  }

  static Future<void> clearAuth() async {
    await _settingsBox.delete('auth_token');
    await _settingsBox.delete('staff');
    await _settingsBox.delete('org_selection_done');
  }

  static bool get orgSelectionDone =>
      _settingsBox.get('org_selection_done', defaultValue: false) == true;

  static Future<void> markOrgSelectionDone() async {
    await _settingsBox.put('org_selection_done', true);
  }

  static List<Map> getAccessibleWorkspaces() {
    final myIds = getStaffWorkspaceIds();
    if (myIds.isEmpty) return <Map>[];
    return getWorkspaces().where((w) => myIds.contains(w['id'])).toList();
  }

  static Future<bool> isLoggedIn() async {
    return _settingsBox.get('auth_token') != null;
  }

  static String? getToken() => _settingsBox.get('auth_token');
  static Map? getStaff() => _settingsBox.get('staff');

  // ---- Multi-org workspaces ----
  static dynamic _normalize(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) => out[k.toString()] = _normalize(v));
      return out;
    }
    if (value is List) {
      return value.map(_normalize).toList();
    }
    return value;
  }

  static List<Map> getWorkspaces() {
    final list = _settingsBox.get('workspaces', defaultValue: <Map>[]);
    return ((list as List).map((w) => _normalize(w))).cast<Map>().toList();
  }

  static String? get activeWorkspaceId =>
      _settingsBox.get('active_workspace_id');

  static Map? getActiveWorkspace() {
    final id = activeWorkspaceId;
    if (id == null) return null;
    for (final ws in getWorkspaces()) {
      if (ws['id'] == id) return ws;
    }
    return null;
  }

  static Future<void> saveWorkspaces(List<Map> workspaces) async {
    await _settingsBox.put('workspaces', workspaces);
  }

  static Future<void> addWorkspace(Map workspace) async {
    final list = getWorkspaces();
    list.removeWhere((w) => w['id'] == workspace['id']);
    list.add(workspace);
    await _settingsBox.put('workspaces', list);
    await setActiveWorkspace(workspace['id']);
  }

  static Future<void> setActiveWorkspace(String id) async {
    await _settingsBox.put('active_workspace_id', id);
    final ws = getActiveWorkspace();
    if (ws != null) {
      final staff = Map<String, dynamic>.from(_settingsBox.get('staff') ?? {});
      staff['workspace'] = ws;
      await _settingsBox.put('staff', staff);
    }
  }

  static Future<void> cacheMembers(List<Member> members) async {
    await _membersBox.clear();
    for (var m in members) {
      await _membersBox.put(m.id, m);
    }
  }

  static Future<void> cacheMembersForWorkspace(
      String workspaceId, List<Member> members) async {
    // Remove old members of this workspace, keep others
    final all = _membersBox.values.toList();
    final keep = all.where((m) => m.workspaceId != workspaceId).toList();
    await _membersBox.clear();
    for (var m in keep) {
      await _membersBox.put(m.id, m);
    }
    for (var m in members) {
      await _membersBox.put(m.id, m);
    }
  }

  static Future<void> addMember(Member member) async {
    await _membersBox.put(member.id, member);
  }

  static Future<void> addMembers(List<Member> members) async {
    // Members carry their own workspaceId
    for (var m in members) {
      await _membersBox.put(m.id, m);
    }
  }

  static List<Member> getCachedMembers() {
    return _membersBox.values.toList();
  }

  static List<Member> getMembersForWorkspace(String workspaceId) {
    return _membersBox.values
        .where((m) => m.workspaceId == workspaceId)
        .toList();
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

  // ---- Staff access (which orgs this treasurer can manage) ----
  static List<String> getStaffWorkspaceIds() {
    final staff = _settingsBox.get('staff');
    final ids = staff?['workspace_ids'];
    if (ids is List) return ids.cast<String>();
    final ws = staff?['workspace'];
    if (ws is Map && ws['id'] != null) return [ws['id'].toString()];
    return <String>[];
  }

  static List<Map> getMyWorkspaces() {
    final myIds = getStaffWorkspaceIds();
    return getWorkspaces().where((w) => myIds.contains(w['id'])).toList();
  }

  static Future<void> grantWorkspaceAccess(String workspaceId,
      {String role = 'treasurer'}) async {
    final staff = Map<String, dynamic>.from(_settingsBox.get('staff') ?? {});
    final ids = <String>[...getStaffWorkspaceIds()];
    if (!ids.contains(workspaceId)) ids.add(workspaceId);
    staff['workspace_ids'] = ids;
    staff['role'] = role;
    await _settingsBox.put('staff', staff);
  }

  static Future<void> revokeWorkspaceAccess(String workspaceId) async {
    final staff = Map<String, dynamic>.from(_settingsBox.get('staff') ?? {});
    final ids = getStaffWorkspaceIds()..remove(workspaceId);
    staff['workspace_ids'] = ids;
    await _settingsBox.put('staff', staff);
  }

  // ---- Contribution campaigns ----
  static List<Map> getCampaigns() {
    final list = _settingsBox.get('campaigns', defaultValue: <Map>[]);
    return ((list as List).map((c) => _normalize(c))).cast<Map>().toList();
  }

  static List<Map> getCampaignsForWorkspace(String workspaceId) {
    return getCampaigns()
        .where((c) => c['workspace_id'] == workspaceId)
        .toList();
  }

  static Future<void> addCampaign(Map campaign) async {
    final list = getCampaigns();
    list.removeWhere((c) => c['id'] == campaign['id']);
    list.add(campaign);
    await _settingsBox.put('campaigns', list);
  }

  static Future<void> updateCampaign(Map campaign) async {
    final list = getCampaigns();
    final idx = list.indexWhere((c) => c['id'] == campaign['id']);
    if (idx >= 0) {
      list[idx] = campaign;
    } else {
      list.add(campaign);
    }
    await _settingsBox.put('campaigns', list);
  }
}
