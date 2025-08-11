import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Transaction> _transactions = [];
  double _thisMonthIncome = 0.0;
  double _thisMonthExpense = 0.0;
  Map<String, double> _expenseByCategory = {};

  List<Transaction> get transactions => _transactions;
  double get thisMonthIncome => _thisMonthIncome;
  double get thisMonthExpense => _thisMonthExpense;
  double get thisMonthBalance => _thisMonthIncome - _thisMonthExpense;
  Map<String, double> get expenseByCategory => _expenseByCategory;

  // 初期化（今月のデータを読み込み）
  Future<void> loadTransactions() async {
    final now = DateTime.now();
    _transactions = await _db.getTransactionsByMonth(now.year, now.month);
    await _loadMonthlySummary();
    _expenseByCategory = await _db.getExpensesByCategory(now.year, now.month);
    notifyListeners();
  }

  // 月別サマリーを読み込み
  Future<void> _loadMonthlySummary() async {
    final now = DateTime.now();
    final summary = await _db.getMonthlySummary(now.year, now.month);
    _thisMonthIncome = summary['income'] ?? 0.0;
    _thisMonthExpense = summary['expense'] ?? 0.0;
  }

  // 取引追加
  Future<void> addTransaction({
    required double amount,
    required String category,
    required String description,
    required bool isIncome,
    DateTime? date,
  }) async {
    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      description: description,
      date: date ?? DateTime.now(),
      isIncome: isIncome,
    );

    await _db.insertTransaction(transaction);
    await loadTransactions(); // データを再読み込み
  }

  // 取引削除
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await loadTransactions(); // データを再読み込み
  }
}
