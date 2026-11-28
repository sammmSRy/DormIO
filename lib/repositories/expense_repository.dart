import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/db_exception.dart';
import '../core/firestore_paths.dart';
import '../core/validators.dart';
import '../models/expense.dart';

/// expenses/{expenseId}  (linked to a dorm by dormId)
class ExpenseRepository {
  ExpenseRepository([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestorePaths.expenses);

  /// Splits [amount] equally. Works in centavos so there is no rounding loss:
  /// equalShares(100, [a,b,c]) -> a: 33.34, b: 33.33, c: 33.33  (sum = 100.00)
  static Map<String, double> equalShares(double amount, List<String> members) {
    final cents = (amount * 100).round();
    final base = cents ~/ members.length;
    final remainder = cents % members.length;
    return {
      for (var i = 0; i < members.length; i++)
        members[i]: (base + (i < remainder ? 1 : 0)) / 100,
    };
  }

  /// Net balance per member. Positive = is owed money, negative = owes money.
  /// Shares that are already settled are ignored.
  static Map<String, double> computeBalances(List<Expense> expenses) {
    final b = <String, double>{};
    for (final e in expenses) {
      e.shares.forEach((uid, share) {
        if (uid == e.paidBy || e.settledBy.contains(uid)) return;
        b[e.paidBy] = (b[e.paidBy] ?? 0) + share;
        b[uid] = (b[uid] ?? 0) - share;
      });
    }
    return b.map((k, v) => MapEntry(k, (v * 100).round() / 100));
  }

  Future<String> addExpense({
    required String dormId,
    required String paidBy,
    required String title,
    required double amount,
    required List<String> splitAmong,
  }) async {
    final error = Validators.requiredField(title, field: 'Title') ??
        Validators.amount(amount);
    if (error != null) throw DbException(error);
    if (splitAmong.isEmpty) throw DbException('Choose who shares this expense');
    if (splitAmong.length > 20) throw DbException('Too many people (max 20)');

    final ref = await _col.add({
      'dormId': dormId,
      'paidBy': paidBy,
      'title': title.trim(),
      'amount': amount,
      'splitAmong': splitAmong,
      'shares': equalShares(amount, splitAmong),
      'settledBy': [paidBy], // the payer has obviously paid already
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<Expense>> watchByDorm(String dormId) => _col
      .where('dormId', isEqualTo: dormId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Expense.fromDoc).toList());

  /// "I paid my share" — only adds the caller's own uid.
  Future<void> markSettled(String expenseId, String uid) =>
      _col.doc(expenseId).update({
        'settledBy': FieldValue.arrayUnion([uid]),
      });

  Future<void> deleteExpense(String expenseId) => _col.doc(expenseId).delete();
}
