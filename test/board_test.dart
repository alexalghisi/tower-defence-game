import 'package:flutter_test/flutter_test.dart';
import 'package:tower_defence/match/board.dart';

void main() {
  final board = Board.campaign();

  test('the campaign road blocks the bend and leaves the grass open', () {
    expect(board.canBuild(0, 1), isFalse);
    expect(board.path.contains(const Cell(9, 2)), isTrue);
    expect(board.path.contains(const Cell(11, 5)), isTrue);
    expect(board.canBuild(0, 0), isTrue);
    expect(board.canBuild(4, 2), isTrue);
    expect(board.contains(-1, 0), isFalse);
  });

  test('the route runs from the west entrance to the gate', () {
    expect(board.route.length, closeTo(29, 0.001));
    expect(board.route.at(0).x, closeTo(0.5, 0.001));
    expect(board.route.at(0).y, closeTo(1.5, 0.001));
    expect(board.route.at(board.route.length).x, closeTo(11.5, 0.001));
    expect(board.route.at(board.route.length).y, closeTo(5.5, 0.001));
    expect(board.route.at(9).x, closeTo(9.5, 0.001));
    expect(board.route.at(9).y, closeTo(1.5, 0.001));
  });
}
