import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../api.dart';
import '../main.dart';
import '../models.dart';
import '../services/csv_download.dart';
import '../utils/format.dart';
import '../widgets/app_feedback.dart';
import '../widgets/responsive.dart';
import 'member_detail_sheet.dart';

/// `2026-10-31` reads as `31 Oct 2026`; unparseable values fall back to raw.
String _dueLabel(String iso) {
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? iso : Format.dueDate(parsed);
}

class LiveListScreen extends StatefulWidget {
  const LiveListScreen({super.key, required this.collectionId});

  final int collectionId;

  @override
  State<LiveListScreen> createState() => _LiveListScreenState();
}

class _LiveListScreenState extends State<LiveListScreen>
    with SingleTickerProviderStateMixin {
  late Future<CollectionDetail> _future = _load();

  /// The last successful payload. Kept so a refresh never blanks the list, and
  /// so the tail of the list still renders while a new request is in flight.
  CollectionDetail? _detail;

  bool _actionBusy = false;
  late final AnimationController _controller;
  late final CurvedAnimation _progressAnimation;
  double _lastProgress = 0;

  Future<CollectionDetail> _load() => Api.getCollection(widget.collectionId);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _progressAnimation =
        CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    _controller.forward();
    _future.then((detail) {
      if (mounted) setState(() => _detail = detail);
    }).catchError((_) => null);
  }

  @override
  void dispose() {
    _progressAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final next = _load();
    setState(() => _future = next);
    try {
      final detail = await next;
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (_) {
      // The FutureBuilder renders the error; keep the last good list visible.
    }
  }

  Future<void> _remindUnpaid() async {
    setState(() => _actionBusy = true);
    try {
      final sent = await Api.remindUnpaid(widget.collectionId);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
                    ),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(Icons.notifications_active_outlined,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Reminders sent',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reminder sent to $sent people.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
      _refresh();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _shareList(CollectionDetail detail) async {
    final s = detail.summary;
    final buffer = StringBuffer()
      ..writeln('TapVerify: ${s.title}')
      ..writeln('${Format.kes(s.amount)} per person · ${s.payoutLabel}')
      ..writeln('Paid: ${s.paidCount}/${s.memberCount} | '
          'Collected: ${Format.kes(s.collected)} | '
          'Outstanding: ${Format.kes(s.outstanding < 0 ? 0 : s.outstanding)}')
      ..writeln();
    for (final m in detail.members) {
      buffer.writeln(
          '${m.displayName}: ${m.isPaid ? "Paid" : "Not paid"}');
    }
    try {
      await SharePlus.instance
          .share(ShareParams(text: buffer.toString(), subject: s.title));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _download() async {
    setState(() => _actionBusy = true);
    try {
      final bytes = await Api.exportCsv(widget.collectionId);
      final slug = (_detail?.summary.title ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final name = slug.isEmpty ? 'collection-${widget.collectionId}' : slug;
      await downloadCsv(bytes, 'tapverify-$name.csv');
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _openMember(Member member) async {
    final wide = isWideDisplay(context);
    final title = _detail?.summary.title ?? 'Collection';
    final amountLabel = Format.kes(_detail?.summary.amount ?? 0);
    final changed = wide
        ? await showDialog<bool>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: MemberDetailSheet(
                  member: member,
                  asDialog: true,
                  collectionTitle: title,
                  amountLabel: amountLabel,
                ),
              ),
            ),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => MemberDetailSheet(
              member: member,
              collectionTitle: title,
              amountLabel: amountLabel,
            ),
          );
    if (changed == true && mounted) await _refresh();
  }

  void _showError(Object error) {
    showErrorSnack(context, error);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CollectionDetail>(
      future: _future,
      builder: (context, snap) {
        // Prefer the freshest payload, but never blank the screen while a
        // refresh is in flight or after a failed one.
        final detail = snap.data ?? _detail;
        final s = detail?.summary;
        final progress = (s == null || s.memberCount == 0)
            ? 0.0
            : s.paidCount / s.memberCount;
        if (s != null && (progress - _lastProgress).abs() > 0.001) {
          _lastProgress = progress;
          _controller.forward(from: 0);
        }
        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              detail == null ? 'Live List' : detail.summary.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18, color: kBrandInk),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (detail != null) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: IconButton(
                    tooltip: 'Share List',
                    icon: const Icon(Icons.share_outlined, size: 20, color: Color(0xFF6B7280)),
                    onPressed: () => _shareList(detail),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: IconButton(
                    tooltip: 'Download / Print',
                    icon: const Icon(Icons.download_outlined, size: 20, color: Color(0xFF6B7280)),
                    onPressed: _actionBusy ? null : _download,
                  ),
                ),
              ],
            ],
          ),
          body: _buildBody(context, snap, progress),
          bottomNavigationBar: detail == null
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: AppConstrained(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.notifications_active_outlined, size: 20),
                          label: const Text('Send Reminder to Unpaid',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: kAccent.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: kAccent.withValues(alpha: 0.4),
                          ),
                          onPressed: _actionBusy ? null : _remindUnpaid,
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, AsyncSnapshot<CollectionDetail> snap, double progress) {
    final detail = snap.data ?? _detail;

    if (detail == null) {
      if (snap.hasError) {
        return _ErrorState(
          message: friendlyError(snap.error!),
          onRetry: _refresh,
        );
      }
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    final s = detail.summary;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: kPrimary,
      child: AppConstrained(
        wide: 760,
        child: ListView(
        // Keeps the scroll position when the list is replaced after an update.
        key: PageStorageKey<String>('live-list-${widget.collectionId}'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (snap.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RefreshWarning(
                message: friendlyError(snap.error!),
                onRetry: _refresh,
              ),
            ),
          // Stats header card
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // What each person owes, and where they should send it. The
                  // screen used to show totals only, so "wrong amount" had no
                  // reference value anywhere in the app.
                  Text(
                    '${Format.kes(s.amount)} per person · ${s.payoutLabel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.autoDetect
                        ? 'Payments appear here automatically'
                        : 'Mark each payment yourself',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                  if (s.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_outlined, color: Colors.white70, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            'Due ${_dueLabel(s.dueDate!)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderStat(
                          label: 'Paid',
                          value: '${s.paidCount}/${s.memberCount}',
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _HeaderStat(
                          label: 'Collected',
                          value: Format.kes(s.collected),
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _HeaderStat(
                          label: s.outstanding < 0 ? 'Overpaid' : 'Outstanding',
                          value: Format.kes(s.outstanding.abs()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (progress * _progressAnimation.value).clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        semanticsLabel: '${s.paidCount} of ${s.memberCount} paid',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress >= 1
                        ? 'All paid, well done!'
                        : '${(progress * 100).toStringAsFixed(0)}% collected',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Members',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kBrandInk),
                ),
              ),
              if (detail.members.isNotEmpty)
                Text(
                  '${s.paidCount} paid · ${s.memberCount - s.paidCount} pending',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...detail.members.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return FadeSlideIn(
              key: ValueKey<int>(m.id),
              delay: AppMotion.stagger(i),
              duration: AppMotion.medium,
              offset: 14,
              child: _MemberTile(
                member: m,
                expectedAmount: s.amount,
                onTap: () => _openMember(m),
              ),
            );
          }),
        ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.onTap,
    this.expectedAmount,
  });

  final Member member;
  final VoidCallback onTap;

  /// What this person was asked for, so a mismatch has a visible reference.
  final double? expectedAmount;

  @override
  Widget build(BuildContext context) {
    final paid = member.isPaid;
    final subtitle = paid ? _paidSubtitle(member) : member.phone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        decoration: BoxDecoration(
          color: paid ? kSuccess.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: paid ? kSuccess.withValues(alpha: 0.25) : kHairline,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: paid
                            ? [kSuccess.withValues(alpha: 0.2), kSuccess.withValues(alpha: 0.08)]
                            : [Colors.grey.withValues(alpha: 0.15), Colors.grey.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: paid
                            ? kSuccess.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        Format.initial(member.displayName),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: paid ? kSuccess : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (paid ? kSuccess : kDanger).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          paid ? Icons.check_circle : Icons.cancel_outlined,
                          color: paid ? kSuccess : kDanger,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          paid ? 'Paid' : 'Not paid',
                          style: TextStyle(
                              color: paid ? kSuccess : kDanger,
                              fontWeight: FontWeight.w700,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _paidSubtitle(Member m) {
    final method = switch (m.paidMethod) {
      'auto' => 'Auto',
      'cash' => 'Cash',
      'other' => 'Other',
      _ => '',
    };
    final time = Format.timestampFrom(m.paidAt);

    // The list used to append " · wrong amount" unconditionally, so a member
    // with no method and no timestamp rendered a dangling separator.
    final parts = [method, time].where((e) => e.isNotEmpty).toList();
    if (m.amountMismatch) {
      final paidAmount =
          m.paidAmount == null ? null : Format.kes(m.paidAmount);
      final expected = expectedAmount == null ? null : Format.kes(expectedAmount);
      parts.add(paidAmount != null && expected != null
          ? 'wrong amount: $paidAmount of $expected'
          : 'wrong amount');
    }
    return parts.join(' · ');
  }
}

/// Shown when the very first load fails.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 34, color: kDanger),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: kBrandInk, height: 1.5),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown above a stale list when a background refresh failed.
class _RefreshWarning extends StatelessWidget {
  const _RefreshWarning({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5A623)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: Color(0xFFE08E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$message Showing the last known list.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF333333)),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
