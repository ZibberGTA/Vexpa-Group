import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/features/favourites/services/favourites_query_support.dart';
import 'package:nightlife_app/features/favourites/services/favourites_service.dart';

void main() {
  group('FavouritesQuerySupport', () {
    test('builds deterministic document id', () {
      expect(
        FavouritesQuerySupport.docIdFor('guest-1', 'venue-42'),
        'guest-1_venue-42',
      );
    });

    test('returns false when favourite is missing from snapshot', () {
      expect(
        FavouritesQuerySupport.isFavouriteInSnapshot(
          const [
            {'userId': 'guest-1', 'venueId': 'other-venue'},
          ],
          'venue-42',
        ),
        isFalse,
      );
    });

    test('returns true when favourite exists in snapshot', () {
      expect(
        FavouritesQuerySupport.isFavouriteInSnapshot(
          const [
            {'userId': 'guest-1', 'venueId': 'venue-42'},
          ],
          'venue-42',
        ),
        isTrue,
      );
    });

    test('filters requested doc ids to owned ids only', () {
      expect(
        FavouritesQuerySupport.filterOwnedDocIds(
          ['guest-1_a', 'guest-1_b', 'other-user_c'],
          ['guest-1_a', 'guest-1_b'],
        ),
        {'guest-1_a', 'guest-1_b'},
      );
    });
  });

  group('FavouritesService.isFavouriteStreamForUser', () {
    List<Map<String, dynamic>> docsForVenues(List<String> venueIds) {
      return venueIds
          .map(
            (venueId) => {'userId': 'user-1', 'venueId': venueId},
          )
          .toList();
    }

    test('emits false when no matching favourite exists', () async {
      final stream = FavouritesService.isFavouriteStreamForUser(
        authChanges: Stream.value(_FakeUser('user-1')),
        ownerFavouriteDocs: (_) => Stream.value(docsForVenues(['other-venue'])),
        venueId: 'venue-42',
      );

      await expectLater(stream, emits(false));
    });

    test('emits true when favourite exists for venue', () async {
      final stream = FavouritesService.isFavouriteStreamForUser(
        authChanges: Stream.value(_FakeUser('user-1')),
        ownerFavouriteDocs: (_) => Stream.value(docsForVenues(['venue-42'])),
        venueId: 'venue-42',
      );

      await expectLater(stream, emits(true));
    });

    test('emits false when signed out', () async {
      final stream = FavouritesService.isFavouriteStreamForUser(
        authChanges: Stream.value(null),
        ownerFavouriteDocs: (_) => const Stream.empty(),
        venueId: 'venue-42',
      );

      await expectLater(stream, emits(false));
    });

    test('rebinds stream when auth user changes', () async {
      final authController = StreamController<User?>();

      final stream = FavouritesService.isFavouriteStreamForUser(
        authChanges: authController.stream,
        ownerFavouriteDocs: (userId) {
          if (userId == 'guest-1') {
            return Stream.value(docsForVenues(['venue-42']));
          }
          return Stream.value(docsForVenues([]));
        },
        venueId: 'venue-42',
      );

      final values = <bool>[];
      final subscription = stream.listen(values.add);

      authController.add(_FakeUser('guest-1'));
      await pumpEventQueue();
      authController.add(_FakeUser('registered-1'));
      await pumpEventQueue();

      expect(values, [true, false]);

      await subscription.cancel();
      await authController.close();
    });
  });

  group('FavouritesService ownership helpers', () {
    test('anonymous user favourite doc id stays deterministic', () {
      const userId = 'anon-uid-123';
      const venueId = 'pub-1';

      expect(
        FavouritesQuerySupport.docIdFor(userId, venueId),
        '${userId}_$venueId',
      );
    });

    test('cross-user doc ids are excluded from owned delete set', () {
      const currentUserId = 'guest-1';
      const otherUserId = 'guest-2';
      const venueId = 'venue-42';

      final ownedIds = [
        FavouritesQuerySupport.docIdFor(currentUserId, venueId),
      ];
      final requestedIds = [
        FavouritesQuerySupport.docIdFor(currentUserId, venueId),
        FavouritesQuerySupport.docIdFor(otherUserId, venueId),
      ];

      expect(
        FavouritesQuerySupport.filterOwnedDocIds(requestedIds, ownedIds),
        {FavouritesQuerySupport.docIdFor(currentUserId, venueId)},
      );
    });

    test('registered user favourite doc id stays deterministic', () {
      const userId = 'registered-user-456';
      const venueId = 'club-9';

      expect(
        FavouritesQuerySupport.docIdFor(userId, venueId),
        'registered-user-456_club-9',
      );
    });
  });
}

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
