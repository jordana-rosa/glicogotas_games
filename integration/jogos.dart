// Copie para glicogotas_app/lib/jogos.dart APENAS depois de testar.
// A pagina principal de Jogos continua em RETRATO;
// somente a Missao Glicogotas muda a orientacao para PAISAGEM.
import 'package:flutter/material.dart';
import 'package:glicogotas_games/glicogotas_games.dart';

class JogosPage extends StatelessWidget {
  const JogosPage({super.key});
  @override
  Widget build(BuildContext context) => const GlicogotasGamesHome();
}
