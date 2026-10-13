import 'dart:math' as math;

import 'package:tower_defence/match/board.dart';
import 'package:tower_defence/match/field_point.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';

typedef WaveRoster = List<EnemyKind> Function(int wave);

class MatchConfig {
  const MatchConfig({
    this.gold = 160,
    this.lives = 20,
    this.waves = 8,
    this.spawnGap = 0.7,
    this.clearBonus = 25,
    this.roster = campaignRoster,
  });

  final int gold;
  final int lives;
  final int waves;
  final double spawnGap;
  final int clearBonus;
  final WaveRoster roster;
}

class MatchSimulator {
  MatchSimulator({this.config = const MatchConfig(), Board? board})
    : board = board ?? Board.campaign();

  final MatchConfig config;
  final Board board;

  MatchState initial() {
    return MatchState(
      board: board,
      gold: config.gold,
      lives: config.lives,
      wave: 0,
      waveCount: config.waves,
      status: WaveStatus.ready,
      outcome: MatchOutcome.ongoing,
      selected: TowerKind.archer,
      towers: const [],
      enemies: const [],
      bolts: const [],
      pending: const [],
      spawnTimer: 0,
      nextId: 1,
    );
  }

  MatchState select(MatchState state, TowerKind kind) {
    if (state.selected == kind) {
      return state;
    }
    return state.copyWith(selected: kind);
  }

  MatchState place(MatchState state, int column, int row) {
    if (state.outcome != MatchOutcome.ongoing ||
        !state.board.canBuild(column, row)) {
      return state;
    }
    for (final tower in state.towers) {
      if (tower.column == column && tower.row == row) {
        return state;
      }
    }
    final profile = towerProfiles[state.selected]!;
    if (state.gold < profile.cost) {
      return state;
    }
    return state.copyWith(
      gold: state.gold - profile.cost,
      nextId: state.nextId + 1,
      towers: [
        ...state.towers,
        Tower(
          id: 't${state.nextId}',
          kind: state.selected,
          column: column,
          row: row,
          cooldown: 0,
        ),
      ],
    );
  }

  MatchState sendWave(MatchState state) {
    if (state.outcome != MatchOutcome.ongoing ||
        state.status != WaveStatus.ready) {
      return state;
    }
    if (state.wave >= config.waves) {
      return state;
    }
    final wave = state.wave + 1;
    return state.copyWith(
      wave: wave,
      status: WaveStatus.active,
      pending: config.roster(wave),
      spawnTimer: 0,
    );
  }

  MatchState step(MatchState state, double dt) {
    if (state.outcome != MatchOutcome.ongoing || dt <= 0) {
      return state;
    }

    final pending = [...state.pending];
    var enemies = [...state.enemies];
    var bolts = [...state.bolts];
    var gold = state.gold;
    var lives = state.lives;
    var nextId = state.nextId;
    var timer = state.spawnTimer;

    if (state.status == WaveStatus.active) {
      timer -= dt;
      while (pending.isNotEmpty && timer <= 0) {
        final kind = pending.removeAt(0);
        final profile = enemyProfiles[kind]!;
        enemies.add(
          Enemy(
            id: 'e$nextId',
            kind: kind,
            progress: 0,
            health: profile.health.toDouble(),
            slowRemaining: 0,
            slowFactor: 1,
          ),
        );
        nextId += 1;
        timer += config.spawnGap;
      }
    }

    final stayed = <Enemy>[];
    for (final enemy in enemies) {
      final profile = enemyProfiles[enemy.kind]!;
      final pace = enemy.slowRemaining > 0
          ? profile.speed * enemy.slowFactor
          : profile.speed;
      final progress = enemy.progress + pace * dt;
      if (progress >= state.board.route.length) {
        lives -= profile.lives;
        continue;
      }
      stayed.add(
        enemy.copyWith(
          progress: progress,
          slowRemaining: math.max(0, enemy.slowRemaining - dt),
        ),
      );
    }
    enemies = stayed;

    if (lives <= 0) {
      return state.copyWith(
        gold: gold,
        lives: 0,
        enemies: enemies,
        bolts: const [],
        pending: const [],
        spawnTimer: timer,
        nextId: nextId,
        outcome: MatchOutcome.lost,
        status: WaveStatus.ready,
      );
    }

    final towers = <Tower>[];
    for (final tower in state.towers) {
      final profile = towerProfiles[tower.kind]!;
      var cooldown = tower.cooldown - dt;
      if (cooldown <= 0) {
        final target = _acquire(state.board, enemies, tower, profile.range);
        if (target == null) {
          cooldown = 0;
        } else {
          bolts.add(
            Bolt(
              id: 'b$nextId',
              kind: tower.kind,
              targetId: target.id,
              position: tower.origin,
              damage: profile.damage,
              splash: profile.splash,
              slowFactor: profile.slowFactor,
              slowDuration: profile.slowDuration,
              speed: profile.shotSpeed,
            ),
          );
          nextId += 1;
          cooldown += profile.interval;
        }
      }
      towers.add(tower.copyWith(cooldown: cooldown));
    }

    final flying = <Bolt>[];
    for (final bolt in bolts) {
      final index = enemies.indexWhere((enemy) => enemy.id == bolt.targetId);
      if (index < 0) {
        continue;
      }
      final aim = state.board.route.at(enemies[index].progress);
      final delta = aim - bolt.position;
      final distance = delta.length;
      final travel = bolt.speed * dt;
      if (distance <= math.max(travel, 0.08)) {
        enemies = _impact(
          state.board,
          enemies,
          bolt,
          aim,
          (bounty) => gold += bounty,
        );
      } else {
        flying.add(
          bolt.copyWith(position: bolt.position + delta * (travel / distance)),
        );
      }
    }

    var status = state.status;
    var outcome = state.outcome;
    if (status == WaveStatus.active &&
        pending.isEmpty &&
        enemies.isEmpty &&
        flying.isEmpty) {
      gold += config.clearBonus + state.wave * 5;
      status = WaveStatus.ready;
      if (state.wave >= config.waves) {
        outcome = MatchOutcome.won;
      }
    }

    return state.copyWith(
      gold: gold,
      lives: lives,
      status: status,
      outcome: outcome,
      towers: towers,
      enemies: enemies,
      bolts: flying,
      pending: pending,
      spawnTimer: timer,
      nextId: nextId,
    );
  }

  Enemy? _acquire(Board board, List<Enemy> enemies, Tower tower, double range) {
    Enemy? best;
    for (final enemy in enemies) {
      final distance = board.route.at(enemy.progress).distanceTo(tower.origin);
      if (distance > range) {
        continue;
      }
      if (best == null || enemy.progress > best.progress) {
        best = enemy;
      }
    }
    return best;
  }

  List<Enemy> _impact(
    Board board,
    List<Enemy> enemies,
    Bolt bolt,
    FieldPoint impact,
    void Function(int bounty) pay,
  ) {
    final survivors = <Enemy>[];
    for (final enemy in enemies) {
      final direct = enemy.id == bolt.targetId;
      final splashed =
          bolt.splash > 0 &&
          board.route.at(enemy.progress).distanceTo(impact) <= bolt.splash;
      if (!direct && !splashed) {
        survivors.add(enemy);
        continue;
      }
      final wounded = _wound(enemy, bolt);
      if (wounded.health <= 0) {
        pay(enemyProfiles[enemy.kind]!.bounty);
        continue;
      }
      survivors.add(wounded);
    }
    return survivors;
  }

  Enemy _wound(Enemy enemy, Bolt bolt) {
    var slowRemaining = enemy.slowRemaining;
    var slowFactor = enemy.slowFactor;
    if (bolt.slowDuration > 0) {
      slowRemaining = math.max(slowRemaining, bolt.slowDuration);
      if (enemy.slowRemaining <= 0 || bolt.slowFactor < slowFactor) {
        slowFactor = bolt.slowFactor;
      }
    }
    return enemy.copyWith(
      health: enemy.health - bolt.damage,
      slowRemaining: slowRemaining,
      slowFactor: slowFactor,
    );
  }
}
