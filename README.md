# Glicogotas Games — Protótipo de integração

Pacote independente Flutter + Flame para o aplicativo **Kahcodes/glicogotas_app** (Dart >=3.5).

## O que está incluído
- Central **Jogos** em retrato: card **Missão Glicogotas** e segundo card **Em breve** (não existe segundo jogo).
- Missão: rolagem lateral, arrasto por toque, disparos automáticos, três vidas, invulnerabilidade, inimigos, Bobo causando lentidão, Rei da Hiper com vida própria, maçãs com poderes, recuperação rara de vida a partir de 5.000 pontos, pausa, pontuação e recorde local.
- A tela do shooter solicita **paisagem** ao abrir e volta a **retrato** ao fechar. A orientação é uma preferência do Flutter/Android/iOS, não uma consequência de usar outro repositório. Teste em dispositivo real.
- Imagens integradas: Lita com Canetto, Lita afetada pelo Bobo, Bobo, Rei da Hiper, frasco do item de recuperação e comemoração de novo recorde.

## Executar demonstração
Abra a pasta `example` no VS Code ou terminal:
```bash
cd example
flutter pub get
flutter run
```

## Integrar ao app existente (somente depois dos testes)
No `glicogotas_app/pubspec.yaml`, em `dependencies`:
```yaml
  glicogotas_games:
    path: ../glicogotas_games
```
Em seguida rode `flutter pub get` na pasta do app principal.
Substitua `glicogotas_app/lib/jogos.dart` pelo arquivo `integration/jogos.dart` deste pacote. O botão da home já abre `JogosPage`; não é necessário mudar `home.dart`.

Para migrar a um repositório remoto separado, publique `glicogotas_games` no seu GitHub e troque a dependência `path` por `git: url: https://github.com/SEU_USUARIO/glicogotas_games.git`.

## Observações importantes
- A arte da Lita voando ainda é uma imagem única movimentada por código, e não um spritesheet articulado. A pose alternativa com Canetto está preservada em `assets/images/lita_canetto_original.png` para futura seleção e animação.
- No minigame, o item inspirado em insulina recupera vida **apenas como mecânica fictícia**. Não sugere eficácia médica ou dosagem extra.
- O original `glicogotas_app` **não foi modificado**.
- O projeto foi preparado em ambiente sem Flutter/Dart instalado: **flutter pub get**, **flutter analyze**, **flutter test** e build APK **não foram executados**. Compilação e ajustes de compatibilidade ficam pendentes de teste local.
- A orientação no iPad/iOS depende das configurações de rotação admitidas pelo host; restrições do sistema operacional podem limitar o bloqueio.
