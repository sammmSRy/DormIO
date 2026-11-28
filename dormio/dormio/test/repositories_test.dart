import 'package:dormio/core/db_exception.dart';
import 'package:dormio/models/dormitory.dart';
import 'package:dormio/models/reservation.dart';
import 'package:dormio/repositories/dormitory_repository.dart';
import 'package:dormio/repositories/message_repository.dart';
import 'package:dormio/repositories/reservation_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Dormitory _dorm({
  String name = 'Test Dorm',
  String city = 'Manila',
  double price = 5000,
  int capacity = 2,
  int slots = 2,
}) =>
    Dormitory(
      ownerId: 'host1',
      name: name,
      address: '123 Test St',
      city: city,
      roomType: RoomType.shared,
      pricePerMonth: price,
      capacity: capacity,
      availableSlots: slots,
    );

void main() {
  late FakeFirebaseFirestore db;
  late DormitoryRepository dorms;
  late ReservationRepository reservations;

  setUp(() {
    db = FakeFirebaseFirestore();
    dorms = DormitoryRepository(db);
    reservations = ReservationRepository(db);
  });

  group('DormitoryRepository', () {
    test('rejects invalid dorm', () {
      expect(() => dorms.createDormitory(_dorm(price: -5)), throwsA(isA<DbException>()));
      expect(() => dorms.createDormitory(_dorm(slots: 9, capacity: 2)), throwsA(isA<DbException>()));
    });

    test('search filters by city and max price, sorted cheapest first', () async {
      await dorms.createDormitory(_dorm(name: 'Cheap Manila', price: 3000));
      await dorms.createDormitory(_dorm(name: 'Pricey Manila', price: 9000));
      await dorms.createDormitory(_dorm(name: 'Cheap QC', city: 'Quezon City', price: 3500));
      await dorms.createDormitory(_dorm(name: 'Mid Manila', price: 6000));

      final r = await dorms.search(city: 'Manila', maxPrice: 7000);
      expect(r.items.map((d) => d.name), ['Cheap Manila', 'Mid Manila']);
    });

    test('pagination returns the next page', () async {
      for (var i = 1; i <= 5; i++) {
        await dorms.createDormitory(_dorm(name: 'Dorm $i', price: 1000.0 * i));
      }
      final page1 = await dorms.search(limit: 2);
      expect(page1.items.length, 2);
      expect(page1.hasMore, isTrue);
      final page2 = await dorms.search(limit: 2, startAfter: page1.lastDoc);
      expect(page2.items.first.name, 'Dorm 3');
    });
  });

  group('ReservationRepository', () {
    late String dormId;
    final moveIn = DateTime.now().add(const Duration(days: 14));

    setUp(() async {
      dormId = await dorms.createDormitory(_dorm(capacity: 2, slots: 1));
    });

    test('blocks duplicate active reservation and own-dorm reservation', () async {
      await reservations.createReservation(
          dormId: dormId, tenantId: 'tenant1', moveInDate: moveIn, durationMonths: 6);
      expect(
        () => reservations.createReservation(
            dormId: dormId, tenantId: 'tenant1', moveInDate: moveIn, durationMonths: 6),
        throwsA(isA<DbException>()),
      );
      expect(
        () => reservations.createReservation(
            dormId: dormId, tenantId: 'host1', moveInDate: moveIn, durationMonths: 6),
        throwsA(isA<DbException>()),
      );
    });

    test('approve decrements slots and adds resident; cancel restores', () async {
      final resId = await reservations.createReservation(
          dormId: dormId, tenantId: 'tenant1', moveInDate: moveIn, durationMonths: 6);

      await reservations.hostUpdateStatus(
          reservationId: resId, newStatus: ReservationStatus.approved);
      var dorm = (await dorms.getById(dormId))!;
      expect(dorm.availableSlots, 0);
      expect(dorm.residentIds, contains('tenant1'));

      await reservations.hostUpdateStatus(
          reservationId: resId, newStatus: ReservationStatus.cancelled);
      dorm = (await dorms.getById(dormId))!;
      expect(dorm.availableSlots, 1);
      expect(dorm.residentIds, isNot(contains('tenant1')));
    });

    test('illegal status jump is rejected', () async {
      final resId = await reservations.createReservation(
          dormId: dormId, tenantId: 'tenant1', moveInDate: moveIn, durationMonths: 6);
      expect(
        () => reservations.hostUpdateStatus(
            reservationId: resId, newStatus: ReservationStatus.completed),
        throwsA(isA<DbException>()),
      );
    });

    test('no reservation when dorm is full', () async {
      final fullId = await dorms.createDormitory(_dorm(name: 'Full', capacity: 1, slots: 0));
      expect(
        () => reservations.createReservation(
            dormId: fullId, tenantId: 'tenant2', moveInDate: moveIn, durationMonths: 3),
        throwsA(isA<DbException>()),
      );
    });
  });

  test('conversationId is the same for both users', () {
    expect(MessageRepository.conversationId('b', 'a'), 'a_b');
    expect(MessageRepository.conversationId('a', 'b'), 'a_b');
  });
}
