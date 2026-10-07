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
}
