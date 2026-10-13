import 'dart:math' as math;
import 'dart:ui';

import 'package:tower_defence/match/board.dart';

class BoardMetrics {
  const BoardMetrics({
    required this.cell,
    required this.originX,
    required this.originY,
    required this.columns,
    required this.rows,
  });

  final double cell;
  final double originX;
  final double originY;
  final int columns;
  final int rows;

  factory BoardMetrics.fit(Size size, int columns, int rows) {
    final cell = math.min(size.width / columns, size.height / rows);
    final usedWidth = cell * columns;
    final usedHeight = cell * rows;
    return BoardMetrics(
      cell: cell,
      originX: (size.width - usedWidth) / 2,
      originY: (size.height - usedHeight) / 2,
      columns: columns,
      rows: rows,
    );
  }

  Offset center(int column, int row) {
    return Offset(
      originX + (column + 0.5) * cell,
      originY + (row + 0.5) * cell,
    );
  }

  Rect tile(int column, int row) {
    return Rect.fromLTWH(
      originX + column * cell,
      originY + row * cell,
      cell,
      cell,
    );
  }

  Cell? cellAt(Offset local) {
    if (cell <= 0) {
      return null;
    }
    final column = ((local.dx - originX) / cell).floor();
    final row = ((local.dy - originY) / cell).floor();
    if (column < 0 || row < 0 || column >= columns || row >= rows) {
      return null;
    }
    return Cell(column, row);
  }
}
