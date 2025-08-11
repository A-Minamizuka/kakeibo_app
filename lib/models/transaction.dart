// データモデルクラス：取引情報を表現するクラス
// アプリ内で取引データをやり取りする際の「型」を定義
class Transaction {
  // final：一度設定されたら変更不可（イミュータブル）
  // これにより予期しない値の変更を防ぐ
  final String id; // 取引の一意識別子（ユニークID）
  final double amount; // 金額（小数点対応のためdouble）
  final String category; // カテゴリ（食費、交通費など）
  final String description; // 説明・メモ
  final DateTime date; // 取引日時
  final bool isIncome; // 収入かどうかのフラグ（true=収入、false=支出）

  // コンストラクタ：Transactionオブジェクトを作成する際に必要な値を指定
  // required：必須パラメータ（省略不可）
  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.isIncome,
  });

  // オブジェクトをMap形式に変換するメソッド
  // データベースやJSONとの連携で使用（シリアライゼーション）
  Map<String, dynamic> toJoin() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.millisecondsSinceEpoch, // DateTimeをUnixタイムスタンプに変換
      'isIncome': isIncome,
    };
  }

  // Map（JSON）からTransactionオブジェクトを作成するファクトリーメソッド
  // APIからのデータやデータベースからのデータを復元する際に使用（デシリアライゼーション）
  // 注意：現在のコードにはいくつかタイプミスがあるため、修正版を示します
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(), // 修正：toDoubleを正しい形に
      category: json['category'],
      description: json['description'],
      date: DateTime.fromMillisecondsSinceEpoch(
        json['date'],
      ), // 修正：millisecondsに統一
      isIncome: json['isIncome'], // 修正：isIncomeのタイプミス修正
    );
  }
}

// カテゴリの定数を管理するクラス
// 静的メンバー（static const）でアプリ全体で共通のカテゴリリストを管理
class CategoryData {
  // 支出カテゴリの定義
  // const：コンパイル時定数、メモリ効率が良い
  static const List<String> expenseCategories = [
    '食費', // 食事、食材など
    '交通費', // 電車、バス、タクシーなど
    '娯楽', // 映画、ゲーム、旅行など
    '光熱費', // 電気、ガス、水道など
    '医療費', // 病院、薬など
    'その他', // その他の支出
  ];

  // 収入カテゴリの定義
  static const List<String> incomeCategories = [
    '給料', // 月給、日給など
    'ボーナス', // 賞与
    'その他収入', // 副収入、お小遣いなど
  ];
}

/*
設計のポイント：

1. イミュータブル設計
   - すべてのフィールドがfinalで変更不可
   - データの整合性を保ち、バグを防ぐ

2. 責任の分離
   - Transactionクラス：データの構造を定義
   - CategoryDataクラス：カテゴリの管理
   
3. 型安全性
   - 厳密な型定義により、コンパイル時にエラーを検出

4. 拡張性
   - 新しいカテゴリを追加する際は、CategoryDataを変更するだけ
*/
