# Correção de compilação do Glicogotas Games

Foi corrigida a ambiguidade entre `dart:ui.Image` e `flutter/widgets.Image` em `lib/src/lita_game.dart`.

1. Descompacte e copie o conteúdo para `D:\\glicogotas_games_novo` (não copie a pasta externa inteira para dentro).
2. Na pasta do jogo execute `git add .`, `git commit -m "Corrige tipo de imagem no jogo"` e `git push origin main`.
3. No `D:\\glicogotas_app`, execute `flutter pub upgrade glicogotas_games` e `flutter run`.

Não altere arquivos dentro de `D:\\dart_pub_cache`.
Esta correção não foi compilada no ambiente de entrega porque o Flutter não está disponível.
