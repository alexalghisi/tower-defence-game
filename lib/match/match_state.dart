import 'package:tower_defence/match/board.dart';
import 'package:tower_defence/match/field_point.dart';
import 'package:tower_defence/match/profiles.dart';

enum MatchOutcome { ongoing, won, lost }

enum WaveStatus { ready, active }

class Tower {
  const Tower({
    required this.id,
    required this.kind,
    required this.column,
    required this.row,
    required this.cooldown,
  });

  final String id;
  final TowerKind kind;
  final int column;
  final int row;
  final double cooldown;

  FieldPoint get origin => FieldPoint(column + 0.5, row + 0.5);

  Tower copyWith({double? cooldown}) {
    return Tower(
      id: id,
      kind: kind,
      column: column,
      row: row,
      cooldown: cooldown ?? this.cooldown,
    );
  }
}

class Enemy {
  const Enemy({
    required this.id,
    required this.kind,
    required this.progress,
    required this.health,
    required this.slowRemaining,
    required this.slowFactor,
  });

  final String id;
  final EnemyKind kind;
  final double progress;
  final double health;
  final double slowRemaining;
  final double slowFactor;

  Enemy copyWith({
    double? progress,
    double? health,
    double? slowRemaining,
    double? slowFactor,
  }) {
    return Enemy(
      id: id,
      kind: kind,
      progress: progress ?? this.progress,
      health: health ?? this.health,
      slowRemaining: slowRemaining ?? this.slowRemaining,
      slowFactor: slowFactor ?? this.slowFactor,
    );
  }
}

class Bolt {
  const Bolt({
    required this.id,
    required this.kind,
    required this.targetId,
    required this.position,
    required this.damage,
    required this.splash,
    required this.slowFactor,
    required this.slowDuration,
    required this.speed,
  });

  final String id;
  final TowerKind kind;
  final String targetId;
  final FieldPoint position;
  final double damage;
  final double splash;
  final double slowFactor;
  final double slowDuration;
  final double speed;

  Bolt copyWith({FieldPoint? position}) {
    return Bolt(
      id: id,
      kind: kind,
      targetId: targetId,
      position: position ?? this.position,
      damage: damage,
      splash: splash,
      slowFactor: slowFactor,
      slowDuration: slowDuration,
      speed: speed,
    );
  }
}

class MatchState {
  const MatchState({
    required this.board,
    required this.gold,
    required this.lives,
    required this.wave,
    required this.waveCount,
    required this.status,
    required this.outcome,
    required this.selected,
    required this.towers,
    required this.enemies,
    required this.bolts,
    required this.pending,
    required this.spawnTimer,
    required this.armTimer,
    required this.nextId,
  });

  final Board board;
  final int gold;
  final int lives;
  final int wave;
  final int waveCount;
  final WaveStatus status;
  final MatchOutcome outcome;
  final TowerKind selected;
  final List<Tower> towers;
  final List<Enemy> enemies;
  final List<Bolt> bolts;
  final List<EnemyKind> pending;
  final double spawnTimer;
  final double armTimer;
  final int nextId;

  MatchState copyWith({
    int? gold,
    int? lives,
    int? wave,
    WaveStatus? status,
    MatchOutcome? outcome,
    TowerKind? selected,
    List<Tower>? towers,
    List<Enemy>? enemies,
    List<Bolt>? bolts,
    List<EnemyKind>? pending,
    double? spawnTimer,
    double? armTimer,
    int? nextId,
  }) {
    return MatchState(
      board: board,
      gold: gold ?? this.gold,
      lives: lives ?? this.lives,
      wave: wave ?? this.wave,
      waveCount: waveCount,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      selected: selected ?? this.selected,
      towers: towers ?? this.towers,
      enemies: enemies ?? this.enemies,
      bolts: bolts ?? this.bolts,
      pending: pending ?? this.pending,
      spawnTimer: spawnTimer ?? this.spawnTimer,
      armTimer: armTimer ?? this.armTimer,
      nextId: nextId ?? this.nextId,
    );
  }
}
