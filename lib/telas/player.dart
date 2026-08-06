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
          child: AnimatedBuilder(
            animation: estado,
            builder: (context, _) => Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Symbols.keyboard_arrow_down, size: 26),
                  ),
                  const Expanded(
                    child: Text('BAND FM · 96,1 SÃO PAULO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.w800,
                            letterSpacing: 1.3, color: BandFMColors.textSecondary)),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Symbols.more_vert, size: 22)),
                ]),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: BandFMColors.momentGradient,
                      borderRadius: BorderRadius.circular(BandFMRadii.hero),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 34),
                        child: Image.asset('assets/logo-emissora.webp', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: BandFMSpacing.x4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .3),
                          borderRadius: BorderRadius.circular(BandFMRadii.pill),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Symbols.circle, fill: 1, size: 8, color: Colors.white),
                          SizedBox(width: 6),
                          Text('AO VIVO',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2, color: Colors.white)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(musica ?? programa,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                      const SizedBox(height: 3),
                      Text(artista ?? (locutor != null ? 'com $locutor' : 'Band FM 96,1'),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: BandFMColors.textSecondary)),
                    ]),
                  ),
                  const Icon(Symbols.favorite, fill: 1, size: 24, color: BandFMColors.orange),
                ]),
              ),

              const SizedBox(height: BandFMSpacing.x5),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Symbols.alarm, size: 24, color: BandFMColors.textSecondary),
                const SizedBox(width: 40),
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
                            fill: 1, size: 34, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 40),
                const Icon(Symbols.volume_up, size: 24, color: BandFMColors.textSecondary),
              ]),

              if (estado.erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(estado.erro!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFFF9A95))),
                ),

              const SizedBox(height: BandFMSpacing.x6),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, BandFMSpacing.x5),
                child: Row(children: [
                  const Icon(Symbols.cast, size: 21, color: BandFMColors.textSecondary),
                  const Spacer(),
                  // Mesmo com o som vindo do FM, a conversa continua a um toque.
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).maybePop();
                      aoAbrirChat();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: BandFMColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(BandFMRadii.pill),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Symbols.chat, size: 17),
                        SizedBox(width: 8),
                        Text('Falar com a rádio',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Symbols.share, size: 21, color: BandFMColors.textSecondary),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
