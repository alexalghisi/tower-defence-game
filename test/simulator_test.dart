import 'package:flutter_test/flutter_test.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/match/simulator.dart';

List<EnemyKind> _one(int wave) => [EnemyKind.grunt];

List<EnemyKind> _pair(int wave) => [EnemyKind.grunt, EnemyKind.grunt];

void main() {
  test('a fresh match starts before the first wave', () {
    final state = MatchSimulator().initial();
    expect(state.gold, 160);
    expect(state.lives, 20);
    expect(state.wave, 0);
    expect(state.waveCount, 8);
    expect(state.selected, TowerKind.archer);
    expect(state.outcome, MatchOutcome.ongoing);
  });

  test(
    'towers can be built on grass and not on the road or an occupied tile',
    () {
      final simulator = MatchSimulator();
      final opened = simulator.initial();
      expect(simulator.place(opened, 0, 1).towers, isEmpty);
      expect(simulator.place(opened, -1, 0), same(opened));

      final placed = simulator.place(opened, 0, 0);
      expect(placed.gold, 110);
      expect(placed.towers.single.kind, TowerKind.archer);
      expect(simulator.place(placed, 0, 0).towers, hasLength(1));

      final poor = simulator.place(opened.copyWith(gold: 10), 0, 0);
      expect(poor.gold, 10);
      expect(poor.towers, isEmpty);
    },
  );

  test('the selected tower decides the price', () {
    final simulator = MatchSimulator();
    final state = simulator.place(
      simulator.select(simulator.initial(), TowerKind.frost),
      0,
      0,
    );
    expect(state.gold, 85);
    expect(state.towers.single.kind, TowerKind.frost);
  });

  test('a second send is ignored while a wave is marching', () {
    final simulator = MatchSimulator(
      config: MatchConfig(roster: _one, waves: 2),
    );
    final marching = simulator.sendWave(simulator.initial());
    expect(marching.wave, 1);
    expect(marching.pending, [EnemyKind.grunt]);
    expect(simulator.sendWave(marching).wave, 1);
  });

  test(
    'grunts that reach the gate cost a life, and two of them can end the match',
    () {
      final simulator = MatchSimulator(
        config: MatchConfig(lives: 1, waves: 1, roster: _pair),
      );
      final breached = simulator.step(
        simulator.sendWave(simulator.initial()),
        40,
      );
      expect(breached.outcome, MatchOutcome.lost);
      expect(breached.lives, 0);
      expect(breached.pending, isEmpty);
      expect(simulator.place(breached, 0, 0).towers, isEmpty);
    },
  );

  test('a brute takes two lives', () {
    final simulator = MatchSimulator(
      config: MatchConfig(lives: 5, waves: 2, roster: (_) => [EnemyKind.brute]),
    );
    final breached = simulator.step(
      simulator.sendWave(simulator.initial()),
      80,
    );
    expect(breached.lives, 3);
    expect(breached.outcome, MatchOutcome.ongoing);
  });

  test('an archer bolt drops a wounded grunt and pays the bounty', () {
    final simulator = MatchSimulator();
    var state = simulator.initial().copyWith(
      wave: 1,
      status: WaveStatus.active,
      towers: [
        const Tower(
          id: 't1',
          kind: TowerKind.archer,
          column: 0,
          row: 0,
          cooldown: 0,
        ),
      ],
      enemies: [
        const Enemy(
          id: 'e1',
          kind: EnemyKind.grunt,
          progress: 0,
          health: 14,
          slowRemaining: 0,
          slowFactor: 1,
        ),
      ],
    );
    state = simulator.step(state, 0.05);
    expect(state.bolts, hasLength(1));
    state = simulator.step(state, 0.25);
    expect(state.enemies, isEmpty);
    expect(state.bolts, isEmpty);
    expect(state.gold, 198);
    expect(state.status, WaveStatus.ready);
    expect(state.outcome, MatchOutcome.ongoing);
  });

  test('frost cuts the pace of a survivor', () {
    final simulator = MatchSimulator();
    var state = simulator.initial().copyWith(
      wave: 1,
      status: WaveStatus.active,
      towers: [
        const Tower(
          id: 't1',
          kind: TowerKind.frost,
          column: 0,
          row: 0,
          cooldown: 0,
        ),
      ],
      enemies: [
        const Enemy(
          id: 'e1',
          kind: EnemyKind.grunt,
          progress: 0,
          health: 80,
          slowRemaining: 0,
          slowFactor: 1,
        ),
      ],
    );
    state = simulator.step(state, 0.05);
    state = simulator.step(state, 0.25);
    final slowed = state.enemies.single;
    expect(slowed.slowRemaining, greaterThan(0));
    expect(slowed.health, lessThan(80));
    final before = slowed.progress;
    state = simulator.step(state, 1);
    expect(state.enemies.single.progress - before, closeTo(1.15 * 0.5, 0.08));
  });

  test('cannon splash wounds a neighbour', () {
    final simulator = MatchSimulator();
    var state = simulator.initial().copyWith(
      wave: 1,
      status: WaveStatus.active,
      towers: [
        const Tower(
          id: 't1',
          kind: TowerKind.cannon,
          column: 0,
          row: 0,
          cooldown: 0,
        ),
      ],
      enemies: [
        const Enemy(
          id: 'e1',
          kind: EnemyKind.grunt,
          progress: 0,
          health: 80,
          slowRemaining: 0,
          slowFactor: 1,
        ),
        const Enemy(
          id: 'e2',
          kind: EnemyKind.grunt,
          progress: 0.3,
          health: 80,
          slowRemaining: 0,
          slowFactor: 1,
        ),
      ],
    );
    state = simulator.step(state, 0.05);
    state = simulator.step(state, 0.3);
    expect(state.enemies, hasLength(2));
    expect(state.enemies.every((enemy) => enemy.health < 80), isTrue);
  });

  test('clearing the last wave pays once and wins', () {
    final simulator = MatchSimulator(
      config: const MatchConfig(waves: 1, roster: _empty),
    );
    var state = simulator.step(simulator.sendWave(simulator.initial()), 0.01);
    expect(state.outcome, MatchOutcome.won);
    expect(state.gold, 190);
    state = simulator.step(state, 1);
    expect(state.gold, 190);
    expect(simulator.sendWave(state).outcome, MatchOutcome.won);
  });
}

List<EnemyKind> _empty(int wave) => const [];
