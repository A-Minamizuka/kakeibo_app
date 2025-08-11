import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

// 状態管理クラス：アプリの取引データの状態を管理
// ChangeNotifierを継承してObserverパターンを実装
// UI（View）とデータベース（Model）の仲介役（MVVMのViewModel相当）
class TransactionProvider with ChangeNotifier {
  // =============================================================================
  // プライベートフィールド（内部状態）
  // =============================================================================

  // データベースヘルパーのインスタンス
  final DatabaseHelper _db = DatabaseHelper();

  // アンダースコア（_）で始まる変数はプライベート（外部からアクセス不可）
  List<Transaction> _transactions = []; // 選択中の月の取引一覧
  double _monthlyIncome = 0.0; // 選択中の月の収入合計
  double _monthlyExpense = 0.0; // 選択中の月の支出合計
  Map<String, double> _expenseByCategory = {}; // カテゴリ別支出

  // 表示する年と月（初期値は現在）
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // =============================================================================
  // パブリックgetters（外部からの読み取り専用アクセス）
  // =============================================================================

  // 取引一覧を取得（読み取り専用）
  List<Transaction> get transactions => _transactions;

  // 選択中の年と月を取得
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  // 選択中の月の収入を取得
  double get monthlyIncome => _monthlyIncome;

  // 選択中の月の支出を取得
  double get monthlyExpense => _monthlyExpense;

  // 選択中の月の残高を計算（収入 - 支出）
  // 計算プロパティ：呼び出し時に動的に計算される
  double get monthlyBalance => _monthlyIncome - _monthlyExpense;

  // 現在の月を表示しているかどうか
  bool get isCurrentMonth {
    final now = DateTime.now();
    return _selectedYear == now.year && _selectedMonth == now.month;
  }

  // カテゴリ別支出を取得
  Map<String, double> get expenseByCategory => _expenseByCategory;

  // =============================================================================
  // 初期化・データ読み込み
  // =============================================================================

  // 初期化処理：今月のデータを読み込み
  // アプリ起動時やデータ更新後に呼び出される
  Future<void> loadTransactions() async {
    // 選択中の月の取引データを取得
    _transactions =
        await _db.getTransactionsByMonth(_selectedYear, _selectedMonth);

    // 月別サマリー（収入・支出）を読み込み
    await _loadMonthlySummary();

    // カテゴリ別支出を読み込み
    _expenseByCategory =
        await _db.getExpensesByCategory(_selectedYear, _selectedMonth);

    // 状態変更をUI（リスナー）に通知
    // この呼び出しによりConsumer<TransactionProvider>で包まれたウィジェットが再ビルドされる
    notifyListeners();
  }

  // 月別サマリーを読み込み（プライベートヘルパーメソッド）
  Future<void> _loadMonthlySummary() async {
    // データベースから選択中の月のサマリーを取得
    final summary =
        await _db.getMonthlySummary(_selectedYear, _selectedMonth);

    // null合体演算子（??）：左辺がnullの場合に右辺の値を使用
    _monthlyIncome = summary['income'] ?? 0.0;
    _monthlyExpense = summary['expense'] ?? 0.0;
  }

  // =============================================================================
  // データ操作メソッド
  // =============================================================================

  // 取引追加処理
  Future<void> addTransaction({
    required double amount, // 必須：金額
    required String category, // 必須：カテゴリ
    required String description, // 必須：説明
    required bool isIncome, // 必須：収入フラグ
    DateTime? date, // オプション：日付（未指定時は現在日時）
  }) async {
    // 新しいTransactionオブジェクトを作成
    final transaction = Transaction(
      // ユニークIDとして現在時刻のミリ秒を文字列化
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      description: description,
      date: date ?? DateTime.now(), // null合体演算子：dateがnullなら現在日時
      isIncome: isIncome,
    );

    // データベースに取引を保存
    await _db.insertTransaction(transaction);

    // データを再読み込みして表示を更新
    await loadTransactions();
  }

  // 取引削除処理
  Future<void> deleteTransaction(String id) async {
    // データベースから指定されたIDの取引を削除
    await _db.deleteTransaction(id);

    // データを再読み込みして表示を更新
    await loadTransactions();
  }

  // 表示月を前月に変更
  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedYear--;
      _selectedMonth = 12;
    } else {
      _selectedMonth--;
    }
    loadTransactions();
  }

  // 表示月を翌月に変更
  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedYear++;
      _selectedMonth = 1;
    } else {
      _selectedMonth++;
    }
    loadTransactions();
  }
}

/*
設計パターンと仕組みの解説：

1. ObserverパターンとChangeNotifier
   - TransactionProviderが状態を管理（Subject）
   - UIウィジェット（Consumer）が変更を監視（Observer）
   - notifyListeners()で状態変更を通知

2. MVVM（Model-View-ViewModel）パターン
   - Model: DatabaseHelper, Transaction（データ層）
   - View: 各Screen（UI層）
   - ViewModel: TransactionProvider（状態管理・ロジック層）

3. 責任の分離
   - UI（View）：表示とユーザーインタラクション
   - Provider（ViewModel）：状態管理とビジネスロジック
   - DatabaseHelper（Model）：データの永続化

4. リアクティブプログラミング
   - データの変更が自動的にUIに反映される
   - 手動でのUI更新が不要

5. 非同期処理
   - Future/asyncによりメインスレッドをブロックしない
   - データベース操作中もUIが応答可能

データフローの例：
1. ユーザーが新しい取引を入力
2. AddTransactionScreenでaddTransaction()を呼び出し
3. DatabaseHelperでデータベースに保存
4. loadTransactions()でデータを再読み込み
5. notifyListeners()でUI更新を通知
6. Consumer<TransactionProvider>が自動的に再ビルド
7. 最新データが画面に表示される

この仕組みにより、データの整合性を保ちながら
効率的な状態管理が実現されています。
*/
