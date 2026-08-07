import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../tema.dart';

/// Estado do player, compartilhado entre o mini-player e o player expandido.
///
/// **Princípio crítico:** o app precisa funcionar mesmo quando o áudio vem do FM, do
/// carro ou de uma caixa inteligente. `fonteExterna` marca esse caso — a plataforma
/// controla o **estado digital**, não a reprodução.
class EstadoPlayer extends ChangeNotifier {
  final _player = AudioPlayer();
  String? _url;
  bool _fonteAberta = false;
  bool _carregando = false;
  String? _erro;

  /// Quem manda no botão é o player, não uma variável nossa.
  ///
  /// Antes havia um `_tocando` mantido à mão, que descrevia a intenção e não a
  /// realidade: se o stream caísse, ou o navegador pausasse sozinho, o botão continuava
  /// mostrando pause com o silêncio no ar.
  bool get tocando => _player.playing;
  bool get carregando => _carregando;
  String? get erro => _erro;
  bool get fonteExterna => _url == null || _url!.isEmpty;

  EstadoPlayer() {
    // Qualquer mudança vinda do próprio player — buffer, pausa do sistema, fim de
    // conexão — se reflete na tela na hora.
    _player.playerStateStream.listen((_) => notifyListeners());
  }

  void definirFonte(String? url) => _url = url;

  Future<void> alternar() async {
    if (_player.playing) {
      await _player.pause();
      notifyListeners();
      return;
    }
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      if (fonteExterna) {
        // A transmissão é da emissora, não nossa. Falhar aqui não pode derrubar o
        // resto do app: Momentos, chat e promoções seguem funcionando.
        _erro = 'A transmissão está indisponível no momento.';
      } else {
        if (!_fonteAberta) {
          // `preload: false` é o detalhe que faz o rádio ao vivo tocar.
          //
          // `setUrl` resolve quando conhece a **duração** do áudio — e transmissão ao
          // vivo não tem fim, então esse Future ficava pendurado para sempre. O
          // resultado era o pior tipo de falha: nenhum erro, nenhum log, o botão
          // preso em "carregando" e o silêncio.
          //
          // Sem pré-carga, a fonte é registrada na hora e quem puxa os bytes é o
          // `play()`. O timeout é rede de segurança para o caso de o servidor da
          // emissora não responder.
          await _player
              .setAudioSource(AudioSource.uri(Uri.parse(_url!)), preload: false)
              .timeout(const Duration(seconds: 10));
          _fonteAberta = true;
        }
        // O pré-roll entraria aqui, antes de soltar o play — o player já sabe tocar um
        // arquivo antes, então não precisa de SDK pesado.
        await _player.play();
      }
    } catch (_) {
      // Uma tentativa falha não pode deixar a fonte num meio-termo: a próxima
      // tentativa reabre do zero.
      _fonteAberta = false;
      _erro = 'Não conseguimos abrir a transmissão agora.';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// O mini-player.
///
/// Vive **acima da tab bar**, presente em todas as abas. Some só no player expandido
/// e na entrada. O player é importante, mas não é o protagonista — por isso nunca
/// virou item de menu.
class MiniPlayer extends StatelessWidget {
  final EstadoPlayer estado;
  final String titulo;
  final String apoio;
  final VoidCallback aoExpandir;

  const MiniPlayer({
    super.key,
    required this.estado,
    required this.titulo,
    required this.apoio,
    required this.aoExpandir,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: estado,
      builder: (context, _) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: aoExpandir,
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: BandFMColors.miniPlayer,
              borderRadius: BorderRadius.circular(BandFMRadii.md),
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  gradient: BandFMColors.momentGradient,
                  borderRadius: BorderRadius.circular(BandFMRadii.sm),
                ),
                child: const Icon(Symbols.radio, size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(titulo,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -.1)),
                    const SizedBox(height: 2),
                    Text(
                      estado.erro ?? apoio,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: estado.erro != null ? const Color(0xFFFF9A95) : BandFMColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: estado.carregando ? null : estado.alternar,
                iconSize: 26,
                visualDensity: VisualDensity.compact,
                icon: estado.carregando
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(estado.tocando ? Symbols.pause : Symbols.play_arrow,
                        fill: 1, color: Colors.white),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
