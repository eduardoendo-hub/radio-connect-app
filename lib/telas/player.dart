import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../tema.dart';
import '../widgets/mini_player.dart';

/// 09 · Player expandido.
///
/// Abre a partir do mini-player. **Não é aba** — o player é importante, mas não é o
/// protagonista.
///
/// **Princípio crítico:** o app funciona mesmo quando o áudio vem do FM, do carro ou
/// de uma caixa inteligente. A plataforma controla o **estado digital**, não a
/// reprodução. Por isso "Falar com a rádio" fica aqui embaixo: mesmo com o som vindo
/// de outro lugar, a conversa continua a um toque.
///
/// Medidas tiradas do handoff, não estimadas: o fundo em três paradas
/// (`#B35708 → #3A1D05 42% → #0A0A0A`), a arte a 150° com raio 14 e a sombra de 70 px
/// que a faz flutuar sobre o gradiente. É essa sombra que dá a profundidade da tela —
/// sem ela a arte vira um retângulo colado no fundo.
class TelaPlayer extends StatelessWidget {
  final EstadoPlayer estado;
  final String programa;
  final String? locutor;
  final String? musica;
  final String? artista;
  final VoidCallback aoAbrirChat;

  const TelaPlayer({
    super.key,
    required this.estado,
    required this.programa,
    this.locutor,
    this.musica,
    this.artista,
    required this.aoAbrirChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BandFMColors.bg,
      body: Container(
        decoration: const BoxDecoration(gradient: BandFMColors.playerGradient),
        child: SafeArea(
          child: Padding(
            // 24 px em toda a tela; a arte recebe mais 4 px de folga própria.
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedBuilder(
              animation: estado,
              builder: (context, _) => Column(children: [
                // ── topo ───────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 34, height: 34,
                          child: Icon(Symbols.keyboard_arrow_down, size: 25),
                        ),
                      ),
                      const Text('BAND FM · 96,1 SÃO PAULO',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w800,
                              letterSpacing: 1.32, color: Color(0xD9FFFFFF))),
                      const SizedBox(
                        width: 34, height: 34,
                        child: Icon(Symbols.more_vert, size: 25),
                      ),
                    ],
                  ),
                ),

                // ── a arte ─────────────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      child: LayoutBuilder(
                        builder: (context, limites) {
                          final lado = limites.maxWidth;
                          return Container(
                            width: lado,
                            height: lado,
                            decoration: BoxDecoration(
                              // 150° no CSS: quase vertical, inclinado para a direita.
                              gradient: const LinearGradient(
                                begin: Alignment(-0.5, -1),
                                end: Alignment(0.5, 1),
                                colors: [Color(0xFFF6821F), Color(0xFF8E3A02)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x8C000000),
                                  blurRadius: 70,
                                  offset: Offset(0, 28),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 62 % da arte, e **todo branco**: o handoff aplica
                                // `brightness(0) invert(1)` no logo. Sobre o laranja,
                                // o logo colorido briga com o próprio fundo — o verde
                                // e o laranja da marca somem e sobra ruído. Em branco
                                // sólido a arte vira uma peça só.
                                SizedBox(
                                  width: lado * .62,
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                        Colors.white, BlendMode.srcIn),
                                    child: Image.asset('assets/logo-emissora.webp',
                                        fit: BoxFit.contain),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: .3),
                                    borderRadius: BorderRadius.circular(BandFMRadii.pill),
                                  ),
                                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                    // Sobre o laranja o ponto é branco, não vermelho:
                                    // o vermelho da marca some no fundo quente.
                                    SizedBox(
                                      width: 9, height: 9,
                                      child: DecoratedBox(decoration: BoxDecoration(
                                        color: Colors.white, shape: BoxShape.circle)),
                                    ),
                                    SizedBox(width: 7),
                                    Text('AO VIVO',
                                        style: TextStyle(
                                            fontSize: 11, fontWeight: FontWeight.w800,
                                            letterSpacing: 1.32, color: Colors.white)),
                                  ]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // ── faixa e artista ────────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(musica ?? programa,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                      Text(artista ?? (locutor != null ? 'com $locutor' : 'Band FM 96,1'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, color: BandFMColors.textSecondary)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Symbols.favorite, fill: 1, size: 28, color: BandFMColors.orange),
                ]),

                // ── controles ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Symbols.alarm, size: 26, color: BandFMColors.textSecondary),
                      GestureDetector(
                        onTap: estado.carregando ? null : estado.alternar,
                        child: Container(
                          width: 70, height: 70,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: estado.carregando
                              ? const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black))
                              : Icon(estado.tocando ? Symbols.pause : Symbols.play_arrow,
                                  fill: 1, size: 42, color: Colors.black),
                        ),
                      ),
                      const Icon(Symbols.volume_up, size: 26, color: BandFMColors.textSecondary),
                    ],
                  ),
                ),

                if (estado.erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(estado.erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFFF9A95))),
                  ),

                // ── rodapé ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Symbols.cast, size: 20, color: BandFMColors.textSecondary),
                      // Mesmo com o som vindo do FM, a conversa continua a um toque.
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).maybePop();
                          aoAbrirChat();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(BandFMRadii.pill),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Symbols.chat, size: 18),
                            SizedBox(width: 6),
                            Text('Falar com a rádio',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                      const Icon(Symbols.share, size: 20, color: BandFMColors.textSecondary),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
