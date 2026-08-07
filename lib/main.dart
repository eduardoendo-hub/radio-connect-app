import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'api.dart';
import 'estado_no_ar.dart';
import 'estado_respostas.dart';
import 'tema.dart';
import 'telas/entrada.dart';
import 'telas/no_ar.dart';
import 'telas/momentos.dart';
import 'telas/chat.dart';
import 'telas/sua_radio.dart';
import 'telas/player.dart';
import 'widgets/mini_player.dart';
import 'widgets/aviso_momento.dart';

/// O aplicativo do ouvinte.
///
/// **White-label total:** quem usa vê a Band FM, nunca o Radio Connect. A plataforma é
/// invisível — é isso que faz a pessoa dizer "essa é a minha rádio" em vez de "esse app
/// de rádio".
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.carregarSessao();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _autenticado = Api.autenticado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Band FM',
      debugShowCheckedModeBanner: false,
      theme: bandFmTheme(),
      home: _autenticado
          ? const Casca()
          : TelaEntrada(aoEntrar: () => setState(() => _autenticado = true)),
    );
  }
}

/// A casca do app: quatro abas com o mini-player logo acima.
///
/// `No Ar | Momentos | Chat | Sua Rádio`
///
/// **Promoções não é aba** — aparece dentro de No Ar, Momentos e Sua Rádio.
/// **O player não é aba** — vive como mini-player e abre em tela cheia ao toque.
class Casca extends StatefulWidget {
  const Casca({super.key});

  @override
  State<Casca> createState() => _CascaState();
}

class _CascaState extends State<Casca> {
  final _noAr = EstadoNoAr();
  final _player = EstadoPlayer();
  int _aba = 0;
  String? _nome;

  @override
  void initState() {
    super.initState();
    _noAr.iniciar();
    _player.definirFonte(const String.fromEnvironment('STREAM_URL'));
    // Falhar aqui não pode travar nada: sem o nome, "Sua Rádio" mostra "Ouvinte".
    unawaited(Api.obter('/auth/eu').then((r) {
      final o = r['ouvinte'] as Map<String, dynamic>?;
      if (mounted) setState(() => _nome = o?['nome']?.toString());
    }).catchError((_) {}));
  }

  @override
  void dispose() {
    _noAr.dispose();
    _player.dispose();
    super.dispose();
  }

  void _abrirPlayer() {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AnimatedBuilder(
        animation: _noAr,
        builder: (_, __) => TelaPlayer(
          estado: _player,
          programa: _noAr.programa?['nome']?.toString() ?? 'Band FM',
          locutor: _noAr.locutor?['nome']?.toString(),
          musica: _noAr.musica?['titulo']?.toString(),
          artista: _noAr.musica?['artista']?.toString(),
          aoAbrirChat: () => setState(() => _aba = 2),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      TelaNoAr(estado: _noAr),
      TelaMomentos(estado: _noAr),
      const TelaChat(),
      TelaSuaRadio(nome: _nome),
    ];

    return Scaffold(
      backgroundColor: BandFMColors.bg,
      body: SafeArea(bottom: false, child: IndexedStack(index: _aba, children: telas)),
      bottomNavigationBar: AnimatedBuilder(
        // O ponto de Momentos some quando a pessoa responde em qualquer lugar.
        animation: Listenable.merge([_noAr, RegistroDeRespostas.instancia]),
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // O aviso fica acima do mini-player e some sozinho. Não aparece em No Ar
            // nem em Momentos: nas duas o cartão do Momento já está na tela, e
            // anunciar o que está bem na frente da pessoa é ruído — pior, com o cartão
            // e a faixa juntos a mesma pergunta aparece duas vezes, com dois conjuntos
            // de botões. Sobram Chat e Sua Rádio, que é exatamente onde o Momento
            // passaria despercebido.
            if (_aba >= 2)
              AvisoMomento(estado: _noAr, aoAbrir: () => setState(() => _aba = 1)),
            // O mini-player fica ACIMA da tab bar e acompanha todas as abas.
            MiniPlayer(
              estado: _player,
              titulo: _noAr.musica?['titulo']?.toString() ?? 'Band FM 96,1 São Paulo',
              apoio: _noAr.musica?['artista']?.toString() ??
                  (_noAr.programa?['nome']?.toString() ?? 'A programação continua'),
              aoExpandir: _abrirPlayer,
            ),
            _tabBar(),
          ],
        ),
      ),
    );
  }

  Widget _tabBar() {
    const itens = [
      (Symbols.sensors, 'No Ar'),
      (Symbols.favorite, 'Momentos'),
      (Symbols.chat, 'Chat'),
      (Symbols.person, 'Sua Rádio'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: BandFMColors.bg,
        border: Border(top: BorderSide(color: BandFMColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: itens.indexed.map((e) {
              final (i, item) = e;
              final ativo = _aba == i;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _aba = i),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // FILL 0 quando inativo, FILL 1 quando ativo — regra do design system.
                    Stack(clipBehavior: Clip.none, children: [
                      Icon(item.$1,
                          fill: ativo ? 1 : 0,
                          size: 23,
                          color: ativo ? BandFMColors.orange : BandFMColors.textTertiary),
                      // O ponto em Momentos é a última linha de defesa: quem está no No
                      // Ar — onde a faixa não aparece — continua sabendo que há algo
                      // acontecendo, e quem já respondeu para de ser chamado.
                      if (i == 1 &&
                          _noAr.momento != null &&
                          !RegistroDeRespostas.instancia
                              .respondeu(_noAr.momento?['id']?.toString()))
                        Positioned(
                          right: -3, top: -2,
                          child: Container(
                            width: 9, height: 9,
                            decoration: BoxDecoration(
                              color: BandFMColors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: BandFMColors.bg, width: 1.5),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 3),
                    Text(item.$2,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                          color: ativo ? BandFMColors.orange : BandFMColors.textTertiary,
                        )),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
