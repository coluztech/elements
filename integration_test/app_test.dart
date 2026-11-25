import 'package:elements/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to home', (tester) async {
    await tester.pumpWidget(const ElementShiftApp());
    await tester.pumpAndSettle();
    expect(find.text('Element Shift'), findsOneWidget);
  });
}
