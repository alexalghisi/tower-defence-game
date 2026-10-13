import 'dart:math' as math;

import 'package:tower_defence/match/field_point.dart';

class Cell {
  const Cell(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);
}

class Route {
  Route(List<Cell> corners) : this._(_centers(corners));

  Route._(this.points) : spans = _spans(points);

  final List<FieldPoint> points;
  final List<double> spans;

  double get length => spans.last;

  FieldPoint at(double distance) {
    if (points.isEmpty) {
      return const FieldPoint(0, 0);
    }
    if (distance <= 0) {
      return points.first;
    }
    if (distance >= length) {
      return points.last;
    }
    for (var i = 1; i < points.length; i++) {
      if (distance > spans[i]) {
        continue;
      }
      final span = spans[i] - spans[i - 1];
      final portion = span == 0 ? 0.0 : (distance - spans[i - 1]) / span;
      final from = points[i - 1];
      final to = points[i];
      return FieldPoint(
        from.x + (to.x - from.x) * portion,
        from.y + (to.y - from.y) * portion,
      );
    }
    return points.last;
  }

  static List<FieldPoint> _centers(List<Cell> corners) {
    return [
      for (final cell in corners) FieldPoint(cell.column + 0.5, cell.row + 0.5),
    ];
  }

  static List<double> _spans(List<FieldPoint> points) {
    final spans = <double>[0];
    for (var i = 1; i < points.length; i++) {
      spans.add(spans.last + points[i].distanceTo(points[i - 1]));
    }
    return spans;
  }
}

class Board {
  Board({
    required this.columns,
    required this.rows,
    required List<Cell> corners,
  }) : route = Route(corners),
       path = _trace(corners);

  final int columns;
  final int rows;
  final Route route;
  final Set<Cell> path;

  bool contains(int column, int row) =>
      column >= 0 && row >= 0 && column < columns && row < rows;

  bool canBuild(int column, int row) =>
      contains(column, row) && !path.contains(Cell(column, row));

  static Board campaign() {
    return Board(
      columns: 12,
      rows: 7,
      corners: const [
        Cell(0, 1),
        Cell(9, 1),
        Cell(9, 3),
        Cell(2, 3),
        Cell(2, 5),
        Cell(11, 5),
      ],
    );
  }

  static Set<Cell> _trace(List<Cell> corners) {
    final cells = <Cell>{};
    if (corners.isEmpty) {
      return cells;
    }
    cells.add(corners.first);
    for (var i = 1; i < corners.length; i++) {
      final from = corners[i - 1];
      final to = corners[i];
      final columnDelta = to.column - from.column;
      final rowDelta = to.row - from.row;
      final steps = math.max(columnDelta.abs(), rowDelta.abs());
      if (steps == 0) {
        continue;
      }
      for (var step = 0; step <= steps; step++) {
        cells.add(
          Cell(
            from.column + (columnDelta * step) ~/ steps,
            from.row + (rowDelta * step) ~/ steps,
          ),
        );
      }
    }
    return cells;
  }
}
