import 'package:flutter/material.dart';
import 'shooter_screen.dart';

/// Central em modo retrato: apenas Missão Glicogotas está disponível por enquanto.
class GlicogotasGamesHome extends StatelessWidget {
  const GlicogotasGamesHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFFFF4081),
      centerTitle: true,
      title: const Text('Jogos', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [IconButton(onPressed: () => showAboutDialog(context: context,
        applicationName: 'Glicogotas Games', children: [const Text('Minigames educativos do Glicogotas.')]),
        icon: const Icon(Icons.info_outline), tooltip: 'Sobre os jogos')],
    ),
    body: SafeArea(child: LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - 44 - 16) / 2;
      return Center(child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Escolha sua aventura!', style: TextStyle(fontSize: 22,
            fontWeight: FontWeight.w800, color: Color(0xFF37ABDC))),
          const SizedBox(height: 25),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: w, child: _GameTile(title: 'Missão Glicogotas',
              color: const Color(0xFFFFE3EE), foreground: const Color(0xFFB52A64),
              image: 'assets/images/lita_voando.png',
              action: () => Navigator.push(context, MaterialPageRoute<void>(
                builder: (_) => const LitaShooterScreen())))),
            const SizedBox(width: 16),
            SizedBox(width: w, child: const _GameTile(title: 'Próximo jogo',
              color: Color(0xFFE2F6FF), foreground: Color(0xFF265F95))),
          ]),
          const SizedBox(height: 24),
          const Text('Itens e poderes são fictícios e não substituem cuidados de saúde.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF42637B))),
        ]))));
    })),
  );
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.title, required this.color,
    required this.foreground, this.image, this.action});
  final String title;
  final Color color, foreground;
  final String? image;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Material(color: color,
    borderRadius: BorderRadius.circular(19), child: InkWell(
      borderRadius: BorderRadius.circular(19), onTap: action,
      child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
        AspectRatio(aspectRatio: 1, child: image == null
          ? Icon(Icons.extension_rounded, size: 58, color: foreground.withValues(alpha: 0.65))
          : Image.asset(image!, package: 'glicogotas_games', fit: BoxFit.contain)),
        const SizedBox(height: 8),
        Text(title, textAlign: TextAlign.center, style: TextStyle(
          color: foreground, fontSize: 15, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: action == null ? Colors.white70 : foreground,
            borderRadius: BorderRadius.circular(25)),
          child: Text(action == null ? 'Em breve' : 'Jogar', textAlign: TextAlign.center,
            style: TextStyle(color: action == null ? foreground : Colors.white,
              fontSize: 14, fontWeight: FontWeight.bold))),
      ])),
    ));
}
