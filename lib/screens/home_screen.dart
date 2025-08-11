import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import 'add_transaction_screen.dart';
import 'chart_screen.dart';

// ホーム画面：アプリのメイン画面
// StatelessWidget：状態を持たない画面（状態管理はProviderで行う）
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // =============================================================================
      // AppBar：画面上部のナビゲーションバー
      // =============================================================================
      appBar: AppBar(
        title: const Text('家計簿アプリ'),
        // Theme.of(context)：現在のテーマから色を取得
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // 右上のグラフアイコンボタン
          IconButton(
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              // Navigator.push：新しい画面に遷移
              // MaterialPageRoute：Material Designの画面遷移アニメーション
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChartScreen()),
              );
            },
          ),
        ],
      ),

      // =============================================================================
      // Body：画面のメインコンテンツ
      // =============================================================================
      body: Consumer<TransactionProvider>(
        // Consumer：Providerの状態変化を監視するウィジェット
        // TransactionProviderの状態が変更されると自動的に再ビルドされる
        builder: (context, provider, child) {
          return Column(
            children: [
              // 月切り替えセレクタ
              _buildMonthSelector(context, provider),

              // サマリーカード：選択中の月の収支を表示
              _buildSummaryCards(context, provider),

              // 取引履歴リスト：残りのスペースを使用
              Expanded(child: _buildTransactionList(context, provider)),
            ],
          );
        },
      ),

      // =============================================================================
      // FloatingActionButton：取引追加ボタン
      // =============================================================================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 取引追加画面に遷移
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // =============================================================================
  // 月切り替えウィジェット
  // =============================================================================

  Widget _buildMonthSelector(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final label = '${provider.selectedYear}年${provider.selectedMonth}月';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              provider.previousMonth();
            },
          ),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.isCurrentMonth
                ? null
                : () {
                    provider.nextMonth();
                  },
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // サマリーカード作成メソッド
  // =============================================================================

  Widget _buildSummaryCards(
    BuildContext context,
    TransactionProvider provider,
  ) {
    // NumberFormat：数値のフォーマット（カンマ区切り）
    // '#,###'：3桁区切りでカンマを挿入するパターン
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(16), // 全方向に16pxのパディング
      child: Row(
        children: [
          // Expandedを使って3つのカードを等幅で配置
          Expanded(
            child: _buildSummaryCard(
              context,
              '収入',
              '¥${formatter.format(provider.monthlyIncome)}',
              Colors.green, // 収入は緑色
              Icons.arrow_upward, // 上向き矢印
            ),
          ),
          const SizedBox(width: 8), // カード間のスペース
          Expanded(
            child: _buildSummaryCard(
              context,
              '支出',
              '¥${formatter.format(provider.monthlyExpense)}',
              Colors.red, // 支出は赤色
              Icons.arrow_downward, // 下向き矢印
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              context,
              '残高',
              '¥${formatter.format(provider.monthlyBalance)}',
              // 三項演算子：残高がマイナスの場合はオレンジ、プラスは青
              provider.monthlyBalance >= 0 ? Colors.blue : Colors.orange,
              Icons.account_balance_wallet, // 財布アイコン
            ),
          ),
        ],
      ),
    );
  }

  // 個別のサマリーカードを作成
  Widget _buildSummaryCard(
    BuildContext context,
    String title, // カードのタイトル（「収入」「支出」など）
    String amount, // 金額の文字列
    Color color, // テーマカラー
    IconData icon, // 表示するアイコン
  ) {
    return Card(
      elevation: 2, // 影の高さ（Material Designの立体感）
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4), // アイコンとタイトル間のスペース
            // Theme.of(context).textTheme：現在のテーマのテキストスタイルを取得
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold, // 金額は太字で強調
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // 取引履歴リスト作成メソッド
  // =============================================================================

  Widget _buildTransactionList(
    BuildContext context,
    TransactionProvider provider,
  ) {
    final transactions = provider.transactions;

    // 取引データが空の場合の処理
    if (transactions.isEmpty) {
      return const Center(child: Text('まだ取引がありません\n＋ボタンから追加してください'));
    }

    // ListView.builder：大量のデータを効率的に表示
    // 画面に表示される部分のみを動的に生成（仮想化）
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length, // リストアイテムの総数
      itemBuilder: (context, index) {
        // 各アイテムを生成するコールバック
        final transaction = transactions[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            // =============================================================================
            // ListTileの構成要素
            // =============================================================================

            // leading：左端のウィジェット（アイコン）
            leading: CircleAvatar(
              backgroundColor: transaction.isIncome ? Colors.green : Colors.red,
              child: Icon(
                transaction.isIncome ? Icons.add : Icons.remove,
                color: Colors.white,
              ),
            ),

            // title：メインテキスト（カテゴリ）
            title: Text(transaction.category),

            // subtitle：サブテキスト（説明と日付）
            subtitle: Text(
              // 複数行のテキスト：説明\n日付
              '${transaction.description}\n${DateFormat('M/d (E)', 'ja').format(transaction.date)}',
              // DateFormat('M/d (E)', 'ja')：「8/11 (月)」形式で日本語表示
            ),

            // trailing：右端のウィジェット（金額）
            trailing: Text(
              '¥${NumberFormat('#,###').format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: transaction.isIncome ? Colors.green : Colors.red,
              ),
            ),

            // onLongPress：長押し時の処理（削除ダイアログ表示）
            onLongPress: () {
              _showDeleteDialog(context, provider, transaction.id);
            },
          ),
        );
      },
    );
  }

  // =============================================================================
  // 削除確認ダイアログ
  // =============================================================================

  void _showDeleteDialog(
    BuildContext context,
    TransactionProvider provider,
    String id, // 削除対象の取引ID
  ) {
    // showDialog：モーダルダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この取引を削除しますか？'),
        actions: [
          // キャンセルボタン
          TextButton(
            onPressed: () => Navigator.pop(context), // ダイアログを閉じる
            child: const Text('キャンセル'),
          ),
          // 削除ボタン
          TextButton(
            onPressed: () {
              // 取引を削除
              provider.deleteTransaction(id);
              // ダイアログを閉じる
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

/*
UIコンポーネントと設計パターンの解説：

1. Scaffoldパターン
   - Material Designの基本構造
   - AppBar, Body, FloatingActionButtonの統一レイアウト

2. Consumer<T>パターン
   - 状態変更の自動検知とUI更新
   - 必要な部分のみ再ビルドしてパフォーマンス最適化

3. コンポーネント分割
   - _buildXXX()メソッドで機能ごとにUI部品を分離
   - 再利用性とメンテナンス性を向上

4. レスポンシブデザイン
   - Expanded, Flexible等でスペースを動的分配
   - 様々な画面サイズに対応

5. Material Design Guidelines
   - Card, ListTile等でMaterial Designの標準コンポーネントを使用
   - 一貫性のあるUXを実現

6. ユーザビリティの配慮
   - 長押しで削除（誤操作防止）
   - 確認ダイアログでさらなる安全性確保
   - 直感的なアイコンと色分け

7. 国際化対応
   - DateFormat('M/d (E)', 'ja')で日本語の曜日表示
   - NumberFormat('#,###')で数値の見やすい表示

この画面が家計簿アプリの中心となり、
ユーザーの日常的な操作のほとんどをここで行います。
*/
