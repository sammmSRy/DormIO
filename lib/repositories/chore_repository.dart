import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/db_exception.dart';
import '../core/firestore_paths.dart';
import '../core/validators.dart';
import '../models/chore.dart';

/// chores/{choreId}  (linked to a dorm by dormId)
class ChoreRepository {
  ChoreRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.chores);

  Future<String> addChore({
    required String dormId,
    required String title,
    required String assignedTo,
    required String createdBy,
    required DateTime dueDate,
  }) async {
    final error = Validators.requiredField(title, field: 'Chore title') ??
        Validators.requiredField(assignedTo, field: 'Assignee');
    if (error != null) throw DbException(error);
    if (title.trim().length > 80) throw DbException('Title must be 80 characters or fewer');

    final ref = await _col.add({
      'dormId': dormId,
      'title': title.trim(),
      'assignedTo': assignedTo,
      'createdBy': createdBy,
      'status': ChoreStatus.pending,
      'dueDate': Timestamp.fromDate(dueDate),
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Chore>> watchByDorm(String dormId) => _col
      .where('dormId', isEqualTo: dormId)
      .orderBy('dueDate')
      .snapshots()
      .map((s) => s.docs.map(Chore.fromDoc).toList());

  /// "My chores" list for one person (only the not-done ones by default).
  Stream<List<Chore>> watchAssignedTo(String uid,
          {String status = ChoreStatus.pending}) =>
      _col
          .where('assignedTo', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .orderBy('dueDate')
          .snapshots()
          .map((s) => s.docs.map(Chore.fromDoc).toList());

  Future<void> setDone(String choreId, bool done) => _col.doc(choreId).update({
        'status': done ? ChoreStatus.done : ChoreStatus.pending,
        'completedAt': done ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> reassign(String choreId, String newAssigneeUid) =>
      _col.doc(choreId).update({
        'assignedTo': newAssigneeUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteChore(String choreId) => _col.doc(choreId).delete();
}
