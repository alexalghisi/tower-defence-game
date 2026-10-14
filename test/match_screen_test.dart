import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tower_defence/keepward_app.dart';
import 'package:tower_defence/match/match_controller.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/match/simulator.dart';
import 'package:tower_defence/view/board_metrics.dart';
import 'package:tower_defence/view/keepward_keys.dart';

import 'surface.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    MatchController? controller,
    Size size = const Size(960, 640),
  }) async {
    useSurface(tester, size);
    await tester.pumpWidget(
      KeepwardApp(controller: controller, animate: false),
    );
    await tester.pump();
  }

  Future<void> tapCell(WidgetTester tester, int column, int row) async {
    final board = tester.getRect(find.byKey(KeepwardKeys.board));
    final metrics = BoardMetrics.fit(board.size, 12, 7);
    await tester.tapAt(board.topLeft + metrics.center(column, row));
    await tester.pump();
  }

  testWidgets('the opening board shows gold, lives and an empty wave', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Keepward'), findsOneWidget);
    expect(
      find.text('Build on the grass. Stop the column before the gate.'),
      findsOneWidget,
    );
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Lives'), findsOneWidget);
    expect(find.text('Wave'), findsOneWidget);
    expect(find.text('160'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('0/8'), findsOneWidget);
    expect(find.text('Battle board'), findsNothing);
    expect(find.bySemanticsLabel('Battle board'), findsOneWidget);
  });

  testWidgets('grass takes the selected tower and the road does not', (
    tester,
  ) async {
    await open(tester);
    await tapCell(tester, 0, 1);
    expect(find.text('160'), findsOneWidget);
    await tester.tap(find.byKey(KeepwardKeys.tower(TowerKind.cannon)));
    await tester.pump();
    await tapCell(tester, 0, 0);
    expect(find.text('60'), findsOneWidget);
    await tapCell(tester, 0, 0);
    expect(find.text('60'), findsOneWidget);
  });

  testWidgets('a wave starts on its own when the pause ends', (tester) async {
    final controller = MatchController(
      simulator: MatchSimulator(
        config: MatchConfig(armDelay: 1, roster: (_) => [EnemyKind.grunt]),
      ),
    );
    await open(tester, controller: controller);
    controller.tick(0.4);
    await tester.pump();
    expect(find.text('0/8'), findsOneWidget);
    controller.tick(0.7);
    await tester.pump();
    expect(find.text('1/8'), findsOneWidget);
    expect(find.text('Wave in progress'), findsOneWidget);
  });

  testWidgets('sending a wave marks it in progress', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(KeepwardKeys.send));
    await tester.pump();
    expect(find.text('1/8'), findsOneWidget);
    expect(find.text('Wave in progress'), findsOneWidget);
  });

  testWidgets('a breach can be played again', (tester) async {
    final controller = MatchController(
      simulator: MatchSimulator(
        config: MatchConfig(
          lives: 1,
          waves: 1,
          roster: (_) => [EnemyKind.grunt],
        ),
      ),
    );
    await open(tester, controller: controller);
    controller.sendWave();
    controller.tick(40);
    await tester.pump();
    expect(find.text('Defeat'), findsOneWidget);
    expect(find.text('The gate fell.'), findsOneWidget);
    await tester.tap(find.byKey(KeepwardKeys.restart));
    await tester.pump();
    expect(find.text('Defeat'), findsNothing);
    expect(find.text('160'), findsOneWidget);
    expect(controller.state.outcome, MatchOutcome.ongoing);
  });

  testWidgets('the layout holds on a phone and a wide window', (tester) async {
    await open(tester, size: const Size(390, 844));
    expect(tester.takeException(), isNull);
    await open(tester, size: const Size(1280, 800));
    expect(tester.takeException(), isNull);
  });
}
