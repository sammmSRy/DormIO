import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/db_exception.dart';
import '../core/firestore_paths.dart';
import '../core/validators.dart';
import '../models/dormitory.dart';
import '../models/reservation.dart';

/// reservations/{reservationId}
///   tenantId  -> users/{uid}        (who reserved)
///   dormId    -> dormitories/{id}   (what was reserved)
///   ownerId   -> users/{uid}        (copied from the dorm)
class ReservationRepository {
  ReservationRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.reservations);
  CollectionReference<Map<String, dynamic>> get _dorms =>
      _db.collection(FirestorePaths.dormitories);

  /// Tenant reserves a dorm. Status always starts as "pending".
  Future<String> createReservation({
    required String dormId,
    required String tenantId,
    required DateTime moveInDate,
    required int durationMonths,
    String note = '',
  }) async {
    final error =
        Validators.moveInDate(moveInDate) ?? Validators.durationMonths(durationMonths);
    if (error != null) throw DbException(error);
    if (note.length > 300) throw DbException('Note must be 300 characters or fewer');

    final dormSnap = await _dorms.doc(dormId).get();
    if (!dormSnap.exists) throw DbException('Dormitory not found');
    final dorm = Dormitory.fromDoc(dormSnap);
    if (!dorm.isActive) throw DbException('This dormitory is not accepting reservations');
    if (dorm.availableSlots <= 0) throw DbException('No available slots');
    if (dorm.ownerId == tenantId) throw DbException('You cannot reserve your own dormitory');

    final existing = await _col
        .where('tenantId', isEqualTo: tenantId)
        .where('dormId', isEqualTo: dormId)
        .where('status', whereIn: [
          ReservationStatus.pending,
          ReservationStatus.approved,
        ])
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw DbException('You already have an active reservation for this dormitory');
    }

    final ref = await _col.add({
      'dormId': dormId,
      'tenantId': tenantId,
      'ownerId': dorm.ownerId,
      'status': ReservationStatus.pending,
      'moveInDate': Timestamp.fromDate(moveInDate),
      'durationMonths': durationMonths,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Reservation>> watchTenantReservations(String tenantId) => _col
      .where('tenantId', isEqualTo: tenantId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Reservation.fromDoc).toList());

  Stream<List<Reservation>> watchHostReservations(String ownerId,
      {String? status}) {
    Query<Map<String, dynamic>> q = _col.where('ownerId', isEqualTo: ownerId);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Reservation.fromDoc).toList());
  }

  /// Tenant can only cancel while the reservation is still "pending".
  Future<void> cancelByTenant(String reservationId) => _col.doc(reservationId).update({
        'status': ReservationStatus.cancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// Host approves / rejects / cancels / completes.
  /// Runs in a TRANSACTION so the reservation status and the dorm's
  /// availableSlots + residentIds can never get out of sync.
  Future<void> hostUpdateStatus({
    required String reservationId,
    required String newStatus,
  }) {
    return _db.runTransaction((tx) async {
      final resRef = _col.doc(reservationId);
      final resSnap = await tx.get(resRef);
      if (!resSnap.exists) throw DbException('Reservation not found');
      final res = Reservation.fromDoc(resSnap);

      final allowed = ReservationStatus.hostTransitions[res.status] ?? const <String>[];
      if (!allowed.contains(newStatus)) {
        throw DbException('Cannot change a ${res.status} reservation to $newStatus');
      }

      final dormRef = _dorms.doc(res.dormId);
      final dormSnap = await tx.get(dormRef);
      if (!dormSnap.exists) throw DbException('Dormitory not found');
      final dorm = Dormitory.fromDoc(dormSnap);

      if (newStatus == ReservationStatus.approved) {
        if (dorm.availableSlots <= 0) throw DbException('No slots left to approve');
        tx.update(dormRef, {
          'availableSlots': dorm.availableSlots - 1,
          'residentIds': FieldValue.arrayUnion([res.tenantId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (res.status == ReservationStatus.approved) {
        // approved -> cancelled / completed : free the slot again
        tx.update(dormRef, {
          'availableSlots': math.min(dorm.availableSlots + 1, dorm.capacity),
          'residentIds': FieldValue.arrayRemove([res.tenantId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      tx.update(resRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
