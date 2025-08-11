class Transaction {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final bool isIncome;

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.isIncome,
  });

  Map<String, dynamic> toJoin() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'isIncome': isIncome,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble,
      category: json['category'],
      description: json['description'],
      date: DateTime.fromMicrosecondsSinceEpoch(json['date']),
      isIncome: json['isIcome'],
    );
  }
}

class CategoryData {
  static const List<String> expenseCategories = [
    '食費',
    '交通費',
    '娯楽',
    '光熱費',
    '医療費',
    'その他',
  ];

  static const List<String> incomeCategories = ['給料', 'ボーナス', 'その他収入'];
}
