import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tower_defence/keepward_app.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/view/board_metrics.dart';
import 'package:tower_defence/view/keepward_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a player builds an archer and sends the first wave', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KeepwardApp());
    await tester.pump();

    await tester.tap(find.byKey(KeepwardKeys.tower(TowerKind.archer)));
    await tester.pump();

    final board = tester.getRect(find.byKey(KeepwardKeys.board));
    final metrics = BoardMetrics.fit(board.size, 12, 7);
    await tester.tapAt(board.topLeft + metrics.center(0, 0));
    await tester.pump();

    expect(find.text('110'), findsOneWidget);

    await tester.tap(find.byKey(KeepwardKeys.send));
    await tester.pump();
    expect(find.text('1/8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
