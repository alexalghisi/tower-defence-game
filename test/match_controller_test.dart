import 'package:flutter_test/flutter_test.dart';
import 'package:tower_defence/match/match_controller.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/match/simulator.dart';

void main() {
  test('tick advances the match and notifies once per call', () {
    final controller = MatchController(
      simulator: MatchSimulator(
        config: MatchConfig(
          lives: 1,
          waves: 1,
          roster: (_) => [EnemyKind.grunt],
        ),
      ),
    );
    var notices = 0;
    controller.addListener(() => notices += 1);
    controller.tick(0);
    expect(notices, 0);
    controller.sendWave();
    expect(notices, 1);
    controller.tick(40);
    expect(controller.state.outcome, MatchOutcome.lost);
    expect(notices, 2);
    controller.tick(5);
    expect(notices, 2);
  });

  test('restart opens a new match', () {
    final controller = MatchController();
    controller.place(0, 0);
    controller.restart();
    expect(controller.state.gold, 160);
    expect(controller.state.towers, isEmpty);
  });
}
