import 'dart:math' as math;

enum PowerMode { normal, rapid, doubleShot, tripleShot, burst }

/// Regras puras para testes sem motor gráfico.
class GameRules {
  static const maxLives = 3;
  int lives = maxLives;
  int score = 0;
  double time = 0;
  double invulnerableUntil = 0;
  double slowUntil = 0;
  double powerUntil = 0;
  PowerMode power = PowerMode.normal;
  int bossesDefeated = 0;

  bool get isInvulnerable => time < invulnerableUntil;
  bool get isSlowed => time < slowUntil;
  bool get isPowerActive => time < powerUntil && power != PowerMode.normal;
  bool get isOver => lives <= 0;
  double get difficulty => math.min(4.5, 1 + time / 80 + score / 12000);
  double get enemySpawnInterval => math.max(0.48, 1.75 / difficulty);
  double get enemySpeed => math.min(340, 115 + difficulty * 38);

  void advance(double dt) {
    time += math.max(0, dt);
    if (time >= powerUntil) power = PowerMode.normal;
  }

  bool damage() {
    if (isOver || isInvulnerable) return false;
    lives--;
    invulnerableUntil = time + 1.6;
    return true;
  }

  void slow({double duration = 3.0}) {
    slowUntil = math.max(slowUntil, time + duration);
  }

  void activate(PowerMode mode, {double duration = 9}) {
    power = mode;
    powerUntil = time + duration;
  }

  bool heal() {
    if (score < 5000 || lives >= maxLives || isOver) return false;
    lives++;
    return true;
  }

  void addPoints(int amount) {
    score += math.max(0, amount);
  }

  bool get healthItemEligible => score >= 5000 && lives < maxLives;
  void reset() {
    lives = maxLives;
    score = 0;
    time = 0;
    invulnerableUntil = 0;
    slowUntil = 0;
    powerUntil = 0;
    power = PowerMode.normal;
    bossesDefeated = 0;
  }
}
