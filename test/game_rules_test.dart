import 'package:flutter_test/flutter_test.dart';
import 'package:glicogotas_games/glicogotas_games.dart';

void main() {
  test('três vidas iniciais e reinício', () {
    final r = GameRules();
    expect(r.lives, 3);
    r.damage(); r.advance(2); r.damage();
    r.reset();
    expect(r.lives, 3); expect(r.score, 0);
  });
  test('dano tem invulnerabilidade', () {
    final r = GameRules();
    expect(r.damage(), isTrue);
    expect(r.damage(), isFalse);
    expect(r.lives, 2);
    r.advance(1.7);
    expect(r.damage(), isTrue);
  });
  test('maçã ativa e expira o poder', () {
    final r = GameRules();
    r.activate(PowerMode.tripleShot, duration: 2);
    expect(r.isPowerActive, isTrue);
    r.advance(2.1);
    expect(r.power, PowerMode.normal);
  });
  test('recuperação só após 5000 pontos, no máximo três vidas', () {
    final r = GameRules();
    r.damage(); r.advance(2);
    expect(r.heal(), isFalse);
    r.addPoints(5000);
    expect(r.heal(), isTrue);
    expect(r.heal(), isFalse);
    expect(r.lives, 3);
  });
  test('Bobo deixa lento temporariamente', () {
    final r = GameRules();
    r.slow(duration: 3);
    expect(r.isSlowed, isTrue);
    r.advance(3.1);
    expect(r.isSlowed, isFalse);
  });
  test('pontuação e dificuldade continuam após 5000', () {
    final r = GameRules();
    final oldDifficulty = r.difficulty;
    r.addPoints(5600); r.advance(120);
    expect(r.difficulty, greaterThan(oldDifficulty));
    r.addPoints(7000);
    expect(r.score, 12600);
  });
}
