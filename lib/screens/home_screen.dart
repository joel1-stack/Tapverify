import 'package:flutter/material.dart';

import '../api.dart';
import '../main.dart';
import '../models.dart' show CollectionSummary;
import '../utils/format.dart';
import '../widgets/app_feedback.dart';
import '../widgets/responsive.dart';
import 'create_collection_screen.dart';
import 'live_list_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<CollectionSummary>> _future = _load();
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  Future<List<CollectionSummary>> _load() => Api.listCollections();

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
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _future = _load());
    // Swallow the error here: the FutureBuilder renders it, and an unhandled
    // rejection would otherwise surface as a red screen in debug.
    await _future.catchError((_) => <CollectionSummary>[]);
  }

  /// Opens the create form and refreshes when a collection was actually made.
  ///
  /// The form used to `pushReplacement` to the live list without popping a
  /// result, so this future always completed with null and the new collection
  /// stayed invisible until a manual pull to refresh.
  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(_createRoute());
    if (created == true && mounted) {
      await _refresh();
      if (!mounted) return;
      showSuccessSnack(context, 'Collection added to your list');
    }
  }

  Future<void> _logout() async {
    await AuthState.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('My Collections',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Color(0xFF111827))),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF6B7280)),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: kPrimary,
        child: AppConstrained(
          child: FutureBuilder<List<CollectionSummary>>(
          future: _future,
          builder: (context, snap) {
            // Keep showing the collections we already have while a refresh is
            // in flight; only a first load shows the skeleton.
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
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              itemCount: collections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _CollectionCard(
                key: ValueKey<int>(collections[i].id),
                collection: collections[i],
                index: i,
                onChanged: _refresh,
              ),
            );
          },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.add, size: 22),
            label: const Text('New Collection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              shadowColor: kPrimary.withValues(alpha: 0.4),
            ),
            onPressed: _openCreate,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: List.generate(3, (i) => _CollectionSkeleton(index: i)),
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

class _CollectionCard extends StatefulWidget {
  const _CollectionCard({
    super.key,
    required this.collection,
    required this.index,
    required this.onChanged,
  });

  final CollectionSummary collection;
  final int index;
  final VoidCallback onChanged;

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + widget.index * 80),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    final progress = collection.memberCount == 0
        ? 0.0
        : collection.paidCount / collection.memberCount;

    return SlideTransition(
      position: _slideAnimation,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _hovered ? const Color(0xFF0D9488) : const Color(0xFFE5E7EB),
                width: _hovered ? 2 : 1,
              ),
              boxShadow: _hovered ? [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                await Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => LiveListScreen(collectionId: collection.id),
                    transitionsBuilder: (_, animation, __, child) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
                widget.onChanged();
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: collection.completed
                                  ? [kSuccess, kSuccess.withValues(alpha: 0.7)]
                                  : [kPrimary, kPrimary.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            collection.completed ? Icons.check_circle_outline : Icons.receipt_long_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                collection.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              if (collection.completed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kSuccess.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: kSuccess,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MiniStat(
                          label: 'Paid',
                          value: '${collection.paidCount}/${collection.memberCount}',
                          color: kPrimary,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          label: 'Collected',
                          value: Format.kes(collection.collected),
                          color: kSuccess,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          label: 'Outstanding',
                          value: Format.kes(
                              collection.outstanding < 0 ? 0 : collection.outstanding),
                          color: collection.outstanding > 0 ? kDanger : kSuccess,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: kHairline,
                        valueColor: const AlwaysStoppedAnimation(kPrimary),
                        semanticsLabel:
                            '${collection.paidCount} of ${collection.memberCount} paid',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
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
                  colors: [kPrimary.withValues(alpha: 0.15), kPrimary.withValues(alpha: 0.05)],
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            Text(
              'Create your first collection and\nstop asking "Umelipa?"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Collection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
