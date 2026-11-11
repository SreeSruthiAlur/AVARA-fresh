// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avara_astrology_trial/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    dotenv.testLoad(
      fileInput: 'GEMINI_API_KEY=AQ.test\nAVARA_API_BASE_URL=http://127.0.0.1:8000/api/v1',
    );
    await tester.pumpWidget(const AvaraApp());
    expect(find.byType(AvaraApp), findsOneWidget);
  });
}
