import 'package:elements/app/app.dart';
import 'package:elements/game/element_shift_game.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Play opens GameWidget with move/jump HUD', (tester) async {
    await tester.pumpWidget(const ElementShiftApp());
    await tester.pump();

    expect(find.text('Element Shift'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GameWidget<ElementShiftGame>), findsOneWidget);
    expect(find.byTooltip('Jump'), findsOneWidget);
    expect(find.byTooltip('Pause'), findsOneWidget);
  });
}
