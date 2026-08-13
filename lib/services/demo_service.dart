import '../models/member.dart';
import 'hive_service.dart';
import 'contribution_service.dart';

/// Offline demo data so the app is fully explorable without a connection.
///
/// Seeds five workspaces (Umoja Chama, Mwema SACCO, Riverside Welfare, Sunrise
/// Academy, Kipchoge Burial Group) with their member rosters and contribution
/// campaigns. `seed()` is idempotent — repeated calls never duplicate
/// campaigns (each is guarded by `_exists`). Also provides fallback stats and
/// the demo auth profile for [ApiService].
class DemoService {
  static const String demoPhone = '254712345678';
  static const String demoPin = '1234';
  static const String demoWorkspaceId = 'demo-ws-001';

  static Map<String, dynamic> _rawWorkspace(
      String id,
      String name,
      String type,
      int contribution,
      Map rails,
      String till,
      String paybill,
      String account) {
    return {
      'id': id,
      'name': name,
      'type': type,
      'contribution': contribution,
      'rails': rails,
      'till_number': till,
      'paybill_number': paybill,
      'account_number': account,
      'created_at': DateTime.now().toIso8601String(),
      'image': OrgRules.imageFor(type),
    };
  }

  static List<Map> demoWorkspaces() {
    return [
      _rawWorkspace(
        demoWorkspaceId,
        'Umoja Chama',
        'Chama',
        5000,
        {'loop': true, 'till': true, 'paybill': false, 'bank': false},
        '9415678',
        '522033',
        '',
      ),
      _rawWorkspace(
        'demo-ws-002',
        'Mwema SACCO',
        'SACCO',
        1200000,
        {'loop': true, 'till': true, 'paybill': true, 'bank': true},
        '123456',
        '100200',
        '0112012345678',
      ),
      _rawWorkspace(
        'demo-ws-003',
        'Riverside Welfare',
        'Welfare',
        85000,
        {'loop': true, 'till': false, 'paybill': true, 'bank': false},
        '',
        '622100',
        '018301234567',
      ),
      _rawWorkspace(
        'demo-ws-004',
        'Sunrise Academy',
        'School',
        12500,
        {'loop': true, 'till': true, 'paybill': true, 'bank': false},
        '773412',
        '552244',
        '',
      ),
      _rawWorkspace(
        'demo-ws-005',
        'Kipchoge Burial Group',
        'Burial Group',
        2000,
        {'loop': true, 'till': false, 'paybill': true, 'bank': false},
        '',
        '722100',
        '0821',
      ),
    ];
  }

  static List<Map<String, String>> _rawMembers(
      String wsPrefix, String orgCode) {
    final names = [
      ['Grace Wanjiku', '254700111222', '5000'],
      ['John Otieno', '254700222333', '3500'],
      ['Faith Chebet', '254700333444', '7500'],
      ['David Mwangi', '254700444555', '2000'],
      ['Mary Achieng', '254700555666', '4200'],
      ['Samuel Kiprop', '254700666777', '6800'],
      ['Esther Njeri', '254700777888', '1500'],
      ['Brian Muli', '254700888999', '9300'],
      ['Ruth Auma', '254700999000', '1100'],
      ['Peter Kamau', '254701111333', '5600'],
      ['Lucy Muthoni', '254701222444', '8800'],
      ['Kevin Omondi', '254701333555', '2500'],
    ];
    return names.asMap().entries.map((e) {
      final i = e.key + 1;
      return {
        'code': '$orgCode$i',
        'name': e.value[0],
        'phone': e.value[1],
        'due': e.value[2],
      };
    }).toList();
  }

  static List<Member> demoMembers(String wsId, String orgCode) {
    return _rawMembers(wsId, orgCode).map((m) {
      final code = m['code']!;
      return Member(
        id: '$wsId-member-$code',
        name: m['name']!,
        phone: m['phone']!,
        memberCode: code,
        balanceDue: double.parse(m['due']!),
        workspaceId: wsId,
      );
    }).toList();
  }

  static Map<String, dynamic> demoStaff() {
    return {
      'id': 'demo-staff-1',
      'name': 'John Mwangi',
      'phone': demoPhone,
      'role': 'treasurer',
      'workspace_ids': [
        demoWorkspaceId,
        'demo-ws-003',
        'demo-ws-004',
      ],
      'workspace': {
        'id': demoWorkspaceId,
        'name': 'Umoja Chama',
        'type': 'Chama',
      },
    };
  }

  /// Boots the demo: writes workspaces + members once, then seeds campaigns,
  /// stores the demo auth session and switches to Umoja Chama. Safe to call
  /// repeatedly (campaign seeds skip titles that already exist).
  static Future<void> seed() async {
    if (HiveService.getWorkspaces().isEmpty) {
      await HiveService.saveWorkspaces(demoWorkspaces());
      await HiveService.cacheMembers(
        demoMembers(demoWorkspaceId, 'TV') +
            demoMembers('demo-ws-002', 'MW') +
            demoMembers('demo-ws-003', 'RV') +
            demoMembers('demo-ws-004', 'SA') +
            demoMembers('demo-ws-005', 'KB'),
      );
    }
    _seedCampaigns();
    await HiveService.saveAuth('demo-token', demoStaff());
    await HiveService.setActiveWorkspace(demoWorkspaceId);
  }

  static bool _exists(String title) =>
      HiveService.getCampaigns().any((c) => c['title'] == title);

  static void _seedCampaigns() {
    final members = HiveService.getMembersForWorkspace(demoWorkspaceId);
    const orgName = 'Umoja Chama';

    // Monthly contribution campaign — some paid full, some partial, some pending
    if (!_exists('August monthly contribution')) {
      final monthly = ContributionService.create(
        title: 'August monthly contribution',
        contribType: 'Regular',
        amount: 5000,
        frequency: 'monthly',
        deadline:
            DateTime.now().add(const Duration(days: 12)).toIso8601String(),
        message:
            'You have to pay Ksh 5000 for $orgName this month. Pay via till 9415678 or LOOP before the deadline.',
        paymentMethod: {'rail': 'till', 'label': 'M-PESA Till 9415678'},
        allowPartial: true,
        minPartial: 1000,
        workspaceId: demoWorkspaceId,
      );
      for (int i = 0; i < members.length && i < 4; i++) {
        ContributionService.recordPayment(
            monthly,
            members[i].id,
            members[i].name,
            members[i].memberCode,
            members[i].phone,
            5000,
            'M-PESA Till 9415678');
      }
      if (members.length >= 6) {
        ContributionService.recordPayment(
            monthly,
            members[5].id,
            members[5].name,
            members[5].memberCode,
            members[5].phone,
            2000,
            'LOOP (NCBA)');
      }
    }

    // School trip campaign — demo of parent payment
    if (!_exists('End-year school trip')) {
      final trip = ContributionService.create(
        title: 'End-year school trip',
        contribType: 'Trip',
        amount: 3500,
        frequency: 'per_event',
        deadline: DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        message:
            "PAY YOUR CHILD'S TRIP — Ksh 3500 for the end-year school trip. Pay before the deadline to secure your child's seat.",
        paymentMethod: {'rail': 'loop', 'label': 'LOOP Request-to-Pay'},
        allowPartial: true,
        minPartial: 1750,
        workspaceId: demoWorkspaceId,
      );
      if (members.length >= 3) {
        ContributionService.recordPayment(trip, members[2].id, members[2].name,
            members[2].memberCode, members[2].phone, 3500, 'LOOP (NCBA)');
      }
    }

    // Emergency burial levy
    if (!_exists('Burial levy — Kiprop family')) {
      final burial = ContributionService.create(
        title: 'Burial levy — Kiprop family',
        contribType: 'Emergency',
        amount: 2000,
        frequency: 'per_event',
        deadline: DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        message:
            'EMERGENCY COLLECTION — $orgName has raised a 2000 levy for the Kiprop family. Please contribute what you can before the deadline.',
        paymentMethod: {'rail': 'paybill', 'label': 'Paybill 522033 · Acc 001'},
        allowPartial: true,
        minPartial: 200,
        workspaceId: demoWorkspaceId,
      );
      for (int i = 4; i < members.length && i < 8; i++) {
        ContributionService.recordPayment(
            burial,
            members[i].id,
            members[i].name,
            members[i].memberCode,
            members[i].phone,
            2000,
            'Paybill 522033');
      }
    }

    // School — Sunrise Academy trip (parents)
    final schoolMembers = HiveService.getMembersForWorkspace('demo-ws-004');
    if (schoolMembers.isNotEmpty && !_exists('Class 8 end-year trip')) {
      final schoolTrip = ContributionService.create(
        title: 'Class 8 end-year trip',
        contribType: 'Trip',
        amount: 12500,
        frequency: 'per_event',
        deadline:
            DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        message:
            "PAY YOUR CHILD'S TRIP — Ksh 12,500 for the Class 8 end-year trip. Minimum 50% now, balance before departure.",
        paymentMethod: {
          'rail': 'paybill',
          'label': 'Paybill 552244 · Acc 2024'
        },
        allowPartial: true,
        minPartial: 6250,
        workspaceId: 'demo-ws-004',
      );
      for (int i = 0; i < schoolMembers.length && i < 6; i++) {
        ContributionService.recordPayment(
            schoolTrip,
            schoolMembers[i].id,
            schoolMembers[i].name,
            schoolMembers[i].memberCode,
            schoolMembers[i].phone,
            12500,
            'Paybill 552244');
      }
      if (schoolMembers.length >= 8) {
        ContributionService.recordPayment(
            schoolTrip,
            schoolMembers[7].id,
            schoolMembers[7].name,
            schoolMembers[7].memberCode,
            schoolMembers[7].phone,
            6250,
            'LOOP (NCBA)');
      }
    }

    // Loan repayment campaign — members repaying borrowed funds with proof
    if (!_exists('Loan repayment — Peter Kamau')) {
      final loan = ContributionService.create(
        title: 'Loan repayment — Peter Kamau',
        contribType: 'Loan',
        amount: 15000,
        frequency: 'monthly',
        deadline:
            DateTime.now().add(const Duration(days: 20)).toIso8601String(),
        message:
            'Umoja Chama loan repayment — Ksh 15,000 due this month for the loan taken by Peter Kamau. Repay before the deadline.',
        paymentMethod: {'rail': 'till', 'label': 'M-PESA Till 9415678'},
        allowPartial: true,
        minPartial: 2000,
        workspaceId: demoWorkspaceId,
      );
      if (members.length >= 2) {
        ContributionService.recordPayment(
            loan,
            members[1].id,
            members[1].name,
            members[1].memberCode,
            members[1].phone,
            8000,
            'M-PESA Till 9415678',
            verified: false);
      }
      if (members.length >= 4) {
        ContributionService.recordPayment(loan, members[3].id, members[3].name,
            members[3].memberCode, members[3].phone, 15000, 'LOOP (NCBA)');
      }
      if (members.length >= 9) {
        ContributionService.recordPayment(
            loan,
            members[8].id,
            members[8].name,
            members[8].memberCode,
            members[8].phone,
            5000,
            'M-PESA Till 9415678',
            verified: false);
      }
    }

    // SACCO — Mwema monthly shares (no partials)
    final saccoMembers = HiveService.getMembersForWorkspace('demo-ws-002');
    if (saccoMembers.isNotEmpty && !_exists('August monthly shares')) {
      final shares = ContributionService.create(
        title: 'August monthly shares',
        contribType: 'Regular',
        amount: 1000,
        frequency: 'monthly',
        deadline: DateTime.now().add(const Duration(days: 8)).toIso8601String(),
        message:
            'MWEMA SACCO — your monthly share of Ksh 1,000 is due. Shares must be paid in full by the deadline.',
        paymentMethod: {'rail': 'till', 'label': 'M-PESA Till 123456'},
        allowPartial: false,
        minPartial: 1000,
        workspaceId: 'demo-ws-002',
      );
      for (int i = 0; i < saccoMembers.length && i < 7; i++) {
        ContributionService.recordPayment(
            shares,
            saccoMembers[i].id,
            saccoMembers[i].name,
            saccoMembers[i].memberCode,
            saccoMembers[i].phone,
            1000,
            'M-PESA Till 123456');
      }
    }

    // Burial Group — Kipchoge emergency levy
    final burialMembers = HiveService.getMembersForWorkspace('demo-ws-005');
    if (burialMembers.isNotEmpty &&
        !_exists('Emergency levy — Mzee Kipchoge')) {
      final levy = ContributionService.create(
        title: 'Emergency levy — Mzee Kipchoge',
        contribType: 'Emergency',
        amount: 2000,
        frequency: 'per_event',
        deadline: DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        message:
            'EMERGENCY — Mzee Kipchoge needs hospital support. Contribution of Ksh 2,000, pay what you can before the deadline.',
        paymentMethod: {
          'rail': 'paybill',
          'label': 'Paybill 722100 · Acc 0821'
        },
        allowPartial: true,
        minPartial: 200,
        workspaceId: 'demo-ws-005',
      );
      for (int i = 0; i < burialMembers.length && i < 9; i++) {
        ContributionService.recordPayment(
            levy,
            burialMembers[i].id,
            burialMembers[i].name,
            burialMembers[i].memberCode,
            burialMembers[i].phone,
            2000,
            'Paybill 722100');
      }
    }
  }

  static String _fmt(num n) {
    final s = n.toStringAsFixed(n == n.roundToDouble() ? 0 : 2);
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  static Map<String, dynamic> stats() {
    final ws = HiveService.getActiveWorkspace() ?? demoStaff()['workspace'];
    final wsId = ws['id'];
    final members = HiveService.getMembersForWorkspace(wsId);
    final pending =
        HiveService.getPendingEvents().where((e) => e.workspaceId == wsId);
    final pendingAmount = pending.fold(0.0, (sum, e) => sum + e.amount);
    final totalDue = members.fold(0.0, (sum, m) => sum + m.balanceDue);
    final collections = members.length * (ws['contribution'] ?? 5000).toInt();

    return {
      'today': {
        'collections': members.length,
        'revenue': members.length * 500,
        'subtitle': 'from ${members.length} members',
      },
      'this_week': {
        'collections': members.length + 2,
        'revenue': members.length * 500 + 3000,
        'subtitle': 'this week',
      },
      'total_members': members.length,
      'active_members': members.length,
      'expected_monthly': collections,
      'expected_subtitle': 'expected this month',
      'pending_balance': pendingAmount > 0 ? pendingAmount : totalDue / 2,
      'pending_subtitle': 'outstanding balances',
      'recent_events': members
          .take(6)
          .map((m) => {
                'member_name': m.name,
                'event_type': 'Payment · SMS receipt',
                'amount': m.balanceDue > 0 ? m.balanceDue / 8 : 500,
                'created_at': 'Just now',
              })
          .toList(),
    };
  }

  static bool drainThresholdMet() {
    final ws = HiveService.getActiveWorkspace();
    if (ws == null) return true;
    // Demo flag: pretend collection target reached so treasurer can sync receipts
    return HiveService.getPendingEvents()
        .where((e) => e.workspaceId == (ws['id'] ?? ''))
        .isNotEmpty;
  }

  static String formatKsh(num v) => 'Ksh ${_fmt(v.round())}';

  static String formatNumber(num v) => _fmt(v);
}
