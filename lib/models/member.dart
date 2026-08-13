import 'package:hive/hive.dart';

part 'member.g.dart';

/// A group member stored in the local Hive box.
///
/// Members belong to a [workspaceId] (the contributory group / org) and carry a
/// short human [memberCode] (e.g. `TV1`) plus their latest [balanceDue].
/// Persisted so Treasurer can verify payments fully offline.
@HiveType(typeId: 1)
class Member {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String memberCode;

  @HiveField(4)
  final double balanceDue;

  @HiveField(5)
  final String workspaceId;

  /// Lifecycle status: invited → active → suspended → reinstated / left / banned.
  @HiveField(6)
  final String status;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.memberCode,
    required this.balanceDue,
    required this.workspaceId,
    this.status = 'active',
  });

  static const List<String> lifecycle = [
    'invited',
    'active',
    'suspended',
    'left',
    'banned',
  ];

  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get canContribute => isActive || status == 'invited';

  Member copyWith({double? balanceDue, String? status}) {
    return Member(
      id: id,
      name: name,
      phone: phone,
      memberCode: memberCode,
      balanceDue: balanceDue ?? this.balanceDue,
      workspaceId: workspaceId,
      status: status ?? this.status,
    );
  }

  /// Rebuilds a [Member] from the API JSON shape (`member_code`, `balance_due`,
  /// `workspace`). Missing/absent keys safely fall back to defaults.
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      memberCode: json['member_code'] ?? '',
      balanceDue:
          double.tryParse(json['balance_due']?.toString() ?? '0') ?? 0.0,
      workspaceId: json['workspace'] ?? '',
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'member_code': memberCode,
        'balance_due': balanceDue,
        'workspace': workspaceId,
        'status': status,
      };
}
