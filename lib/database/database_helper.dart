import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/transaction.dart' as models;

// データベース操作を管理するクラス
// Singletonパターンを使用してアプリ全体で1つのインスタンスのみ存在
class DatabaseHelper {
  // =============================================================================
  // Singletonパターンの実装
  // =============================================================================

  // 唯一のインスタンスを保存する静的変数
  // _internal()でプライベートコンストラクタを呼び出し、外部からの直接作成を防ぐ
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // ファクトリーコンストラクタ：新しいインスタンスを作らず既存のものを返す
  // どこからDatabaseHelper()を呼び出しても同じインスタンスが返される
  factory DatabaseHelper() => _instance;

  // プライベートコンストラクタ：外部からの直接インスタンス化を防ぐ
  DatabaseHelper._internal() {
    // デスクトップ環境やテスト環境ではsqflite_common_ffiを使用して初期化
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // データベースインスタンスを保存する変数
  // null許可型（?）：初期状態ではnull、初期化後にDatabaseインスタンスを格納
  Database? _database;

  // =============================================================================
  // データベース初期化
  // =============================================================================

  // データベースインスタンスを取得するgetter
  // 初回アクセス時のみ初期化処理を実行（遅延初期化：Lazy Initialization）
  Future<Database> get database async {
    // null合体代入演算子（??=）：_databaseがnullの場合のみ初期化実行
    _database ??= await _initDatabase();
    return _database!; // 非null保証演算子（!）：この時点で_databaseは確実にnullでない
  }

  // データベースファイルの作成と初期化
  Future<Database> _initDatabase() async {
    // データベースファイルのパスを生成
    // join()：パスを安全に結合（OSの違いを吸収）
    String path = join(await getDatabasesPath(), 'transaction.db');

    // データベースを開く（存在しない場合は作成）
    return await openDatabase(
      path,
      version: 1, // データベースのバージョン（スキーマ変更時に使用）
      onCreate: _createTables, // 初回作成時に実行するコールバック
    );
  }

  // テーブル作成処理
  Future<void> _createTables(Database db, int version) async {
    // SQLでtransactionsテーブルを作成
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,    -- 主キー（文字列型のユニークID）
        amount REAL NOT NULL,   -- 金額（実数型、必須）
        category TEXT NOT NULL, -- カテゴリ（文字列型、必須）
        description TEXT NOT NULL, -- 説明（文字列型、必須）
        date INTEGER NOT NULL,  -- 日付（整数型のUnixタイムスタンプ、必須）
        isIncome INTEGER NOT NULL -- 収入フラグ（整数型：0=支出、1=収入、必須）
      )
    ''');
  }

  // =============================================================================
  // CRUD操作（Create, Read, Update, Delete）
  // =============================================================================

  // 取引を追加（Create操作）
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database; // データベースインスタンスを取得

    // insert()：SQLのINSERT文を実行
    // 戻り値：挿入された行のID（成功時は正の整数、失敗時は-1など）
    return await db.insert('transactions', {
      // DartオブジェクトをMap<String, dynamic>に変換してデータベースに保存
      'id': transaction.id,
      'amount': transaction.amount,
      'category': transaction.category,
      'description': transaction.description,
      'date':
          transaction.date.millisecondsSinceEpoch, // DateTimeをUnixタイムスタンプに変換
      'isIncome': transaction.isIncome ? 1 : 0, // boolを整数に変換
    });
  }

  // すべての取引を取得（Read操作）
  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;

    // query()：SQLのSELECT文を実行
    // orderBy：結果を日付の降順（新しい順）で並び替え
    final maps = await db.query('transactions', orderBy: 'date DESC');

    // List.generate()：指定された長さのリストを生成
    // 各Map<String, dynamic>をTransactionオブジェクトに変換
    return List.generate(maps.length, (i) {
      return models.Transaction(
        id: maps[i]['id'] as String,
        amount: (maps[i]['amount'] as num).toDouble(), // numからdoubleに安全変換
        category: maps[i]['category'] as String,
        description: maps[i]['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(
          maps[i]['date'] as int,
        ), // Unixタイムスタンプから復元
        isIncome: maps[i]['isIncome'] == 1, // 整数からboolに変換
      );
    });
  }

  // 特定月の取引を取得（Read操作：条件付き）
  Future<List<models.Transaction>> getTransactionsByMonth(
    int year, // 年
    int month, // 月
  ) async {
    final db = await database;

    // 月の開始日時と終了日時を計算
    final startOfMonth = DateTime(year, month, 1); // 月初：1日 00:00:00
    final endOfMonth = DateTime(
      year,
      month + 1,
      0,
      23,
      59,
      59,
    ); // 月末：最終日 23:59:59

    // WHERE句で日付範囲を指定してクエリ実行
    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?', // プレースホルダー（?）を使用
      whereArgs: [
        // プレースホルダーに代入する値
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );

    // 結果をTransactionオブジェクトのリストに変換
    return List.generate(maps.length, (i) {
      return models.Transaction(
        id: maps[i]['id'] as String,
        amount: (maps[i]['amount'] as num).toDouble(),
        category: maps[i]['category'] as String,
        description: maps[i]['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(maps[i]['date'] as int),
        isIncome: maps[i]['isIncome'] == 1,
      );
    });
  }

  // 取引を削除（Delete操作）
  Future<int> deleteTransaction(String id) async {
    final db = await database;

    // delete()：SQLのDELETE文を実行
    // 戻り値：削除された行数
    return await db.delete(
      'transactions',
      where: 'id = ?', // 指定されたIDの行を削除
      whereArgs: [id],
    );
  }

  // =============================================================================
  // 集計・分析機能
  // =============================================================================

  // カテゴリ別の支出を取得（今月）
  Future<Map<String, double>> getExpensesByCategory(int year, int month) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    // rawQuery()：生のSQL文を直接実行（複雑なクエリに使用）
    final maps = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total  -- カテゴリ別に金額を合計
      FROM transactions 
      WHERE date >= ? AND date <= ? AND isIncome = 0  -- 指定月の支出のみ
      GROUP BY category  -- カテゴリでグループ化
    ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    // 結果をMap<String, double>に変換
    final result = <String, double>{};
    for (final map in maps) {
      result[map['category'] as String] = (map['total'] as num).toDouble();
    }

    return result;
  }

  // 月別サマリーを取得（収入・支出・残高）
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    // CASE文を使用して収入と支出を条件分岐で集計
    final maps = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,  -- 収入の合計
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expense  -- 支出の合計
      FROM transactions 
      WHERE date >= ? AND date <= ?
    ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    // null安全な値の取得と型変換
    final incomeValue = maps.first['income'];
    final expenseValue = maps.first['expense'];

    final income = incomeValue != null ? (incomeValue as num).toDouble() : 0.0;
    final expense = expenseValue != null
        ? (expenseValue as num).toDouble()
        : 0.0;

    // 収入、支出、残高を含むMapを返す
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense, // 残高 = 収入 - 支出
    };
  }

  // =============================================================================
  // リソース管理
  // =============================================================================

  // データベース接続を閉じる（メモリリーク防止）
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null; // 参照をクリア
    }
  }
}

/*
設計パターンと技術のまとめ：

1. Singletonパターン
   - アプリ全体で1つのデータベース接続を共有
   - リソース節約とデータ整合性の確保

2. Future/async/await
   - 非同期処理でUIブロックを防ぐ
   - データベース操作は時間がかかる可能性があるため

3. SQLiteの活用
   - ローカルストレージによる高速アクセス
   - 関係データベースの機能（JOIN、GROUP BY等）

4. 型安全性
   - 厳密な型変換でランタイムエラーを防ぐ
   - null安全性の確保

5. SQL注入攻撃の防止
   - プレースホルダー（?）を使用してパラメータ化クエリを実行
*/
