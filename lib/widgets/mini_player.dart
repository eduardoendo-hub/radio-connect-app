import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
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

  /// O anúncio tocando agora, se houver. A tela usa para mostrar a faixa de pré-roll.
  Map<String, dynamic>? _preRoll;
  int _restanteDoPreRoll = 0;
  Map<String, dynamic>? get preRoll => _preRoll;
  int get restanteDoPreRoll => _restanteDoPreRoll;

  /// Quem manda no botão é o player, não uma variável nossa.
  ///
  /// Antes havia um `_tocando` mantido à mão, que descrevia a intenção e não a
  /// realidade: se o stream caísse, ou o navegador pausasse sozinho, o botão continuava
  /// mostrando pause com o silêncio no ar.
  bool get tocando => _player.playing || _preRoll != null;

  /// Anúncio no ar, antes da rádio.
  ///
  /// Precisa ser um estado próprio, e não "carregando": durante o pré-roll **tem som
  /// saindo**, e um botão girando enquanto o áudio toca diz à pessoa que o app travou.
  /// O botão mostra pause — porque pausar é justamente o que ele faz — e a faixa
  /// explica que a rádio entra em seguida.
  bool get tocandoAnuncio => _preRoll != null;

  bool get carregando => _carregando;
  String? get erro => _erro;
  bool get fonteExterna => _url == null || _url!.isEmpty;

  EstadoPlayer() {
    // Qualquer mudança vinda do próprio player — buffer, pausa do sistema, fim de
    // conexão — se reflete na tela na hora.
    _player.playerStateStream.listen((_) => notifyListeners());
    _relogio = Timer.periodic(const Duration(minutes: 1), (_) => _contarMinuto());
  }

  Timer? _relogio;

  /// Um minuto ouvido, avisado ao servidor.
  ///
  /// **É `tocando` que decide, não a intenção.** Se o stream cair ou o sistema pausar, o
  /// player diz que não está tocando e o minuto não conta — que é a diferença entre medir
  /// escuta e medir aba aberta.
  ///
  /// O anúncio de pré-roll não entra: quem está esperando a rádio começar não está
  /// ouvindo a rádio, e contar aquilo como escuta seria inflar o Índice com o tempo que a
  /// pessoa passa querendo que ele acabe.
  ///
  /// Sem `await` e sem tratar erro: é telemetria. Se falhar, o que se perde é um minuto
  /// num número — não a música que está tocando.
  void _contarMinuto() {
    if (!_player.playing) return;
    Api.enviar('/sinal-de-vida', {'minutos': 1})
        .catchError((_) => <String, dynamic>{});
  }



  void definirFonte(String? url) => _url = url;

  AudioPlayer? _playerDoAnuncio;

  Future<void> alternar() async {
    // Pausar durante o anúncio para o anúncio — e não solta a rádio no lugar dele.
    // Quem apertou pause quer silêncio, não a próxima faixa.
    if (_preRoll != null) {
      await _playerDoAnuncio?.pause();
      _preRoll = null;
      _restanteDoPreRoll = 0;
      notifyListeners();
      return;
    }
    if (_player.playing) {
      await _player.pause();
      notifyListeners();
      return;
    }
    _erro = null;
    try {
      if (fonteExterna) {
        _carregando = true;
        notifyListeners();
        // A transmissão é da emissora, não nossa. Falhar aqui não pode derrubar o
        // resto do app: Momentos, chat e promoções seguem funcionando.
        _erro = 'A transmissão está indisponível no momento.';
      } else {
        // O pré-roll entra aqui, antes da rádio.
        //
        // Regra que não se negocia: **se o anúncio falhar, a rádio entra assim mesmo**.
        // Publicidade que impede a pessoa de ouvir rádio destrói o produto para salvar
        // uma impressão. Por isso tudo aqui dentro é `try` sem `rethrow`.
        //
        // `_carregando` fica FORA daqui: durante o anúncio o estado é "tocando", não
        // "carregando". O spinner só volta na abertura do stream, que é rápida.
        await _talvezPreRoll();

        _carregando = true;
        notifyListeners();
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

  /// Toca o pré-roll e só volta quando ele termina.
  ///
  /// O servidor decide se existe anúncio para esta pessoa agora — teto de sessão e
  /// intervalo mínimo são conta dele. Aqui só se pergunta e se toca.
  Future<void> _talvezPreRoll() async {
    Timer? conta;
    try {
      final r = await Api.obter('/anuncios?posicao=preroll');
      final a = r['anuncio'] as Map<String, dynamic>?;
      if (a == null || a['url'] == null) return;

      _preRoll = a;
      _restanteDoPreRoll = (a['duracao'] as num?)?.toInt() ?? 10;
      notifyListeners();

      final anuncio = AudioPlayer();
      _playerDoAnuncio = anuncio;
      try {
        await anuncio.setUrl(a['url'].toString()).timeout(const Duration(seconds: 6));
        unawaited(
          Api.enviar('/anuncios/${a['impressaoId']}/confirmar', {'visivel': true})
              .catchError((_) => <String, dynamic>{}),
        );
        unawaited(anuncio.play());

        // Conta para a tela enquanto o áudio corre.
        conta = Timer.periodic(const Duration(seconds: 1), (t) {
          _restanteDoPreRoll = (_restanteDoPreRoll - 1).clamp(0, 999);
          notifyListeners();
        });

        // `completed` chega quando o arquivo acaba. Se nunca chegar — rede ruim,
        // formato estranho —, o teto de duração + 3s solta a rádio de qualquer jeito.
        await anuncio.playerStateStream
            .firstWhere((e) => e.processingState == ProcessingState.completed)
            .timeout(Duration(seconds: _restanteDoPreRoll + 3));

        // "Concluído" é o que separa impressão de impressão paga: o anúncio foi ouvido
        // até o fim, não apenas servido.
        unawaited(
          Api.enviar('/anuncios/${a['impressaoId']}/confirmar', {'concluido': true})
              .catchError((_) => <String, dynamic>{}),
        );
      } finally {
        conta?.cancel();
        await anuncio.dispose();
        _playerDoAnuncio = null;
        _preRoll = null;
        _restanteDoPreRoll = 0;
        notifyListeners();
      }
    } catch (_) {
      // Falhou? A rádio entra do mesmo jeito.
      _preRoll = null;
      _restanteDoPreRoll = 0;
    }
  }

  @override
  void dispose() {
    _relogio?.cancel();
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
                // Spinner só quando de fato não há som. Durante o anúncio tem áudio
                // saindo, então o botão mostra pause.
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
