import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_app/app.dart';

void main() {
  testWidgets('Nightlife app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NightlifeApp());

    expect(find.byType(NightlifeApp), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}