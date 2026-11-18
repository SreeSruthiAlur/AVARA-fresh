import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avara_astrology_trial/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    dotenv.testLoad(
      fileInput:
          'GROQ_API_KEY=gsk_test\nGEMINI_API_KEY=AQ.test\nAVARA_API_BASE_URL=http://127.0.0.1:8000/api/v1',
    );
    await tester.pumpWidget(const AvaraApp());
    expect(find.byType(AvaraApp), findsOneWidget);
  });
}
