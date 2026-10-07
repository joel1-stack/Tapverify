import 'package:flutter_test/flutter_test.dart';
import 'package:tapverify/demo.dart';

/// The shareable APK runs on this in-memory backend, so the whole journey a
/// tester takes (OTP -> home -> open a collection -> export) must work with
/// no server behind it.
void main() {
  test('demo OTP login returns a shown code and a session token', () {
    final result = Demo.instance.requestOtp('0715641339');
    expect(result['sent'], true);
    final code = result['dev_code'] as String;
    expect(code, hasLength(6));

    expect(
      () => Demo.instance.verifyOtp('0715641339', '000000'),
      throwsA(isA<Exception>()),
    );

    final token = Demo.instance.verifyOtp('0715641339', code);
    expect(token, isNotEmpty);
    // The universal fallback also works so testers never get stuck.
    expect(Demo.instance.verifyOtp('0715641339', '123456'), isNotEmpty);
  });

  test('demo collections match the numbers on the app design', () async {
    Demo.instance.requestOtp('0715641339');
    Demo.instance.verifyOtp('0715641339', '123456');

    final list = Demo.instance.listCollections();
    expect(list, hasLength(5));

    final monthly = list.firstWhere((c) => c.title == 'Monthly Savings');
    expect(monthly.paidCount, 18);
    expect(monthly.memberCount, 40);
    expect(monthly.collected, 9000);

    final detail = Demo.instance.getCollection(monthly.id);
    expect(detail.members, hasLength(40));
    expect(detail.members.where((m) => m.isPaid), hasLength(18));
    expect(detail.members.every((m) => m.phone.isNotEmpty), isTrue);

    final csv = Demo.instance.exportCsv(monthly.id);
    expect(csv, isNotEmpty);
  });

  test('demo lets a tester create a collection and see it in the list', () {
    Demo.instance.requestOtp('0715641339');
    Demo.instance.verifyOtp('0715641339', '123456');

    final before = Demo.instance.listCollections().length;
    final created = Demo.instance.createCollection(
      title: 'Test Chama',
      amount: '300',
      payoutMethod: 'personal',
      membersText: 'Wanjiku Kamau - 0722000111\n0733444555',
    );
    expect(created.summary.title, 'Test Chama');
    expect(Demo.instance.listCollections(), hasLength(before + 1));
  });

  test('payment link claims reach the treasurer and can be settled', () {
    Demo.instance.requestOtp('0715641339');
    Demo.instance.verifyOtp('0715641339', '123456');

    final detail = Demo.instance.getCollection(1);
    // The seeded data ships with claims so the Claims tab is never empty.
    expect(detail.members.where((m) => m.claimStatus == 'claimed'), isNotEmpty);
    expect(detail.members.where((m) => m.claimStatus == 'partial'), isNotEmpty);
    expect(detail.members.where((m) => m.claimStatus == 'issue'), isNotEmpty);
    expect(detail.members.where((m) => m.claimStatus == 'cancelled'), isNotEmpty);

    // A member claims a full payment from their pay link: waits for the
    // treasurer, nobody is paid yet.
    final member =
        detail.members.firstWhere((m) => !m.isPaid && !m.hasClaim);
    Demo.instance.submitClaim(
      member.id,
      status: 'claimed',
      amount: 500,
      code: 'SJ1TEST01',
      note: 'Paid at noon',
    );
    var after = Demo.instance
        .getCollection(1)
        .members
        .firstWhere((m) => m.id == member.id);
    expect(after.claimStatus, 'claimed');
    expect(after.claimCode, 'SJ1TEST01');
    expect(after.isPaid, isFalse);

    // Approving the claim marks the member paid and clears it.
    Demo.instance.resolveClaim(member.id, approve: true);
    after = Demo.instance
        .getCollection(1)
        .members
        .firstWhere((m) => m.id == member.id);
    expect(after.isPaid, isTrue);
    expect(after.hasClaim, isFalse);

    // A partial claim that the treasurer rejects changes nothing.
    final other =
        Demo.instance.getCollection(1).members.firstWhere((m) => !m.isPaid && !m.hasClaim);
    Demo.instance.submitClaim(other.id, status: 'partial', amount: 200, code: 'SJ2TEST02');
    Demo.instance.resolveClaim(other.id, approve: false);
    after = Demo.instance
        .getCollection(1)
        .members
        .firstWhere((m) => m.id == other.id);
    expect(after.isPaid, isFalse);
    expect(after.hasClaim, isFalse);

    // Cancelling from the link is recorded so the treasurer can see it.
    final cancelled =
        Demo.instance.getCollection(1).members.firstWhere((m) => !m.isPaid && !m.hasClaim);
    Demo.instance.submitClaim(cancelled.id, status: 'cancelled');
    after = Demo.instance
        .getCollection(1)
        .members
        .firstWhere((m) => m.id == cancelled.id);
    expect(after.claimStatus, 'cancelled');
    expect(after.isPaid, isFalse);
  });
}
