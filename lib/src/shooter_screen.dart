import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lita_game.dart';

class LitaShooterScreen extends StatefulWidget {
  const LitaShooterScreen({super.key});
  @override
  State<LitaShooterScreen> createState() => _LitaShooterScreenState();
}

class _LitaShooterScreenState extends State<LitaShooterScreen> with WidgetsBindingObserver {
  late final LitaGame game;
  final ValueNotifier<int> ticks = ValueNotifier<int>(0);
  int record = 0;
  bool over = false;
  bool newRecord = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    game = LitaGame(changed: () {
      if (mounted) ticks.value++;
    }, finished: _onFinished);
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => record = prefs.getInt('glicogotas_lita_record') ?? 0);
  }

  Future<void> _onFinished(int score) async {
    if (!mounted || over) return;
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getInt('glicogotas_lita_record') ?? 0;
    if (score > old) await prefs.setInt('glicogotas_lita_record', score);
    if (mounted) setState(() {
      over = true;
      newRecord = score > old;
      record = score > old ? score : old;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) game.setPaused(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ticks.dispose();
    super.dispose();
  }

  void _replay() {
    setState(() { over = false; newRecord = false; });
    game.restart();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEDF9FE),
    body: SafeArea(child: Stack(children: [
      Positioned.fill(child: GameWidget(game: game)),
      Positioned(top: 8, left: 8, right: 8, child: ValueListenableBuilder<int>(
        valueListenable: ticks, builder: (_, __, ___) {
          final rules = game.rules;
          return Column(children: [
            Row(children: [
              Material(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(13), child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text('♥ ' * rules.lives + '♡ ' * (3-rules.lives), style: const TextStyle(fontSize: 21, color: Color(0xFFEF447B), fontWeight: FontWeight.bold)),
              )),
              const Spacer(),
              Material(color: Colors.white.withOpacity(.94), borderRadius: BorderRadius.circular(13), child: Padding(
                padding: const EdgeInsets.all(10), child: Text('Pontos ${rules.score}  •  Recorde $record', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              )),
              IconButton.filledTonal(tooltip: 'Pausar ou continuar', onPressed: () => setState(() => game.setPaused(!game.pausedByUser)), icon: Icon(game.pausedByUser ? Icons.play_arrow : Icons.pause)),
            ]),
            if (game.bossHp > 0) Padding(padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 55), child: Column(children: [
              const Text('REI DA HIPER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
              LinearProgressIndicator(value: game.bossHpFraction, minHeight: 9, backgroundColor: Colors.white, color: const Color(0xFF9253CB)),
            ])),
            if (rules.isPowerActive) const Text('★ CANETTO TURBINADO ★', style: TextStyle(color: Color(0xFFA85820), fontWeight: FontWeight.bold)),
            if (rules.isSlowed) const Text('LENTIDÃO: desvie do Bobo!', style: TextStyle(color: Color(0xFFBD1C4F), fontWeight: FontWeight.bold)),
          ]);
        },
      )),
      if (game.pausedByUser && !over) Center(child: _panel(children: [
        const Text('Jogo pausado', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => setState(() => game.setPaused(false)), child: const Text('Continuar')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar aos jogos')),
      ])),
      if (over) Center(child: _panel(children: [
        if (newRecord) Image.asset('assets/images/novo_recorde.png', package: 'glicogotas_games', height: 95, fit: BoxFit.contain),
        Text(newRecord ? '🌟 NOVO RECORDE!' : 'Fim de jogo!', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 25)),
        const SizedBox(height: 16),
        Text('Pontuação: ${game.rules.score}', style: const TextStyle(fontSize: 19)),
        Text('Recorde pessoal: $record'),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: _replay, icon: const Icon(Icons.replay), label: const Text('Jogar novamente')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar aos jogos')),
      ])),
      const Positioned(left: 12, right: 12, bottom: 8, child: IgnorePointer(child: Text(
        'Arraste a Lita para desviar • Disparos automáticos • Itens são fantasia', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Color(0xFF3B607C)),
      ))),
    ])),
  );

  Widget _panel({required List<Widget> children}) => Container(
    width: 320, padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(blurRadius: 24, color: Color(0x33000000))]),
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}
