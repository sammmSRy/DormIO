import 'package:dormio/models/expense.dart';
import 'package:dormio/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _expense({
  required String paidBy,
  required double amount,
  required Map<String, double> shares,
  List<String> settledBy = const [],
}) =>
    Expense(
      id: 'e',
      dormId: 'd',
      paidBy: paidBy,
      title: 't',
      amount: amount,
      splitAmong: shares.keys.toList(),
      shares: shares,
      settledBy: settledBy,
    );

void main() {
  test('equalShares never loses a centavo', () {
    final shares = ExpenseRepository.equalShares(100, ['a', 'b', 'c']);
    final total = shares.values.fold<double>(0, (s, v) => s + v);
    expect((total * 100).round(), 10000);
    expect(shares['a'], 33.34);
    expect(shares['b'], 33.33);
  });

  test('computeBalances: payer is owed, others owe', () {
    final e = _expense(
        paidBy: 'a', amount: 90, shares: {'a': 30, 'b': 30, 'c': 30}, settledBy: ['a']);
    final b = ExpenseRepository.computeBalances([e]);
    expect(b['a'], 60);
    expect(b['b'], -30);
    expect(b['c'], -30);
  });

  test('computeBalances ignores settled shares', () {
    final e = _expense(
        paidBy: 'a',
        amount: 90,
        shares: {'a': 30, 'b': 30, 'c': 30},
        settledBy: ['a', 'b']);
    final b = ExpenseRepository.computeBalances([e]);
    expect(b['a'], 30);
    expect(b.containsKey('b'), isFalse);
    expect(b['c'], -30);
  });
}
