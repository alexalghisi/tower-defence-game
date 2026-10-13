import 'dart:math' as math;

class FieldPoint {
  const FieldPoint(this.x, this.y);

  final double x;
  final double y;

  FieldPoint operator +(FieldPoint other) =>
      FieldPoint(x + other.x, y + other.y);

  FieldPoint operator -(FieldPoint other) =>
      FieldPoint(x - other.x, y - other.y);

  FieldPoint operator *(double scale) => FieldPoint(x * scale, y * scale);

  double get length => math.sqrt(x * x + y * y);

  double distanceTo(FieldPoint other) => (this - other).length;
}
