import 'package:flutter/widgets.dart';
import 'package:tower_defence/match/profiles.dart';

abstract final class KeepwardKeys {
  static const board = Key('board');
  static const gold = Key('gold');
  static const lives = Key('lives');
  static const wave = Key('wave');
  static const send = Key('send-wave');
  static const restart = Key('restart');
  static const outcome = Key('outcome');

  static Key tower(TowerKind kind) => Key('tower-${kind.name}');
}
