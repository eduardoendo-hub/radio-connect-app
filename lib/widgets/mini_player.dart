import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../tema.dart';
import 'marca_emissora.dart';

/// O player.
///
/// Importante, mas **não é o protagonista**. Fica como mini-player persistente,
/// acompanhando a navegação — nunca como item de menu.
///
/// A emissora fornece o `m3u8`; não hospedamos nem transcodificamos áudio. E o pré-roll
/// toca ANTES de abrir o stream: se a decisão de anúncio não responder em 2 segundos,
/// desiste e abre a rádio. Nunca fazer o ouvinte esperar por publicidade que não veio.
class MiniPlayer extends StatefulWidget {
  final String? streamUrl;
  final String programa;
  final String? locutor;
  const MiniPlayer({super.key, this.streamUrl, required this.programa, this.locutor});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final _player = AudioPlayer();
  bool _tocando = false;
  bool _carregando = false;
  bool _noPreRoll = false;
  String? _erro;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (_tocando) {
      await _player.pause();
      setState(() => _tocando = false);
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      // Pré-roll: o anúncio é uma fonte de áudio como outra qualquer. Não precisa de
      // SDK pesado — o player já sabe tocar um arquivo antes de abrir o stream.
      // (Na demonstração o inventário ainda não está ligado; o gancho fica aqui.)
      setState(() => _noPreRoll = false);

      if (widget.streamUrl == null || widget.streamUrl!.isEmpty) {
        setState(() {
          _erro = 'A transmissão está indisponível no momento.';
          _carregando = false;
        });
        return;
      }

      await _player.setUrl(widget.streamUrl!);
      await _player.play();
      setState(() {
        _tocando = true;
        _carregando = false;
      });
    } catch (_) {
      // A falha é do stream da emissora, não nossa — e o resto do app continua.
      setState(() {
        _erro = 'Não conseguimos abrir a transmissão agora.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.md, vertical: 10),
      decoration: const BoxDecoration(
        color: Tema.superficie,
        border: Border(top: BorderSide(color: Tema.borda)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Tema.superficieAlta,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Tema.borda),
              ),
              child: const MarcaEmissora(altura: 22),
            ),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _noPreRoll ? 'Publicidade' : widget.programa,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _erro ?? (widget.locutor != null ? 'com ${widget.locutor}' : 'Band FM 96,1'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _erro != null ? const Color(0xFFFF9A95) : Tema.texto2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _carregando ? null : _alternar,
              iconSize: 40,
              icon: _carregando
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Tema.laranja))
                  : Icon(
                      _tocando ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: Tema.laranja,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
