import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/main.dart';

void main() {
  testWidgets('ホーム画面のタイトルが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('家計簿アプリ'), findsOneWidget);
  });
}

