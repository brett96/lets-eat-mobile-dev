import 'package:flutter_test/flutter_test.dart';
import 'package:lets_eat/models/group.dart';

Group _group(Map<String, String> votes) => Group(
      id: 'g1',
      name: 'Lunch Crew',
      ownerUid: 'owner',
      memberUids: const ['a', 'b', 'c'],
      votes: votes,
    );

void main() {
  group('Group.winningRestaurantId', () {
    test('returns null with no votes', () {
      expect(_group({}).winningRestaurantId, isNull);
    });

    test('picks the clear majority', () {
      final g = _group({'a': 'r1', 'b': 'r1', 'c': 'r2'});
      expect(g.winningRestaurantId, 'r1');
    });

    test('returns null on a tie', () {
      final g = _group({'a': 'r1', 'b': 'r2'});
      expect(g.winningRestaurantId, isNull);
    });

    test('single vote wins', () {
      expect(_group({'a': 'r9'}).winningRestaurantId, 'r9');
    });
  });

  test('memberCount reflects member list', () {
    expect(_group({}).memberCount, 3);
  });
}
