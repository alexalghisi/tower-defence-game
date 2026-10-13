import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:tower_defence/match/board.dart';
import 'package:tower_defence/match/field_point.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/view/board_metrics.dart';

class BoardPainter extends CustomPainter {
  const BoardPainter({
    required this.state,
    required this.metrics,
    required this.hover,
  });

  final MatchState state;
  final BoardMetrics metrics;
  final Cell? hover;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF10160E),
    );
    for (var row = 0; row < state.board.rows; row++) {
      for (var column = 0; column < state.board.columns; column++) {
        _tile(canvas, column, row);
      }
    }
    _gate(canvas);
    for (final tower in state.towers) {
      _tower(canvas, tower, _aim(tower));
    }
    for (final enemy in state.enemies) {
      _enemy(canvas, enemy);
    }
    for (final bolt in state.bolts) {
      _bolt(canvas, bolt);
    }
    _ghost(canvas);
  }

  void _tile(Canvas canvas, int column, int row) {
    final rect = metrics.tile(column, row).deflate(metrics.cell * 0.04);
    final onPath = state.board.path.contains(Cell(column, row));
    final grass = (column + row).isEven
        ? const Color(0xFF2C5528)
        : const Color(0xFF346230);
    final radius = Radius.circular(metrics.cell * 0.16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = onPath ? const Color(0xFF6E522C) : grass,
    );
    if (onPath) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(metrics.cell * 0.14),
          Radius.circular(metrics.cell * 0.1),
        ),
        Paint()..color = const Color(0xFFC6A15A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(metrics.cell * 0.28),
          Radius.circular(metrics.cell * 0.08),
        ),
        Paint()..color = const Color(0xFFE4C98A),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            rect.left + metrics.cell * 0.08,
            rect.top + metrics.cell * 0.06,
            rect.width * 0.55,
            metrics.cell * 0.08,
          ),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0x334E8A42),
      );
      if ((column * 5 + row * 3) % 7 == 0) {
        canvas.drawCircle(
          metrics.center(column, row) +
              Offset(metrics.cell * 0.16, metrics.cell * 0.12),
          metrics.cell * 0.045,
          Paint()..color = const Color(0xFF1E3A1C),
        );
      }
    }
  }

  void _gate(Canvas canvas) {
    final at = _map(state.board.route.points.last);
    final post = metrics.cell * 0.16;
    final door = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: at + Offset(metrics.cell * 0.22, metrics.cell * 0.02),
        width: metrics.cell * 0.42,
        height: metrics.cell * 0.78,
      ),
      Radius.circular(metrics.cell * 0.08),
    );
    canvas.drawRRect(door, Paint()..color = const Color(0xFF3A3124));
    canvas.drawRRect(
      door,
      Paint()
        ..color = const Color(0xFFD7A441)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: at + Offset(metrics.cell * 0.22 + side * post * 1.7, 0),
            width: post,
            height: metrics.cell * 0.92,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF8A7A5C),
      );
    }
    canvas.drawCircle(
      at + Offset(metrics.cell * 0.22, -metrics.cell * 0.16),
      post * 0.28,
      Paint()..color = const Color(0xFFF0D56A),
    );
  }

  void _ghost(Canvas canvas) {
    final cell = hover;
    if (cell == null) {
      return;
    }
    final profile = towerProfiles[state.selected]!;
    final open =
        state.board.canBuild(cell.column, cell.row) &&
        state.towers.every(
          (tower) => tower.column != cell.column || tower.row != cell.row,
        ) &&
        state.gold >= profile.cost &&
        state.outcome == MatchOutcome.ongoing;
    final tone = open ? const Color(0x553C8F4A) : const Color(0x66A33B32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        metrics.tile(cell.column, cell.row).deflate(1),
        Radius.circular(metrics.cell * 0.12),
      ),
      Paint()..color = tone,
    );
    canvas.drawCircle(
      metrics.center(cell.column, cell.row),
      profile.range * metrics.cell,
      Paint()
        ..color = tone.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _tower(Canvas canvas, Tower tower, double angle) {
    final at = _map(tower.origin);
    final radius = metrics.cell * 0.32;
    canvas.drawCircle(
      at,
      radius * 1.15,
      Paint()..color = const Color(0xFF24301C),
    );
    canvas.drawCircle(
      at,
      radius * 1.15,
      Paint()
        ..color = const Color(0xFFD7A441)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, radius * 0.45),
        width: radius * 1.8,
        height: radius * 0.65,
      ),
      Paint()..color = const Color(0x33000000),
    );
    switch (tower.kind) {
      case TowerKind.archer:
        _archer(canvas, at, radius, angle);
      case TowerKind.cannon:
        _cannon(canvas, at, radius, angle);
      case TowerKind.frost:
        _frost(canvas, at, radius);
    }
  }

  void _archer(Canvas canvas, Offset at, double radius, double angle) {
    canvas.drawCircle(at, radius, Paint()..color = const Color(0xFF7A4A28));
    canvas.drawCircle(
      at + Offset(0, radius * 0.12),
      radius * 0.55,
      Paint()..color = const Color(0xFF5C3418),
    );
    final roof = Path()
      ..moveTo(at.dx, at.dy - radius * 1.35)
      ..lineTo(at.dx + radius * 1.05, at.dy - radius * 0.2)
      ..lineTo(at.dx - radius * 1.05, at.dy - radius * 0.2)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF1F6A62));
    canvas.drawPath(
      roof,
      Paint()
        ..color = const Color(0xFFD7A441)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(radius * 0.7, 0),
          width: radius * 1.1,
          height: radius * 0.22,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF2A2118),
    );
    canvas.restore();
  }

  void _cannon(Canvas canvas, Offset at, double radius, double angle) {
    canvas.drawCircle(at, radius, Paint()..color = const Color(0xFF596068));
    canvas.drawCircle(
      at,
      radius * 0.62,
      Paint()..color = const Color(0xFFC6A15A),
    );
    canvas.drawCircle(
      at,
      radius * 0.4,
      Paint()..color = const Color(0xFF2A3036),
    );
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(radius * 0.85, 0),
          width: radius * 1.3,
          height: radius * 0.36,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1E2328),
    );
    canvas.restore();
  }

  void _frost(Canvas canvas, Offset at, double radius) {
    final gem = Path()
      ..moveTo(at.dx, at.dy - radius * 1.15)
      ..lineTo(at.dx + radius * 0.85, at.dy)
      ..lineTo(at.dx, at.dy + radius * 1.05)
      ..lineTo(at.dx - radius * 0.85, at.dy)
      ..close();
    canvas.drawCircle(
      at + Offset(0, radius * 0.15),
      radius * 0.72,
      Paint()..color = const Color(0xFF16343C),
    );
    canvas.drawPath(gem, Paint()..color = const Color(0xFF9EE0EA));
    canvas.drawPath(
      gem,
      Paint()
        ..color = const Color(0xFF1E4C57)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _enemy(Canvas canvas, Enemy enemy) {
    final at = _map(state.board.route.at(enemy.progress));
    final profile = enemyProfiles[enemy.kind]!;
    final radius = switch (enemy.kind) {
      EnemyKind.grunt => metrics.cell * 0.2,
      EnemyKind.runner => metrics.cell * 0.15,
      EnemyKind.brute => metrics.cell * 0.28,
    };
    final fill = switch (enemy.kind) {
      EnemyKind.grunt => const Color(0xFF8C4E32),
      EnemyKind.runner => const Color(0xFFE08A32),
      EnemyKind.brute => const Color(0xFF7A2434),
    };
    final stretch = enemy.kind == EnemyKind.runner ? 1.35 : 1.05;
    canvas.drawOval(
      Rect.fromCenter(
        center: at + Offset(0, radius * 0.35),
        width: radius * 2.1,
        height: radius * 0.7,
      ),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: at,
          width: radius * 2 * stretch,
          height: radius * 2,
        ),
        Radius.circular(radius),
      ),
      Paint()..color = fill,
    );
    if (enemy.kind == EnemyKind.brute) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: at + Offset(0, -radius * 0.15),
            width: radius * 1.7,
            height: radius * 0.55,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF4A1822),
      );
    }
    canvas.drawCircle(
      at + Offset(-radius * 0.28, -radius * 0.15),
      radius * 0.12,
      Paint()..color = const Color(0xFFF4E2C4),
    );
    canvas.drawCircle(
      at + Offset(radius * 0.28, -radius * 0.15),
      radius * 0.12,
      Paint()..color = const Color(0xFFF4E2C4),
    );
    final ratio = (enemy.health / profile.health).clamp(0, 1).toDouble();
    final bar = Rect.fromCenter(
      center: at + Offset(0, -radius - metrics.cell * 0.12),
      width: metrics.cell * 0.62,
      height: metrics.cell * 0.08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(2)),
      Paint()..color = const Color(0xFF2A2118),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.left, bar.top, bar.width * ratio, bar.height),
        const Radius.circular(2),
      ),
      Paint()
        ..color = ratio > 0.45
            ? const Color(0xFF7FA36A)
            : const Color(0xFFC45B4A),
    );
  }

  void _bolt(Canvas canvas, Bolt bolt) {
    final at = _map(bolt.position);
    final color = switch (bolt.kind) {
      TowerKind.archer => const Color(0xFFF0D56A),
      TowerKind.cannon => const Color(0xFF2B241C),
      TowerKind.frost => const Color(0xFFD5F4FA),
    };
    final radius = metrics.cell * (bolt.kind == TowerKind.cannon ? 0.13 : 0.08);
    canvas.drawCircle(
      at,
      radius * 1.8,
      Paint()..color = color.withValues(alpha: 0.35),
    );
    canvas.drawCircle(at, radius, Paint()..color = color);
    if (bolt.kind == TowerKind.cannon) {
      canvas.drawCircle(
        at,
        radius * 0.45,
        Paint()..color = const Color(0xFFE07A32),
      );
    }
  }

  double _aim(Tower tower) {
    Enemy? nearest;
    var best = double.infinity;
    for (final enemy in state.enemies) {
      final distance = state.board.route
          .at(enemy.progress)
          .distanceTo(tower.origin);
      if (distance < best) {
        best = distance;
        nearest = enemy;
      }
    }
    final target = nearest == null
        ? state.board.route.points.first
        : state.board.route.at(nearest.progress);
    final delta = target - tower.origin;
    return math.atan2(delta.y, delta.x);
  }

  Offset _map(FieldPoint point) {
    return Offset(
      metrics.originX + point.x * metrics.cell,
      metrics.originY + point.y * metrics.cell,
    );
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}
