enum TowerKind { archer, cannon, frost }

enum EnemyKind { grunt, runner, brute }

class TowerProfile {
  const TowerProfile({
    required this.cost,
    required this.range,
    required this.damage,
    required this.interval,
    required this.shotSpeed,
    required this.splash,
    required this.slowFactor,
    required this.slowDuration,
    required this.label,
    required this.trait,
  });

  final int cost;
  final double range;
  final double damage;
  final double interval;
  final double shotSpeed;
  final double splash;
  final double slowFactor;
  final double slowDuration;
  final String label;
  final String trait;
}

class EnemyProfile {
  const EnemyProfile({
    required this.health,
    required this.speed,
    required this.bounty,
    required this.lives,
  });

  final int health;
  final double speed;
  final int bounty;
  final int lives;
}

const towerProfiles = <TowerKind, TowerProfile>{
  TowerKind.archer: TowerProfile(
    cost: 50,
    range: 2.6,
    damage: 14,
    interval: 0.55,
    shotSpeed: 8,
    splash: 0,
    slowFactor: 1,
    slowDuration: 0,
    label: 'Archer',
    trait: 'Fast shots',
  ),
  TowerKind.cannon: TowerProfile(
    cost: 100,
    range: 2.3,
    damage: 34,
    interval: 1.25,
    shotSpeed: 5,
    splash: 0.85,
    slowFactor: 1,
    slowDuration: 0,
    label: 'Cannon',
    trait: 'Splash',
  ),
  TowerKind.frost: TowerProfile(
    cost: 75,
    range: 2.2,
    damage: 7,
    interval: 0.8,
    shotSpeed: 7,
    splash: 0,
    slowFactor: 0.5,
    slowDuration: 1.6,
    label: 'Frost',
    trait: 'Slows',
  ),
};

const enemyProfiles = <EnemyKind, EnemyProfile>{
  EnemyKind.grunt: EnemyProfile(health: 36, speed: 1.15, bounty: 8, lives: 1),
  EnemyKind.runner: EnemyProfile(health: 22, speed: 1.9, bounty: 10, lives: 1),
  EnemyKind.brute: EnemyProfile(health: 110, speed: 0.62, bounty: 18, lives: 2),
};

List<EnemyKind> campaignRoster(int wave) {
  return [
    for (var i = 0; i < 4 + wave; i++) EnemyKind.grunt,
    if (wave >= 2)
      for (var i = 0; i < wave; i++) EnemyKind.runner,
    if (wave >= 4)
      for (var i = 0; i < wave - 2; i++) EnemyKind.brute,
  ];
}
