import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as models;

// 取引追加画面：新しい収入・支出を登録する画面
// StatefulWidget：画面内で変化する状態（フォームの入力値など）を管理
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

// StatefulWidgetの状態を管理するクラス
class _AddTransactionScreenState extends State<AddTransactionScreen> {
  // =============================================================================
  // フォーム関連のコントローラーとキー
  // =============================================================================

  // GlobalKey<FormState>：フォーム全体のバリデーション制御
  // フォームの検証（validate）や送信処理で使用
  final _formKey = GlobalKey<FormState>();

  // TextEditingController：テキスト入力フィールドの制御
  // 入力値の取得、設定、監視を行う
  final _amountController = TextEditingController(); // 金額入力
  final _descriptionController = TextEditingController(); // 説明入力

  // =============================================================================
  // 画面の状態変数
  // =============================================================================

  bool _isIncome = false; // 収入/支出の切り替えフラグ（false=支出）
  String _selectedCategory = ''; // 選択されたカテゴリ
  DateTime _selectedDate = DateTime.now(); // 選択された日付（初期値は現在日時）

  // =============================================================================
  // ライフサイクルメソッド
  // =============================================================================

  @override
  void initState() {
    super.initState();
    // 画面初期化時にデフォルトカテゴリを設定
    // 最初は支出モードで開始するため、支出カテゴリの最初を選択
    _selectedCategory = models.CategoryData.expenseCategories.first;
  }

  @override
  void dispose() {
    // メモリリーク防止：コントローラーのリソースを解放
    // StatefulWidgetが破棄される時に必ず実行
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // =============================================================================
  // UIビルド
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBarに保存ボタンを配置
      appBar: AppBar(
        title: const Text('取引追加'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // 右上の保存ボタン
          TextButton(
            onPressed: _saveTransaction,
            child: const Text('保存', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),

      // フォーム全体をFormウィジェットで包む
      body: Form(
        key: _formKey, // バリデーション制御用のキー
        child: SingleChildScrollView(
          // スクロール可能にする
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
            children: [
              // 収入/支出切り替えUI
              _buildIncomeExpenseToggle(),
              const SizedBox(height: 24), // 垂直スペース
              // 金額入力フィールド
              _buildAmountField(),
              const SizedBox(height: 16),

              // カテゴリ選択ドロップダウン
              _buildCategoryField(),
              const SizedBox(height: 16),

              // メモ入力フィールド
              _buildDescriptionField(),
              const SizedBox(height: 16),

              // 日付選択フィールド
              _buildDateField(),
              const SizedBox(height: 32),

              // 保存ボタン（画面下部）
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // UI部品作成メソッド
  // =============================================================================

  // 収入/支出切り替えボタン
  Widget _buildIncomeExpenseToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 支出ボタン（左側）
            Expanded(
              child: GestureDetector(
                // タップ時の処理
                onTap: () => setState(() {
                  _isIncome = false; // 支出モードに設定
                  // 支出カテゴリの最初を選択
                  _selectedCategory =
                      models.CategoryData.expenseCategories.first;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    // 選択状態に応じて背景色を変更
                    color: !_isIncome
                        ? Colors.red.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      // 選択状態に応じて枠線色を変更
                      color: !_isIncome ? Colors.red : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.remove_circle,
                        color: !_isIncome ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '支出',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !_isIncome ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16), // ボタン間のスペース
            // 収入ボタン（右側）
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _isIncome = true; // 収入モードに設定
                  // 収入カテゴリの最初を選択
                  _selectedCategory =
                      models.CategoryData.incomeCategories.first;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isIncome
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isIncome ? Colors.green : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle,
                        color: _isIncome ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '収入',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isIncome ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 金額入力フィールド
  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number, // 数値専用キーボードを表示
      decoration: InputDecoration(
        labelText: '金額',
        prefixText: '¥ ', // 接頭辞として円マークを表示
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, // 背景色を有効化
      ),
      // バリデーター：入力値の検証
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '金額を入力してください'; // エラーメッセージ
        }
        // double.tryParse：文字列を数値に変換（失敗時はnull）
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return '正しい金額を入力してください';
        }
        return null; // バリデーション成功
      },
    );
  }

  // カテゴリ選択ドロップダウン
  Widget _buildCategoryField() {
    // 現在の収入/支出モードに応じてカテゴリリストを選択
    final categories = _isIncome
        ? models.CategoryData.incomeCategories
        : models.CategoryData.expenseCategories;

    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'カテゴリ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
      // カテゴリリストからDropdownMenuItemを生成
      items: categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      // 選択変更時の処理
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  // メモ入力フィールド
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'メモ（任意）', // 任意入力であることを明記
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
      ),
      maxLines: 3, // 複数行入力を許可
    );
  }

  // 日付選択フィールド
  Widget _buildDateField() {
    return InkWell(
      // タップ可能な領域
      onTap: _selectDate, // タップ時に日付選択ダイアログを表示
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 16),
            Text(
              // 選択された日付を「年/月/日」形式で表示
              '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  // 保存ボタン
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, // 横幅いっぱいに展開
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('保存', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  // =============================================================================
  // イベントハンドラ
  // =============================================================================

  // 日付選択ダイアログ表示
  Future<void> _selectDate() async {
    // showDatePicker：日付選択ダイアログを表示
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // 初期選択日
      firstDate: DateTime(2020), // 選択可能な最古の日付
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ), // 選択可能な最新日（1年後まで）
    );

    // 日付が選択され、現在の選択と異なる場合のみ更新
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 取引保存処理
  Future<void> _saveTransaction() async {
    // フォームバリデーションの実行
    if (_formKey.currentState!.validate()) {
      // 入力値の取得と整理
      final amount = double.parse(_amountController.text);

      // 説明が空の場合はカテゴリ名をデフォルト説明として使用
      final description = _descriptionController.text.isEmpty
          ? _selectedCategory
          : _descriptionController.text;

      try {
        // TransactionProviderを通じて取引を追加
        await context.read<TransactionProvider>().addTransaction(
          amount: amount,
          category: _selectedCategory,
          description: description,
          isIncome: _isIncome,
          date: _selectedDate,
        );

        // 保存成功時の処理
        if (mounted) {
          // ウィジェットが有効かチェック
          Navigator.pop(context); // 前の画面に戻る

          // 成功メッセージをスナックバーで表示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_isIncome ? '収入' : '支出'}を追加しました'),
              backgroundColor: _isIncome ? Colors.green : Colors.blue,
            ),
          );
        }
      } catch (e) {
        // エラー発生時の処理
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('エラーが発生しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/*
フォーム設計とUXの重要ポイント：

1. フォームバリデーション
   - リアルタイムでエラーチェック
   - ユーザーフレンドリーなエラーメッセージ
   - 送信前の最終検証

2. 状態管理
   - StatefulWidgetでローカル状態を管理
   - 入力値の即座な反映とUI更新

3. ユーザビリティの配慮
   - 直感的な収入/支出切り替え
   - キーボードタイプの最適化
   - デフォルト値の適切な設定

4. エラーハンドリング
   - try-catch文でエラーを捕捉
   - ユーザーに分かりやすいメッセージ表示

5. メモリ管理
   - dispose()でリソース解放
   - mounted チェックで安全な非同期処理

6. レスポンシブデザイン
   - SingleChildScrollViewでスクロール対応
   - 様々な画面サイズに対応

この画面は家計簿アプリの核となる機能で、
使いやすさと確実性の両立が重要です。
*/
