import 'package:flutter/foundation.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/match/simulator.dart';

class MatchController extends ChangeNotifier {
  MatchController._(this._simulator, this._state);

  factory MatchController({MatchSimulator? simulator, MatchState? state}) {
    final resolved = simulator ?? MatchSimulator();
    return MatchController._(resolved, state ?? resolved.initial());
  }

  final MatchSimulator _simulator;
  MatchState _state;

  MatchState get state => _state;

  void select(TowerKind kind) => _commit(_simulator.select(_state, kind));

  void place(int column, int row) =>
      _commit(_simulator.place(_state, column, row));

  void sendWave() => _commit(_simulator.sendWave(_state));

  void restart() => _commit(_simulator.initial());

  void tick(double dt) {
    if (dt <= 0 || _state.outcome != MatchOutcome.ongoing) {
      return;
    }
    var left = dt;
    const slice = 1 / 30;
    while (left > 0) {
      final step = left > slice ? slice : left;
      _state = _simulator.step(_state, step);
      left -= step;
      if (_state.outcome != MatchOutcome.ongoing) {
        break;
      }
    }
    notifyListeners();
  }

  void _commit(MatchState next) {
    if (identical(next, _state)) {
      return;
    }
    _state = next;
    notifyListeners();
  }
}
