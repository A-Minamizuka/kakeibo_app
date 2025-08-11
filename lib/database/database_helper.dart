import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction.dart' as models;

class DatabaseHelper {
  // シングルトンでインスタンスを一つだけにしている（リソース節約のため）
  // インスタンスの保存
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  // ファクトリーコンストラクタ（新しいインスタンスをつくらず、既存のものを返すコンストラクタ）
  factory DatabaseHelper() => _instance;
  // プライベートコンストラクタ
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    // _databaseがnullの時だけ初期化処理をする
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'transaction.db');

    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date INTEGER NOT NULL,
        isIncome INTEGER NOT NULL
      )
    ''');
  }

  // 取引を追加
  Future<int> insertTransaction(models.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', {
      'id': transaction.id,
      'amount': transaction.amount,
      'category': transaction.category,
      'description': transaction.description,
      'date': transaction.date.millisecondsSinceEpoch,
      'isIncome': transaction.isIncome ? 1 : 0,
    });
  }

  // すべての取引を取得
  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');

    return List.generate(maps.length, (i) {
      return models.Transaction(
        id: maps[i]['id'] as String,
        amount: maps[i]['amount'] as double,
        category: maps[i]['category'] as String,
        description: maps[i]['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(maps[i]['date'] as int),
        isIncome: maps[i]['isIncome'] == 1,
      );
    });
  }

  // 特定月の取引を取得
  Future<List<models.Transaction>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return models.Transaction(
        id: maps[i]['id'] as String,
        amount: maps[i]['amount'] as double,
        category: maps[i]['category'] as String,
        description: maps[i]['description'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(maps[i]['date'] as int),
        isIncome: maps[i]['isIncome'] == 1,
      );
    });
  }

  // 取引を削除
  Future<int> deleteTransaction(String id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // カテゴリ別の支出を取得（今月）
  Future<Map<String, double>> getExpensesByCategory(int year, int month) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final maps = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total
      FROM transactions 
      WHERE date >= ? AND date <= ? AND isIncome = 0
      GROUP BY category
    ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    final result = <String, double>{};
    for (final map in maps) {
      result[map['category'] as String] = map['total'] as double;
    }

    return result;
  }

  // 月別サマリーを取得
  Future<Map<String, double>> getMonthlySummary(int year, int month) async {
    final db = await database;

    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final maps = await db.rawQuery(
      '''
      SELECT 
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as expense
      FROM transactions 
      WHERE date >= ? AND date <= ?
    ''',
      [startOfMonth.millisecondsSinceEpoch, endOfMonth.millisecondsSinceEpoch],
    );

    final income = maps.first['income'] as double? ?? 0.0;
    final expense = maps.first['expense'] as double? ?? 0.0;

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // データベースを閉じる
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
