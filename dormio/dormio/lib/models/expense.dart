import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/converters.dart';

class Expense {
  final String id;
  final String dormId;
  final String paidBy;
  final String title;
  final double amount;
  final List<String> splitAmong;
  final Map<String, double> shares; // uid -> amount owed
  final List<String> settledBy; // uids who already paid their share
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.dormId,
    required this.paidBy,
    required this.title,
    required this.amount,
    required this.splitAmong,
    required this.shares,
    required this.settledBy,
    this.createdAt,
  });

  factory Expense.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawShares = (d['shares'] as Map?) ?? {};
    return Expense(
      id: doc.id,
      dormId: d['dormId'] ?? '',
      paidBy: d['paidBy'] ?? '',
      title: d['title'] ?? '',
      amount: toDouble(d['amount']),
      splitAmong: stringList(d['splitAmong']),
      shares: rawShares.map((k, v) => MapEntry(k.toString(), toDouble(v))),
      settledBy: stringList(d['settledBy']),
      createdAt: toDate(d['createdAt']),
    );
  }
}
