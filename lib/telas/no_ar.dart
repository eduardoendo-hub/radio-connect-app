import 'package:flutter/material.dart';
import '../estado_no_ar.dart';
import '../tema.dart';
import '../widgets/pulso.dart';
import '../widgets/cartao_momento.dart';
import '../widgets/banner_anuncio.dart';
import '../widgets/mini_player.dart';

/// O No Ar.
///
/// **A Home deixa de existir.** O usuário não entra num menu — entra no que está
/// acontecendo naquele instante. É o conceito de presente.
///
/// A hierarquia é fixa e não se negocia:
///   1. Presença — a rádio está ao vivo, qual programa, quem apresenta
///   2. Contexto — o que está acontecendo
///   3. Participação — o que ele pode fazer agora
///   4. Continuidade — o que vem depois
///
/// E o app nunca pode parecer parado: mesmo sem Momento ativo, o programa, o locutor,
/// a próxima atração e a promoção mantêm a tela viva.
class TelaNoAr extends StatefulWidget {
  final String? streamUrl;
  const TelaNoAr({super.key, this.streamUrl});

  @override
  State<TelaNoAr> createState() => _TelaNoArState();
}

class _TelaNoArState extends State<TelaNoAr> {
  final _estado = EstadoNoAr();

  @override
  void initState() {
    super.initState();
    _estado.iniciar();
  }

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _estado,
      builder: (context, _) {
        final programa = _estado.programa;
        final locutor = _estado.locutor;
        final momento = _estado.momento;

        return Scaffold(
          backgroundColor: Tema.fundo,
          body: SafeArea(
            bottom: false,
            child: _estado.estado == null
                ? const Center(child: CircularProgressIndicator(color: Tema.laranja))
                : RefreshIndicator(
                    color: Tema.laranja,
                    backgroundColor: Tema.superficie,
                    onRefresh: _estado.atualizar,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.md, Espaco.md, Espaco.lg),
                      children: [
                        _cabecalho(),
                        const SizedBox(height: Espaco.lg),

                        // 1º NÍVEL — presença
                        if (_estado.aoVivo) ...[
                          const EtiquetaNoAr(),
                          const SizedBox(height: Espaco.md),
                        ],
                        Text(
                          programa?['nome']?.toString() ?? 'Band FM',
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15),
                        ),
                        if (locutor != null) ...[
                          const SizedBox(height: Espaco.xs),
                          Row(children: [
                            const Icon(Icons.mic_none, size: 16, color: Tema.texto2),
                            const SizedBox(width: 6),
                            Text('com ${locutor['nome']}',
                                style: const TextStyle(fontSize: 15.5, color: Tema.texto2)),
                          ]),
                        ],

                        // Pertencimento: um dado vira sensação de coletivo.
                        if (_estado.ouvintes > 0) ...[
                          const SizedBox(height: Espaco.sm),
                          Text(
                            '${_estado.ouvintes} ${_estado.ouvintes == 1 ? "ouvinte vivendo" : "ouvintes vivendo"} este momento',
                            style: const TextStyle(fontSize: 13.5, color: Tema.texto3),
                          ),
                        ],

                        const SizedBox(height: Espaco.lg),

                        // 3º NÍVEL — participação. Tem prioridade sobre tudo.
                        if (momento != null)
                          CartaoMomento(
                            key: ValueKey(momento['id']),
                            momento: momento,
                            aoResponder: _estado.atualizar,
                          )
                        else
                          _semMomento(),

                        const SizedBox(height: Espaco.md),

                        // Inventário: existe desde o primeiro desenho de tela, mas some
                        // enquanto há interação disputando a atenção.
                        BannerAnuncio(ocultar: momento != null),

                        if (_estado.promocao != null) ...[
                          const SizedBox(height: Espaco.md),
                          _promocao(),
                        ],

                        // 4º NÍVEL — continuidade
                        if (_estado.proxima != null) ...[
                          const SizedBox(height: Espaco.md),
                          _proxima(),
                        ],
                      ],
                    ),
                  ),
          ),
          bottomNavigationBar: MiniPlayer(
            streamUrl: widget.streamUrl,
            programa: programa?['nome']?.toString() ?? 'Band FM',
            locutor: locutor?['nome']?.toString(),
          ),
        );
      },
    );
  }

  Widget _cabecalho() => Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: Tema.laranja, borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.radio, color: Colors.white, size: 19),
          ),
          const SizedBox(width: Espaco.sm),
          const Text('Band FM', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          // Perder a rede não vira tela branca: mostra a última foto e avisa discreto.
          if (_estado.semRede)
            const Row(children: [
              Icon(Icons.cloud_off, size: 14, color: Tema.texto3),
              SizedBox(width: 5),
              Text('sem conexão', style: TextStyle(fontSize: 12, color: Tema.texto3)),
            ]),
        ],
      );

  /// Sem Momento, o app segue vivo. O silêncio faz parte da experiência —
  /// não é para inventar interação o tempo todo.
  Widget _semMomento() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Espaco.md),
        decoration: BoxDecoration(
          color: Tema.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Tema.borda),
        ),
        child: const Row(children: [
          Icon(Icons.graphic_eq, color: Tema.texto3, size: 20),
          SizedBox(width: Espaco.sm),
          Expanded(
            child: Text('A programação está rolando. Fica ligado que já já tem novidade.',
                style: TextStyle(color: Tema.texto2, fontSize: 14.5, height: 1.35)),
          ),
        ]),
      );

  Widget _promocao() {
    final p = _estado.promocao!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Tema.laranja.withValues(alpha: .18), Tema.superficie],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tema.laranja.withValues(alpha: .3)),
      ),
      child: Row(children: [
        const Icon(Icons.card_giftcard, color: Tema.laranja, size: 22),
        const SizedBox(width: Espaco.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('PROMOÇÃO NO AR',
                style: TextStyle(fontSize: 10.5, letterSpacing: 1.3, color: Tema.laranja, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(p['titulo']?.toString() ?? '',
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, height: 1.25)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Tema.texto3),
      ]),
    );
  }

  Widget _proxima() {
    final n = _estado.proxima!;
    final quando = DateTime.tryParse(n['comeca']?.toString() ?? '');
    final hora = quando == null
        ? ''
        : '${quando.hour.toString().padLeft(2, '0')}h${quando.minute.toString().padLeft(2, '0')}';
    return Row(children: [
      const Icon(Icons.schedule, size: 15, color: Tema.texto3),
      const SizedBox(width: 7),
      Expanded(
        child: Text('A seguir, $hora · ${n['nome']}',
            style: const TextStyle(fontSize: 13.5, color: Tema.texto3)),
      ),
    ]);
  }
}
