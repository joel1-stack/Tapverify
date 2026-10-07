import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../models.dart' show CollectionDetail, CollectionSummary, Member;
import '../utils/format.dart';
import '../widgets/app_feedback.dart';
import '../widgets/responsive.dart';
import 'create_collection_screen.dart';
import 'live_list_screen.dart';
import 'member_detail_sheet.dart';

/// Slide-up route used for the create flow.
Route<bool> _createRoute() => PageRouteBuilder<bool>(
      pageBuilder: (_, __, ___) => const CreateCollectionScreen(),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppMotion.enter)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      transitionDuration: AppMotion.medium,
    );

/// One section of the Members tab: a collection (chama) plus its members,
/// so people are grouped under the collection they pay into.
class _MemberGroup {
  const _MemberGroup(this.detail);

  final CollectionDetail detail;
}

/// One waiting item on the Claims tab: what a member reported from their
/// payment link, so the treasurer can confirm it.
class _ClaimRow {
  const _ClaimRow(this.collection, this.member);

  final CollectionSummary collection;
  final Member member;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<CollectionSummary>> _future = _load();
  late Future<List<_MemberGroup>> _membersFuture = _loadMembers();
  late Future<List<_ClaimRow>> _claimsFuture = _loadClaims();
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;
  String _name = '';
  String _group = '';
  int _tab = 0;

  Future<List<CollectionSummary>> _load() => Api.listCollections();

  /// The Members tab groups people under the collection they belong to, so
  /// a treasurer sees one section per chama instead of one long list.
  Future<List<_MemberGroup>> _loadMembers() async {
    final collections = await Api.listCollections();
    final groups = <_MemberGroup>[];
    for (final c in collections) {
      final detail = await Api.getCollection(c.id);
      if (detail.members.isNotEmpty) {
        groups.add(_MemberGroup(detail));
      }
    }
    return groups;
  }

  /// Every member who reported something from their payment link, waiting
  /// for the treasurer to confirm or dismiss it.
  Future<List<_ClaimRow>> _loadClaims() async {
    final collections = await Api.listCollections();
    final rows = <_ClaimRow>[];
    for (final c in collections) {
      final detail = await Api.getCollection(c.id);
      for (final m in detail.members) {
        if (m.hasClaim) rows.add(_ClaimRow(c, m));
      }
    }
    return rows;
  }

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: AppMotion.slow,
      vsync: this,
    );
    _fabScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
    );
    _fabController.forward();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await Api.loadProfile();
    if (mounted) {
      setState(() {
        _name = profile['name'] ?? '';
        _group = profile['group'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _future = _load();
      _membersFuture = _loadMembers();
      _claimsFuture = _loadClaims();
    });
    // Swallow the error here: the FutureBuilder renders it, and an unhandled
    // rejection would otherwise surface as a red screen in debug.
    await _future.catchError((_) => <CollectionSummary>[]);
  }

  /// Opens the create form and refreshes when a collection was actually made.
  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(_createRoute());
    if (created == true && mounted) {
      await _refresh();
      if (!mounted) return;
      showSuccessSnack(context, 'Collection added to your list');
    }
  }

  /// Shared slide-up route into a collection's live list.
  Future<void> _openLive(int id) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => LiveListScreen(collectionId: id),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: animation, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    _refresh();
  }

  Future<void> _logout() async {
    await AuthState.signOut();
  }

  void _goTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    if (index == 2) {
      setState(() => _membersFuture = _loadMembers());
    } else if (index == 3) {
      setState(() => _claimsFuture = _loadClaims());
    }
  }

  String get _groupLabel => _group.isEmpty ? 'My Group' : _group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: switch (_tab) {
        0 => _homeTab(),
        1 => _collectionsTab(),
        2 => _membersTab(),
        _ => _claimsTab(),
      },
      bottomNavigationBar: _HomeNavBar(tab: _tab, onChanged: _goTab),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _tab == 0 || _tab == 1
          ? ScaleTransition(
              scale: _fabScale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton.icon(
                  icon: const Icon(Icons.add, size: 22),
                  label: const Text('New Collection',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    shadowColor: kPrimary.withValues(alpha: 0.4),
                  ),
                  onPressed: _openCreate,
                ),
              ),
            )
          : null,
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────

  Widget _homeTab() {
    return Column(
      children: [
        _HomeHeader(name: _name, group: _group, onLogout: _logout),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: kPrimary,
            child: AppConstrained(
              child: FutureBuilder<List<CollectionSummary>>(
                future: _future,
                builder: (context, snap) {
                  final collections = snap.data;
                  if (collections == null) {
                    if (snap.hasError) {
                      return _ErrorState(
                        message: friendlyError(snap.error!),
                        onRetry: _refresh,
                      );
                    }
                    return _buildLoadingState();
                  }
                  if (collections.isEmpty) {
                    return _EmptyState(onCreate: _openCreate);
                  }
                  return _collectionList(collections, featured: true);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _collectionsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 16),
          color: kPrimaryDark,
          child: const Text(
            'All Collections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: kPrimary,
            child: AppConstrained(
              child: FutureBuilder<List<CollectionSummary>>(
                future: _future,
                builder: (context, snap) {
                  final collections = snap.data;
                  if (collections == null) {
                    if (snap.hasError) {
                      return _ErrorState(
                        message: friendlyError(snap.error!),
                        onRetry: _refresh,
                      );
                    }
                    return _buildLoadingState();
                  }
                  if (collections.isEmpty) {
                    return _EmptyState(onCreate: _openCreate);
                  }
                  return _collectionList(collections, featured: false);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _membersTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 18, 20, 16),
          color: kPrimaryDark,
          child: const Text(
            'Members',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: kPrimary,
            child: AppConstrained(
              child: FutureBuilder<List<_MemberGroup>>(
                future: _membersFuture,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _ErrorState(
                      message: friendlyError(snap.error!),
                      onRetry: () =>
                          setState(() => _membersFuture = _loadMembers()),
                    );
                  }
                  final groups = snap.data;
                  if (groups == null) {
                    return _buildLoadingState();
                  }
                  if (groups.isEmpty) {
                    return const _EmptyMembers();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    children: [
                      for (var gi = 0; gi < groups.length; gi++) ...[
                        _MemberGroupHeader(group: groups[gi]),
                        const SizedBox(height: 8),
                        for (var mi = 0;
                            mi < groups[gi].detail.members.length;
                            mi++) ...[
                          _MemberTile(
                            member: groups[gi].detail.members[mi],
                            onTap: () => _openMember(
                              groups[gi].detail,
                              groups[gi].detail.members[mi],
                            ),
                          ),
                          if (mi != groups[gi].detail.members.length - 1)
                            const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 18),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the member sheet (same one the live list uses) and refreshes the
  /// groups when something was changed from it.
  Future<void> _openMember(CollectionDetail detail, Member member) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberDetailSheet(
        member: member,
        collectionTitle: detail.summary.title,
        amountLabel: Format.kes(detail.summary.amount),
      ),
    );
    if (changed == true && mounted) {
      setState(() => _membersFuture = _loadMembers());
    }
  }

  /// The Claims tab: everything members reported from their payment links.
  Widget _claimsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.paddingOf(context).top + 18, 20, 16),
          color: kPrimaryDark,
          child: const Text(
            'Claims',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: kPrimary,
            child: AppConstrained(
              child: FutureBuilder<List<_ClaimRow>>(
                future: _claimsFuture,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _ErrorState(
                      message: friendlyError(snap.error!),
                      onRetry: () =>
                          setState(() => _claimsFuture = _loadClaims()),
                    );
                  }
                  final rows = snap.data;
                  if (rows == null) {
                    return _buildLoadingState();
                  }
                  if (rows.isEmpty) {
                    return const _EmptyClaims();
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 2),
                        child: Text(
                          '${rows.length} waiting for you',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kMuted,
                          ),
                        ),
                      ),
                      for (var i = 0; i < rows.length; i++) ...[
                        _ClaimTile(
                          row: rows[i],
                          onDecide: (approve) =>
                              _resolveClaim(rows[i], approve: approve),
                        ),
                        if (i != rows.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Approves (mark as paid) or rejects a claim from the Claims tab.
  Future<void> _resolveClaim(_ClaimRow row, {required bool approve}) async {
    try {
      await Api.resolveClaim(row.member.id, approve: approve);
      if (!mounted) return;
      setState(() => _claimsFuture = _loadClaims());
      final status = row.member.claimStatus;
      final message = !approve
          ? 'Claim rejected'
          : (status == 'issue' || status == 'cancelled')
              ? 'Dismissed'
              : 'Marked as Paid';
      showSuccessSnack(context, message);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  /// The list body. [featured] lifts the first collection into the big
  /// summary card and heads the rest with "Other Collections".
  Widget _collectionList(List<CollectionSummary> collections,
      {required bool featured}) {
    final first = featured ? collections.first : null;
    final rest = featured ? collections.skip(1).toList() : collections;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        if (first != null) ...[
          _FeaturedCard(
            collection: first,
            group: _groupLabel,
            onTap: () => _openLive(first.id),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Text(
                'Other Collections',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kBrandInk,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _goTab(1),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: kPrimary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < rest.length; i++) ...[
          _CollectionTile(
            collection: rest[i],
            group: _groupLabel,
            seed: i,
            onTap: () => _openLive(rest[i].id),
          ),
          if (i != rest.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: List.generate(3, (i) => _CollectionSkeleton(index: i)),
    );
  }
}

/// Big top summary card from the home mockup: name, paid pill, collected vs
/// outstanding and the progress bar.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.collection,
    required this.group,
    required this.onTap,
  });

  final CollectionSummary collection;
  final String group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = collection.memberCount == 0
        ? 0.0
        : (collection.paidCount / collection.memberCount).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final outstanding =
        collection.outstanding < 0 ? 0.0 : collection.outstanding;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005F3C).withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimary, kPrimaryDark],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w900,
                            color: kBrandInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPrimaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${collection.paidCount} / ${collection.memberCount}',
                          style: const TextStyle(
                            color: kPrimaryDark,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount Collected',
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Format.kes(collection.collected),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 42, color: kHairline),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outstanding',
                          style: TextStyle(
                              fontSize: 12.5, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Format.kes(outstanding),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: kAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (outstanding > 0)
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: kAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.priority_high,
                                    size: 15, color: Colors.white),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: kPrimaryLight,
                        valueColor: const AlwaysStoppedAnimation(kPrimary),
                        semanticsLabel:
                            '${collection.paidCount} of ${collection.memberCount} paid',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean list card from the mockup: icon, name, paid line with mini bar,
/// collected amount and a chevron.
class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.collection,
    required this.group,
    required this.seed,
    required this.onTap,
  });

  final CollectionSummary collection;
  final String group;
  final int seed;
  final VoidCallback onTap;

  static IconData _iconFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('school') || t.contains('fees')) return Icons.school_outlined;
    if (t.contains('christmas') || t.contains('fund')) {
      return t.contains('christmas') ? Icons.card_giftcard : Icons.savings_outlined;
    }
    if (t.contains('emergency')) return Icons.health_and_safety_outlined;
    if (t.contains('phone')) return Icons.phone_iphone_outlined;
    if (t.contains('welfare') || t.contains('monthly')) {
      return Icons.groups_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final progress = collection.memberCount == 0
        ? 0.0
        : (collection.paidCount / collection.memberCount).clamp(0.0, 1.0);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kHairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimary, kPrimaryDark],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(collection.title),
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: kBrandInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${collection.paidCount} / ${collection.memberCount} Paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 140,
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: kHairline),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(color: kPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Format.kes(collection.collected),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Collected',
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header on the Members tab: the collection its members pay into,
/// with the paid count and a member-count pill.
class _MemberGroupHeader extends StatelessWidget {
  const _MemberGroupHeader({required this.group});

  final _MemberGroup group;

  @override
  Widget build(BuildContext context) {
    final s = group.detail.summary;
    final memberNoun = s.memberCount == 1 ? 'member' : 'members';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimary, kPrimaryDark],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryDark,
                  ),
                ),
                Text(
                  '${s.paidCount} of ${s.memberCount} paid',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kSoftGreen),
            ),
            child: Text(
              '${s.memberCount} $memberNoun',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kPrimaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One member on the Members tab.
class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, this.onTap});

  final Member member;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final paid = m.isPaid;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: Text(
              m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: kPrimaryDark,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kBrandInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: paid
                  ? kPrimary.withValues(alpha: 0.12)
                  : kAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paid ? 'Paid' : 'Unpaid',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: paid ? kPrimaryDark : kAccentDark,
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

/// Bottom tabs from the mockup: Home | Collections | Members.
class _HomeNavBar extends StatelessWidget {
  const _HomeNavBar({required this.tab, required this.onChanged});

  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(int index, IconData icon, IconData activeIcon, String label) {
      final active = tab == index;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 23,
                  color: active ? kPrimary : kMuted,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? kPrimary : kMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: kHairline)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
            item(1, Icons.list_alt, Icons.list_alt_rounded, 'Collections'),
            item(2, Icons.people_outline, Icons.people_rounded, 'Members'),
            item(3, Icons.assignment_outlined,
                Icons.assignment_turned_in_outlined, 'Claims'),
          ],
        ),
      ),
    );
  }
}

/// Deep green gradient header: white logo, "My Collections", the group name
/// and the secretary's avatar, matching the home mockup.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.group,
    required this.onLogout,
  });

  final String name;
  final String group;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 14, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(height: 30, onDark: true),
              const Spacer(),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Logout',
                icon: const Icon(Icons.logout, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 6),
              Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: name.isNotEmpty
                        ? Text(
                            Format.initial(name),
                            style: const TextStyle(
                              color: kPrimaryDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          )
                        : const Icon(Icons.person, color: kPrimary, size: 22),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FE7AE),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'My Collections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.groups_outlined, color: kSoftGreen, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  group.isEmpty ? 'My Group' : group,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kSoftGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionSkeleton extends StatefulWidget {
  const _CollectionSkeleton({required this.index});
  final int index;

  @override
  State<_CollectionSkeleton> createState() => _CollectionSkeletonState();
}

class _CollectionSkeletonState extends State<_CollectionSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE5E7EB),
                      const Color(0xFFD1D5DB),
                      const Color(0xFFE5E7EB),
                    ],
                    stops: [
                      _shimmer.value - 0.3,
                      _shimmer.value,
                      _shimmer.value + 0.3,
                    ].map((v) => v.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimary.withValues(alpha: 0.15),
                    kPrimary.withValues(alpha: 0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(Icons.receipt_long_outlined, size: 60, color: kPrimary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No collections yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kBrandInk),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your first collection and\nstop asking "Umelipa?"',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Collection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMembers extends StatelessWidget {
  const _EmptyMembers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 56, color: kPrimary),
            SizedBox(height: 16),
            Text(
              'No members yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kBrandInk),
            ),
            SizedBox(height: 8),
            Text(
              'Members appear here once you\ncreate a collection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// One claim on the Claims tab: who reported what, with the treasurer's
/// decisions (mark as paid / reject, or dismiss notices).
class _ClaimTile extends StatelessWidget {
  const _ClaimTile({required this.row, required this.onDecide});

  final _ClaimRow row;
  final ValueChanged<bool> onDecide;

  (String, Color) get _chip => switch (row.member.claimStatus) {
        'claimed' => ('Claimed paid', kPrimaryDark),
        'partial' => ('Partial payment', kAccentDark),
        'cancelled' => ('Cancelled', kMuted),
        'issue' => ('Issue raised', kDanger),
        _ => ('Claim', kMuted),
      };

  @override
  Widget build(BuildContext context) {
    final m = row.member;
    final s = row.collection;
    final (chipLabel, chipColor) = _chip;
    final pending = m.claimStatus == 'claimed' || m.claimStatus == 'partial';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: kPrimaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  Format.initial(m.displayName),
                  style: const TextStyle(
                    color: kPrimaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.displayName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: kBrandInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.title} · ${Format.kes(s.amount)}',
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
          if (m.claimAmount != null ||
              m.claimCode != null ||
              m.claimNote != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.claimAmount != null)
                    Text(
                      'Claimed: ${Format.kes(m.claimAmount!)} of ${Format.kes(s.amount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kBrandInk,
                      ),
                    ),
                  if (m.claimCode != null) ...[
                    if (m.claimAmount != null) const SizedBox(height: 4),
                    Text(
                      'M-Pesa code: ${m.claimCode}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kBrandInk,
                      ),
                    ),
                  ],
                  if (m.claimNote != null) ...[
                    if (m.claimAmount != null || m.claimCode != null)
                      const SizedBox(height: 4),
                    Text(
                      m.claimNote!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (pending) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onDecide(true),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Mark as Paid',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => onDecide(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kDanger,
                    side: BorderSide(
                        color: kDanger.withValues(alpha: 0.5), width: 1.4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                  ),
                  child: const Text('Reject',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onDecide(true),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Dismiss',
                        style: TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryDark,
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyClaims extends StatelessWidget {
  const _EmptyClaims();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_turned_in_outlined,
                  size: 40, color: kPrimaryDark),
            ),
            const SizedBox(height: 16),
            const Text(
              'No claims yet',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: kBrandInk),
            ),
            const SizedBox(height: 8),
            const Text(
              'When members submit a payment from their\nlink, it waits for you here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: kMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.error_outline, size: 40, color: kDanger),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: kBrandInk),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
