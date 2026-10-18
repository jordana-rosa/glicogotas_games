import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_rules.dart';

enum ThingType { foe, bobo, apple, heart, bullet, enemyBullet, boss }

class Thing {
  Thing(this.type, this.x, this.y, this.radius, this.vx, {this.vy = 0, this.hp = 1, this.age = 0});
  ThingType type;
  double x, y, radius, vx, vy, age;
  int hp;
}

/// Mundo horizontal em pixels lógicos. Atualização independente da taxa de quadros.
class LitaGame extends FlameGame with DragCallbacks, TapCallbacks {
  LitaGame({required this.changed, required this.finished});
  final VoidCallback changed;
  final Future<void> Function(int) finished;
  final GameRules rules = GameRules();
  final math.Random random = math.Random();
  final List<Thing> things = [];
  final Images packageImages = Images(prefix: 'packages/glicogotas_games/assets/images/');
  SpriteComponent? lita;
  SpriteComponent? confused;
  final Map<ThingType, ui.Image> entityImages = {};
  double playerX = 35, playerY = 160;
  double spawnClock = 0, fireClock = 0, appleClock = 0, healClock = 0, bossClock = 0;
  double sceneOffset = 0;
  double bossHpFraction = 0;
  double bossIntroRemaining = 0;
  static const double bossIntroDuration = 3.2;
  int bossHp = 0, bossMaxHp = 0;
  bool pausedByUser = false;
  bool soundEnabled = true; // Preparado para futura ligação ao sistema de áudio.
  bool notifiedEnd = false;
  int nextBossAt = 500; // Primeiro chefe aparece cedo; depois a cada 3500 pontos.
  int lastDisplayScore = -1, lastDisplayLives = -1;

  double get playerWidth => math.min(155, size.x * 0.28);
  double get playerHeight => playerWidth * 0.57;
  double get minY => 58;
  double get maxY => math.max(minY, size.y - playerHeight - 15);
  double get hitX => playerX + playerWidth * 0.42;
  double get hitY => playerY + playerHeight * 0.51;

  @override
  Color backgroundColor() => const Color(0xFFF1FAFF);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    entityImages[ThingType.bobo] = await packageImages.load('bobo.png');
    entityImages[ThingType.boss] = await packageImages.load('rei_hiper.png');
    entityImages[ThingType.heart] = await packageImages.load('vida_extra.png');
    final flight = Sprite(await packageImages.load('lita_voando.png'));
    final dizzy = Sprite(await packageImages.load('lita_bobo.png'));
    lita = SpriteComponent(sprite: flight, position: Vector2(playerX, playerY), size: Vector2(playerWidth, playerHeight));
    confused = SpriteComponent(sprite: dizzy, position: Vector2(playerX + 25, playerY - 10), size: Vector2(playerWidth * 0.55, playerHeight * 1.32));
    add(lita!);
    add(confused!);
    confused!.opacity = 0; // Exibido durante lentidão; base voadora volta depois.
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    playerY = playerY.clamp(minY, maxY).toDouble();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (pausedByUser || rules.isOver) return;
    final factor = rules.isSlowed ? 0.4 : 1.0;
    playerX = (playerX + event.localDelta.x * factor).clamp(0.0, math.max(0, size.x * 0.48)).toDouble();
    playerY = (playerY + event.localDelta.y * factor).clamp(minY, maxY).toDouble();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (pausedByUser || rules.isOver) return;
    playerY = (event.localPosition.y - playerHeight / 2).clamp(minY, maxY).toDouble();
  }

  void setPaused(bool value) {
    pausedByUser = value;
    changed();
  }

  void restart() {
    rules.reset();
    things.clear();
    playerX = 35;
    playerY = size.y / 2;
    spawnClock = fireClock = appleClock = healClock = bossClock = sceneOffset = 0;
    bossHp = bossMaxHp = 0;
    bossHpFraction = 0;
    bossIntroRemaining = 0;
    nextBossAt = 500;
    pausedByUser = false;
    notifiedEnd = false;
    changed();
  }

  void _spawn(ThingType type, {double? y}) {
    final yy = y ?? (65 + random.nextDouble() * math.max(1, size.y - 145));
    switch (type) {
      case ThingType.foe:
        things.add(Thing(type, size.x + 32, yy, 19, -rules.enemySpeed, hp: 2));
      case ThingType.bobo:
        things.add(Thing(type, size.x + 40, yy, 25, -rules.enemySpeed * 0.67, hp: 3));
      case ThingType.apple:
        things.add(Thing(type, size.x + 30, yy, 17, -110));
      case ThingType.heart:
        things.add(Thing(type, size.x + 30, yy, 17, -110));
      case ThingType.boss:
        bossMaxHp = 28 + rules.bossesDefeated * 12;
        bossHp = bossMaxHp;
        bossHpFraction = 1;
        bossIntroRemaining = bossIntroDuration;
        // O chefe entra pela direita e permanece na arena até ser derrotado.
        things.add(Thing(type, size.x + 90, size.y / 2, 52, -55, hp: bossHp));
      case ThingType.bullet:
      case ThingType.enemyBullet:
        break;
    }
  }

  void _shoot() {
    final power = rules.isPowerActive ? rules.power : PowerMode.normal;
    final directions = switch (power) {
      PowerMode.doubleShot => [-0.10, 0.10],
      PowerMode.tripleShot => [-0.24, 0.0, 0.24],
      PowerMode.burst => [-0.36, -0.18, 0.0, 0.18, 0.36],
      _ => [0.0],
    };
    for (final n in directions) {
      things.add(Thing(ThingType.bullet, playerX + playerWidth * 0.95, hitY - 11, 7, 420, vy: n * 290));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (pausedByUser || rules.isOver || size.x == 0 || size.y == 0) return;
    dt = dt.clamp(0.0, 0.05).toDouble();
    if (bossIntroRemaining > 0) {
      bossIntroRemaining = math.max(0, bossIntroRemaining - dt);
    }
    rules.advance(dt);
    sceneOffset += dt * (35 + rules.difficulty * 12);
    fireClock += dt;
    spawnClock += dt;
    appleClock += dt;
    healClock += dt;
    bossClock += dt;
    final activePower = rules.isPowerActive ? rules.power : PowerMode.normal;
    final cooldown = (activePower == PowerMode.rapid || activePower == PowerMode.burst) ? 0.14 : 0.35;
    if (fireClock >= cooldown) { fireClock = 0; _shoot(); }
    if (spawnClock >= rules.enemySpawnInterval) {
      spawnClock = 0;
      if (things.where((e) => e.type == ThingType.foe || e.type == ThingType.bobo).length < 12) {
        _spawn(random.nextDouble() < .19 ? ThingType.bobo : ThingType.foe);
      }
    }
    if (appleClock > 12) { appleClock = 0; _spawn(ThingType.apple); }
    if (healClock > 17) {
      healClock = 0;
      if (rules.healthItemEligible && random.nextDouble() < .27) _spawn(ThingType.heart);
    }
    if (rules.score >= nextBossAt && !things.any((t) => t.type == ThingType.boss)) {
      _spawn(ThingType.boss);
      nextBossAt += 3500;
      bossClock = 0;
    }
    final boss = things.where((t) => t.type == ThingType.boss).toList();
    if (boss.isNotEmpty && bossIntroRemaining <= 0 && bossClock >= 1.5) {
      bossClock = 0;
      things.add(Thing(ThingType.enemyBullet, boss.first.x - 40, boss.first.y, 10, -220, vy: (hitY - boss.first.y) * .2));
    }
    final remove = <Thing>{};
    for (final t in things) {
      t.age += dt;
      t.x += t.vx * dt;
      t.y += t.vy * dt;
      if (t.type == ThingType.boss) {
        final bossTargetX = size.x * 0.76;
        if (t.x <= bossTargetX) {
          t.x = bossTargetX;
          t.vx = 0;
        }
      }
      if (t.type == ThingType.bobo || t.type == ThingType.boss) t.y += math.sin(t.age * 3) * 22 * dt;
      if (t.x < -80 || t.x > size.x + 130 || t.y < -40 || t.y > size.y + 40) remove.add(t);
      if (t.type == ThingType.bullet) continue;
      if (_touch(t.x, t.y, hitX, hitY, t.radius + playerHeight * .22)) {
        if (t.type == ThingType.apple) {
          final powers = [PowerMode.rapid, PowerMode.doubleShot, PowerMode.tripleShot, PowerMode.burst];
          rules.activate(powers[random.nextInt(powers.length)]);
          rules.addPoints(100);
          remove.add(t);
        } else if (t.type == ThingType.heart) {
          rules.heal(); remove.add(t);
        } else if (t.type == ThingType.bobo) {
          rules.slow();
          rules.damage(); remove.add(t);
        } else {
          rules.damage();
          if (t.type != ThingType.boss) remove.add(t);
        }
      }
    }
    for (final shot in things.where((t) => t.type == ThingType.bullet)) {
      for (final target in things.where((t) => t.type == ThingType.foe || t.type == ThingType.bobo || t.type == ThingType.boss)) {
        if (remove.contains(shot) || remove.contains(target)) continue;
        if (_touch(shot.x, shot.y, target.x, target.y, shot.radius + target.radius)) {
          remove.add(shot); target.hp--;
          if (target.type == ThingType.boss) { bossHp = target.hp; bossHpFraction = (bossHp / bossMaxHp).clamp(0, 1).toDouble(); }
          if (target.hp <= 0) {
            remove.add(target);
            rules.addPoints(target.type == ThingType.boss ? 1000 : target.type == ThingType.bobo ? 150 : 100);
            if (target.type == ThingType.boss) { rules.bossesDefeated++; bossHp = 0; }
          }
        }
      }
    }
    things.removeWhere(remove.contains);
    final sprite = lita;
    if (sprite != null) {
      sprite.position.setValues(playerX, playerY + math.sin(rules.time * 7) * 2);
      sprite.size.setValues(playerWidth, playerHeight);
      sprite.opacity = rules.isSlowed ? 0.35 : (rules.isInvulnerable && (rules.time * 7).floor().isOdd ? .55 : 1);
    }
    final dizzy = confused;
    if (dizzy != null) {
      dizzy.position.setValues(playerX + 18, playerY - 12);
      dizzy.size.setValues(playerWidth * .56, playerHeight * 1.4);
      dizzy.opacity = rules.isSlowed ? .85 : 0;
    }
    if (lastDisplayScore != rules.score || lastDisplayLives != rules.lives || rules.isPowerActive || rules.isSlowed) {
      lastDisplayScore = rules.score;
      lastDisplayLives = rules.lives;
      changed();
    }
    if (rules.isOver && !notifiedEnd) { notifiedEnd = true; finished(rules.score); }
  }

  bool _touch(double x, double y, double a, double b, double radius) => (x-a)*(x-a) + (y-b)*(y-b) < radius*radius;

  @override
  void render(Canvas canvas) {
    final bg = Paint()..color = const Color(0xFFC7EFF8).withValues(alpha: 0.6);
    for (var i = 0; i < 14; i++) {
      final x = ((i * 107.0 - sceneOffset * (i.isEven ? 1 : .65)) % (size.x + 180) + size.x + 180) % (size.x + 180);
      final y = 65.0 + (i * 83.0) % math.max(70, size.y - 100);
      canvas.drawCircle(Offset(x, y), i.isEven ? 18 : 10, bg);
    }
    for (final t in things) {
      Color c;
      switch(t.type) {
        case ThingType.foe: c = const Color(0xFF8752C7);
        case ThingType.bobo: c = const Color(0xFFFF8A43);
        case ThingType.apple: c = const Color(0xFFE94A59);
        case ThingType.heart: c = const Color(0xFF58BDAC);
        case ThingType.bullet: c = const Color(0xFFFFCC42);
        case ThingType.enemyBullet: c = const Color(0xFFEF659D);
        case ThingType.boss: c = const Color(0xFF462B84);
      }
      final art = entityImages[t.type];
      if (art != null) {
        // Preserva a proporção das artes para não esticar os personagens.
        final aspectRatio = art.width / art.height;
        double height;
        double maxWidth;
        switch (t.type) {
          case ThingType.boss:
            height = size.y * 0.76;
            maxWidth = size.x * 0.43;
          case ThingType.bobo:
            height = t.radius * 3.4;
            maxWidth = t.radius * 4.4;
          case ThingType.heart:
            height = t.radius * 2.4;
            maxWidth = t.radius * 3.0;
          default:
            height = t.radius * 2.8;
            maxWidth = t.radius * 3.4;
        }
        final width = math.min(height * aspectRatio, maxWidth);
        height = width / aspectRatio;
        canvas.drawImageRect(
          art,
          Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
          Rect.fromCenter(
            center: Offset(t.x, t.y),
            width: width,
            height: height,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
        continue;
      }
      final p = Paint()..color = c;
      canvas.drawCircle(Offset(t.x, t.y), t.radius, p);
      canvas.drawCircle(
  Offset(t.x - t.radius * .2, t.y - t.radius * .2),
  t.radius * .48,
  Paint()..color = Colors.white.withValues(alpha: 0.45),
);
      if (t.type == ThingType.apple) canvas.drawLine(Offset(t.x, t.y - 14), Offset(t.x+7, t.y-24), Paint()..color = Colors.green..strokeWidth = 4);
      if (t.type == ThingType.heart) _drawLabel(canvas, '+', t.x - 7, t.y - 12, 28);
      if (t.type == ThingType.bobo) _drawLabel(canvas, 'B', t.x-10, t.y-17, 27);
      if (t.type == ThingType.boss) _drawLabel(canvas, 'R', t.x-19, t.y-30, 54);
    }
    super.render(canvas);
    _renderBossEntrance(canvas);
  }

  /// Alerta visual sobre o jogo nos primeiros segundos de cada chefe.
  void _renderBossEntrance(Canvas canvas) {
    if (bossIntroRemaining <= 0 || bossHp <= 0) return;
    final elapsed = bossIntroDuration - bossIntroRemaining;
    final alpha = math.min(1.0, math.min(elapsed / .32, bossIntroRemaining / .55));
    final pulse = .5 + .5 * math.sin(elapsed * 10);
    final w = size.x;
    final h = size.y;

    // Flash discreto e faixas dramáticas; o jogo permanece visível.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF3B146A).withValues(alpha: .11 * alpha * pulse),
    );
    final banner = Rect.fromCenter(
      center: Offset(w * .5, h * .35),
      width: math.min(w * .81, 650),
      height: math.min(h * .36, 115),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(banner, const Radius.circular(23)),
      Paint()..color = const Color(0xFF38115E).withValues(alpha: .91 * alpha),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(banner.deflate(3), const Radius.circular(20)),
      Paint()
        ..color = const Color(0xFFFFCE43).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final titleFont = math.min(32.0, math.max(15.0, w * .05));
    final title = TextPainter(
      text: TextSpan(
        text: 'O REI DA HIPER CHEGOU!',
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: titleFont,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Color(0xFFAA54F5), blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout(maxWidth: banner.width - 20);
    title.paint(canvas, Offset(w * .5 - title.width / 2, banner.center.dy - title.height * .75));

    final subtitle = TextPainter(
      text: TextSpan(
        text: 'PREPARE O CANETTO!',
        style: TextStyle(
          color: const Color(0xFFFFDC61).withValues(alpha: alpha),
          fontSize: math.min(17.0, math.max(11.0, w * .026)),
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: banner.width - 20);
    subtitle.paint(canvas, Offset(w * .5 - subtitle.width / 2, banner.center.dy + title.height * .15));
  }

  void _drawLabel(Canvas canvas, String label, double x, double y, double fontSize) {
    final tp = TextPainter(text: TextSpan(text: label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x, y));
  }
}
