import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tower_defence/match/board.dart';
import 'package:tower_defence/view/board_metrics.dart';

void main() {
  test('a cell center maps back to that cell', () {
    final metrics = BoardMetrics.fit(const Size(240, 140), 12, 7);
    final center = metrics.center(3, 2);
    expect(metrics.cellAt(center), const Cell(3, 2));
  });

  test('points outside the grid are ignored', () {
    final metrics = BoardMetrics.fit(const Size(240, 140), 12, 7);
    expect(metrics.cellAt(const Offset(-4, 8)), isNull);
    expect(
      metrics.cellAt(
        Offset(metrics.originX + metrics.cell * 20, metrics.originY),
      ),
      isNull,
    );
  });
}
