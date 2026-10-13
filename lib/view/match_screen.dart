import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tower_defence/match/board.dart';
import 'package:tower_defence/match/match_controller.dart';
import 'package:tower_defence/match/match_state.dart';
import 'package:tower_defence/match/profiles.dart';
import 'package:tower_defence/view/board_metrics.dart';
import 'package:tower_defence/view/board_painter.dart';
import 'package:tower_defence/view/keepward_keys.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, this.controller, this.animate = true});

  final MatchController? controller;
  final bool animate;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final MatchController _controller;
  late final bool _ownsController;
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _skipFrame = false;
  Cell? _hover;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MatchController();
    WidgetsBinding.instance.addObserver(this);
    if (widget.animate) {
      _ticker = createTicker(_onTick)..start();
    }
  }

  void _onTick(Duration elapsed) {
    if (_skipFrame) {
      _skipFrame = false;
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1000000;
    _last = elapsed;
    if (dt > 0) {
      _controller.tick(dt);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ticker = _ticker;
    if (ticker == null) {
      return;
    }
    if (state == AppLifecycleState.paused) {
      ticker.stop();
    } else if (state == AppLifecycleState.resumed) {
      _skipFrame = true;
      ticker.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final busy = state.status == WaveStatus.active;
        return SizedBox.expand(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusBar(state: state),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _Board(
                        controller: _controller,
                        hover: _hover,
                        onHover: _setHover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TowerDock(
                      selected: state.selected,
                      onSelect: _controller.select,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: KeepwardKeys.send,
                        onPressed: busy ? null : _controller.sendWave,
                        child: Text(
                          busy
                              ? 'Wave in progress'
                              : 'Next wave ${state.armTimer.ceil()}s',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.outcome != MatchOutcome.ongoing)
                _Outcome(state: state, onRestart: _controller.restart),
            ],
          ),
        );
      },
    );
  }

  void _setHover(Cell? cell) {
    if (_hover == cell) {
      return;
    }
    setState(() => _hover = cell);
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final MatchState state;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3C4632)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Keepward', style: style.titleLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Gold',
                    value: '${state.gold}',
                    valueKey: KeepwardKeys.gold,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Lives',
                    value: '${state.lives}',
                    valueKey: KeepwardKeys.lives,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Wave',
                    value: '${state.wave}/${state.waveCount}',
                    valueKey: KeepwardKeys.wave,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: style.labelMedium),
          const SizedBox(width: 6),
          Text(value, key: valueKey, style: style.bodyMedium),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.controller,
    required this.hover,
    required this.onHover,
  });

  final MatchController controller;
  final Cell? hover;
  final ValueChanged<Cell?> onHover;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7A441), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: const Color(0xFF10160E),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final state = controller.state;
                final metrics = BoardMetrics.fit(
                  Size(constraints.maxWidth, constraints.maxHeight),
                  state.board.columns,
                  state.board.rows,
                );
                return Semantics(
                  label: 'Battle board',
                  child: MouseRegion(
                    onHover: (event) =>
                        onHover(metrics.cellAt(event.localPosition)),
                    onExit: (_) => onHover(null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final cell = metrics.cellAt(details.localPosition);
                        if (cell == null) {
                          return;
                        }
                        controller.place(cell.column, cell.row);
                      },
                      child: CustomPaint(
                        key: KeepwardKeys.board,
                        painter: BoardPainter(
                          state: state,
                          metrics: metrics,
                          hover: hover,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TowerDock extends StatelessWidget {
  const _TowerDock({required this.selected, required this.onSelect});

  final TowerKind selected;
  final ValueChanged<TowerKind> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = (constraints.maxWidth - 16) / TowerKind.values.length;
        return Row(
          children: [
            for (final kind in TowerKind.values) ...[
              SizedBox(
                width: slot,
                child: _TowerButton(
                  kind: kind,
                  selected: kind == selected,
                  onPressed: () => onSelect(kind),
                ),
              ),
              if (kind != TowerKind.frost) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

class _TowerButton extends StatelessWidget {
  const _TowerButton({
    required this.kind,
    required this.selected,
    required this.onPressed,
  });

  final TowerKind kind;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final profile = towerProfiles[kind]!;
    final style = Theme.of(context).textTheme;
    return Material(
      color: selected ? const Color(0xFF3A3424) : const Color(0xFF24281C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? const Color(0xFFD7A441) : const Color(0xFF3C4632),
          width: 2,
        ),
      ),
      child: InkWell(
        key: KeepwardKeys.tower(kind),
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: switch (kind) {
                      TowerKind.archer => const Color(0xFF1F6A62),
                      TowerKind.cannon => const Color(0xFFC6A15A),
                      TowerKind.frost => const Color(0xFF9EE0EA),
                    },
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(profile.label, style: style.bodyMedium),
                Text(
                  '${profile.cost}  ${profile.trait}',
                  style: style.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.state, required this.onRestart});

  final MatchState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final won = state.outcome == MatchOutcome.won;
    final style = Theme.of(context).textTheme;
    return ColoredBox(
      color: const Color(0xCC12180F),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF24301C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD7A441)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    won ? 'Victory' : 'Defeat',
                    key: KeepwardKeys.outcome,
                    style: style.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won ? 'The gate held.' : 'The gate fell.',
                    style: style.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: KeepwardKeys.restart,
                    onPressed: onRestart,
                    child: const Text('Play again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
