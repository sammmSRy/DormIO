import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

class ChoreStatus {
  static const pending = 'pending';
  static const done = 'done';
}

class Chore {
  final String id;
  final String dormId;
  final String title;
  final String assignedTo;
  final String createdBy;
  final String status;
  final DateTime? dueDate;
  final DateTime? completedAt;

  const Chore({
    required this.id,
    required this.dormId,
    required this.title,
    required this.assignedTo,
    required this.createdBy,
    required this.status,
    this.dueDate,
    this.completedAt,
  });

  bool get isDone => status == ChoreStatus.done;

  factory Chore.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Chore(
      id: doc.id,
      dormId: d['dormId'] ?? '',
      title: d['title'] ?? '',
      assignedTo: d['assignedTo'] ?? '',
      createdBy: d['createdBy'] ?? '',
      status: d['status'] ?? ChoreStatus.pending,
      dueDate: toDate(d['dueDate']),
      completedAt: toDate(d['completedAt']),
    );
  }
}
