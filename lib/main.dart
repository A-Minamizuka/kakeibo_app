import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';

// アプリのエントリーポイント（起動時に最初に実行される関数）
void main() {
  // MyAppウィジェットを実行してアプリを起動
  runApp(const MyApp());
}

// アプリ全体の設定を行うルートウィジェット
// StatelessWidgetは状態を持たない（変化しない）ウィジェット
class MyApp extends StatelessWidget {
  // constコンストラクタ：コンパイル時に値が決定される、パフォーマンスが良い
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider：Provider状態管理の基本
    // アプリ全体でTransactionProviderの状態を共有できるようにする
    return ChangeNotifierProvider(
      // create：Providerのインスタンスを作成
      // ..loadTransactions()：カスケード記法で初期データを読み込み
      create: (context) => TransactionProvider()..loadTransactions(),

      // child：Providerの配下に置くウィジェット
      child: MaterialApp(
        title: '家計簿アプリ', // アプリのタイトル（タスクマネージャーなどで表示される）
        // テーマ設定：アプリ全体のデザインを統一
        theme: ThemeData(
          // Material Design 3のカラースキーム
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, // ベースカラー
            brightness: Brightness.light, // ライトモード
          ),
          useMaterial3: true, // Material Design 3を使用
        ),

        // 国際化（i18n）の設定：日本語対応
        localizationsDelegates: const [
          // 各種ローカライゼーション（言語設定）のデリゲート
          GlobalMaterialLocalizations.delegate, // Material Design要素の翻訳
          GlobalWidgetsLocalizations.delegate, // 基本ウィジェットの翻訳
          GlobalCupertinoLocalizations.delegate, // iOSスタイル要素の翻訳
        ],

        // サポートする言語の設定
        supportedLocales: const [
          Locale('ja', 'JP'), // 日本語（日本）
          Locale('en', 'US'), // 英語（アメリカ）
        ],
        locale: const Locale('ja', 'JP'), // デフォルトロケールを日本語に設定

        home: const HomeScreen(), // 起動時に表示する最初の画面
        debugShowCheckedModeBanner: false, // 右上の「DEBUG」バナーを非表示
      ),
    );
  }
}
