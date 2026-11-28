import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

class ReservationStatus {
  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const completed = 'completed';

  /// Allowed changes made by the dorm owner (host).
  static const hostTransitions = <String, List<String>>{
    pending: [approved, rejected],
    approved: [cancelled, completed],
  };
}

class Reservation {
  final String id;
  final String dormId;
  final String tenantId;
  final String ownerId; // copied from the dorm so rules/queries stay cheap
  final String status;
  final DateTime? moveInDate;
  final int durationMonths;
  final String note;
  final DateTime? createdAt;

  const Reservation({
    required this.id,
    required this.dormId,
    required this.tenantId,
    required this.ownerId,
    required this.status,
    required this.moveInDate,
    required this.durationMonths,
    this.note = '',
    this.createdAt,
  });

  factory Reservation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Reservation(
      id: doc.id,
      dormId: d['dormId'] ?? '',
      tenantId: d['tenantId'] ?? '',
      ownerId: d['ownerId'] ?? '',
      status: d['status'] ?? ReservationStatus.pending,
      moveInDate: toDate(d['moveInDate']),
      durationMonths: toInt(d['durationMonths'], 1),
      note: d['note'] ?? '',
      createdAt: toDate(d['createdAt']),
    );
  }
}
