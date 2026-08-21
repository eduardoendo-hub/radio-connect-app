import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../avisos.dart';
import '../estado_respostas.dart';
import '../tema.dart';
import 'assinatura_patrocinio.dart';

/// Fofocômetro — o gancho, a espera e a revelação.
///
/// Todos os outros Momentos pedem uma resposta e fecham em segundos. Este pede
/// **espera**: é o "depois do intervalo a gente conta" da rádio, que é o instrumento de
/// retenção mais antigo do meio e nunca tinha existido em tela.
///
/// Três decisões que sustentam o formato:
///
/// **A revelação não vem junto com o gancho.** O aplicativo recebe apenas o instante da
/// abertura e conta o tempo sozinho; o texto só é buscado quando o relógio zera. Se
/// viesse antes e ficasse escondido na tela, bastaria abrir a aba de rede para estragar
/// a surpresa de todo mundo — e um formato cuja graça é ninguém saber antes não
/// sobrevive a isso.
///
/// **O relógio é o protagonista.** Ele é grande, ocupa o meio do cartão e continua
/// correndo quando o app vai para segundo plano. É ele que segura.
///
/// **A revelação não some.** Depois de abrir, fica na tela e depois na aba Momentos,
/// onde entra fechada e abre ao toque. Quem chegou atrasado ainda consegue ler.
class CartaoFofocometro extends StatefulWidget {
  final Map<String, dynamic> momento;
  const CartaoFofocometro({super.key, required this.momento});

  @override
  State<CartaoFofocometro> createState() => _CartaoFofocometroState();
}

/// O magenta do Fofocômetro. Não aparece em nenhum outro lugar do app — é essa
/// exclusividade que faz a cor virar assinatura do formato.
const _magenta = Color(0xFFE8437B);

class _CartaoFofocometroState extends State<CartaoFofocometro> {
  Timer? _relogio;
  Duration _falta = Duration.zero;
  Map<String, dynamic>? _revelacao;
  bool _buscando = false;
  String? _palpitando;
  bool _avisar = false;
  bool _permitido = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    RegistroDeRespostas.instancia.addListener(_aoMudarRegistro);
  }

  void _aoMudarRegistro() { if (mounted) setState(() {}); }

  @override
  void didUpdateWidget(CartaoFofocometro anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.momento['id'] != widget.momento['id']) {
      setState(() => _revelacao = null);
      _tick();
    }
  }

  @override
  void dispose() {
    _relogio?.cancel();
    RegistroDeRespostas.instancia.removeListener(_aoMudarRegistro);
    super.dispose();
  }

  DateTime? get _quando {
    final f = widget.momento['fofoca'] as Map<String, dynamic>?;
    return DateTime.tryParse(f?['revelarEm']?.toString() ?? '');
  }

  void _tick() {
    final q = _quando;
    if (q == null) return;
    final d = q.difference(DateTime.now());
    if (mounted) setState(() => _falta = d.isNegative ? Duration.zero : d);
    // Deu a hora: busca uma vez e para de tentar.
    if (d.isNegative && _revelacao == null && !_buscando) _revelar();
  }

  Future<void> _revelar() async {
    setState(() => _buscando = true);
    try {
      final r = await Api.obter('/momentos/${widget.momento['id']}/revelacao');
      if (mounted) setState(() => _revelacao = r['revelacao'] as Map<String, dynamic>?);
      if (_avisar && _permitido) {
        Avisos.mostrar(
          'O Fofocômetro abriu',
          widget.momento['titulo']?.toString() ?? 'A gente já conta.',
        );
      }
    } catch (_) {
      // Servidor ainda não considera a hora — relógios não batem ao milissegundo.
      // O próximo tique tenta de novo.
      if (mounted) setState(() => _buscando = false);
    }
  }

  /// O patrocínio vem do campo comum a todos os Momentos, não de dentro da fofoca.
  ///
  /// Era `fofoca.patrocinador` — texto que o produtor digitava. Virou relação com a
  /// campanha vendida, então a mesma leitura serve para qualquer formato e a impressão
  /// entra no relatório da campanha em vez de morrer na tela.
  Object? get _patrocinio => widget.momento['patrocinio'];

  @override
  Widget build(BuildContext context) {
    final abriu = _revelacao != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Identidade própria, e não o laranja de sempre.
        //
        // O Fofocômetro não é mais um Momento: é um formato com nome, que a pessoa
        // aprende a reconhecer e a esperar. Se ele chegasse na mesma superfície e na
        // mesma cor das enquetes, viraria só mais uma pergunta na tela — e o que se
        // quer é o oposto, que ela pense "o Fofocômetro vai abrir".
        //
        // O magenta vem da mesma família quente da marca, mas não é usado em nenhum
        // outro lugar do app. É essa exclusividade que faz a cor virar assinatura.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1420), Color(0xFF1A1016)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _magenta.withValues(alpha: .3)),
        boxShadow: [
          const BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -10),
          BoxShadow(
            color: _magenta.withValues(alpha: .18),
            blurRadius: 40, offset: const Offset(0, 14), spreadRadius: -16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // A etiqueta é o nome do formato, com peso de selo.
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _magenta.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(BandFMRadii.pill),
                border: Border.all(color: _magenta.withValues(alpha: .4)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                _Antena(),
                SizedBox(width: 6),
                Text('FOFOCÔMETRO',
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        letterSpacing: 1.2, color: _magenta)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),

          Text(widget.momento['titulo']?.toString() ?? '',
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800,
                  height: 1.2, letterSpacing: -.5, color: Colors.white)),

          if (!abriu) ...[
            const SizedBox(height: 16),
            _contagem(),
            if (_opcoes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _palpite(),
            ],
          ] else ...[
            const SizedBox(height: 14),
            _aRevelacao(),
          ],

          if (_patrocinio != null) ...[
            const SizedBox(height: 13),
            _assinaturaDoPatrocinio(),
          ],

          // O aviso é a última coisa do cartão, e a menor.
          //
          // No meio da espera ele competia com o palpite, que é a ação principal
          // enquanto o relógio corre. No rodapé ele continua ao alcance de quem procura
          // e sai do caminho de quem não procura — que é o comportamento certo para uma
          // opção, e não para um convite.
          if (!abriu) ...[
            const SizedBox(height: 12),
            Center(child: _meAvise()),
          ],
        ]),
      ),
    );
  }

  /// O relógio, com a frase que explica o que ele significa.
  ///
  /// Número solto não diz nada — "3:41" podia ser tempo de música, de promoção, de
  /// qualquer coisa. "Será revelado em" transforma o relógio em promessa, e é a
  /// promessa que segura.
  /// O relógio na horizontal, e não empilhado no meio do cartão.
  ///
  /// Centralizado e com corpo 46, ele ocupava um terço da altura e empurrava o palpite
  /// e o patrocínio para fora da primeira tela — justamente as duas coisas que precisam
  /// ser vistas durante a espera. Deitado, a mesma informação cabe numa linha: o rótulo
  /// e o "daqui a X minutos" de um lado, o número do outro.
  ///
  /// O número continua sendo o maior elemento do bloco. Ele não precisava ser o maior
  /// elemento da tela.
  Widget _contagem() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('SERÁ REVELADO EM',
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w800,
                      letterSpacing: 1.4, color: BandFMColors.textTertiary)),
              const SizedBox(height: 3),
              Text(_porExtenso(_falta),
                  style: const TextStyle(
                      fontSize: 12.5, color: BandFMColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 12),
          Text(_formatado(_falta),
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  height: 1, letterSpacing: -1.2, color: _magenta,
                  fontFeatures: [FontFeature.tabularFigures()])),
        ],
      );

  /// "O Fofocômetro é um oferecimento de X."
  ///
  /// Fica **durante a espera**, que é o que a marca comprou: o tempo em que a tela é
  /// dela e a pessoa está esperando de propósito. Depois de revelar continua ali, agora
  /// ligada à entrega. É o inventário mais valioso do produto — atenção com hora
  /// marcada vale mais que qualquer banner de rolagem.
  Widget _assinaturaDoPatrocinio() =>
      AssinaturaPatrocinio.talvez(
        _patrocinio,
        posicao: 'assinatura_momento',
        referenciaId: widget.momento['id']?.toString(),
      ) ??
      const SizedBox.shrink();


  Widget _aRevelacao() {
    final texto = _revelacao?['texto']?.toString() ?? '';
    final img = _revelacao?['imagemUrl']?.toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, v, filho) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: filho),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 1, color: _magenta.withValues(alpha: .22)),
        const SizedBox(height: 16),
        if (img != null && img.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(BandFMRadii.md),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(img, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(texto,
            style: const TextStyle(
                fontSize: 15.5, height: 1.5, color: BandFMColors.textPrimary)),
      ]),
    );
  }

  /// "Me avisa quando abrir".
  ///
  /// **O que isto faz hoje, com honestidade:** a notificação é do navegador — o app
  /// pede permissão e dispara um aviso do sistema no instante da abertura, mesmo com a
  /// aba em segundo plano. Funciona no Android e no computador; no iOS depende de o
  /// app estar instalado na tela de início.
  ///
  /// **O que ainda não faz:** avisar com o aplicativo fechado. Isso é push de verdade e
  /// exige Firebase configurado por emissora — trabalho de infraestrutura, não de tela.
  /// Enquanto não existe, é melhor entregar o aviso que funciona do que fingir um que
  /// não vai chegar: prometer notificação e não notificar custa mais confiança do que
  /// não ter o botão.
  Widget _meAvise() {
    if (_avisar) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Symbols.notifications_active, fill: 1, size: 13, color: _magenta),
        const SizedBox(width: 6),
        Text(
          _permitido ? 'A gente te avisa quando abrir' : 'Deixe a aba aberta que avisamos aqui',
          style: const TextStyle(fontSize: 11.5, color: BandFMColors.textTertiary),
        ),
      ]);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pedirAviso,
        borderRadius: BorderRadius.circular(7),
        // Canto reto, e não a pílula dos palpites.
        //
        // Forma diferente é o que separa "escolher uma opção" de "ligar um lembrete":
        // com o mesmo formato, o dedo trata os quatro botões como a mesma família e o
        // aviso vira um quarto palpite.
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Symbols.notifications, size: 13,
                color: Colors.white.withValues(alpha: .62)),
            const SizedBox(width: 6),
            Text('Me avisa quando abrir',
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: .62))),
          ]),
        ),
      ),
    );
  }

  Future<void> _pedirAviso() async {
    final ok = await Avisos.pedirPermissao();
    if (mounted) setState(() { _avisar = true; _permitido = ok; });
  }

  List<Map<String, dynamic>> get _opcoes =>
      (widget.momento['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

  /// O palpite durante a espera.
  ///
  /// Transforma espera passiva em participação — e, o que importa mais, dá à pessoa um
  /// motivo próprio para voltar: quem chutou quer saber se acertou. É o mesmo mecanismo
  /// de resposta dos outros Momentos, com a diferença de que aqui a resposta certa
  /// existe e vai aparecer.
  Widget _palpite() {
    final meu = RegistroDeRespostas.instancia.opcaoDe(widget.momento['id']?.toString());
    final jaPalpitou = meu != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(jaPalpitou ? 'Seu palpite está feito' : 'Enquanto isso, dá seu palpite',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: BandFMColors.textSecondary)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: _opcoes.map((o) {
          final id = o['id']?.toString();
          final escolhido = jaPalpitou ? meu == id : _palpitando == id;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (jaPalpitou || _palpitando != null) ? null : () => _palpitar(id),
              borderRadius: BorderRadius.circular(BandFMRadii.pill),
              child: Opacity(
                opacity: jaPalpitou && !escolhido ? .4 : 1,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: escolhido
                        ? _magenta.withValues(alpha: .22)
                        : Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(BandFMRadii.pill),
                    border: Border.all(
                      color: escolhido
                          ? _magenta.withValues(alpha: .9)
                          : Colors.white.withValues(alpha: .22),
                      width: escolhido ? 1.5 : 1,
                    ),
                  ),
                  child: Text(o['rotulo']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Future<void> _palpitar(String? opcaoId) async {
    setState(() => _palpitando = opcaoId);
    try {
      await Api.enviar('/momentos/${widget.momento['id']}/responder', {
        if (opcaoId != null) 'opcaoId': opcaoId,
        'chaveIdempotencia': '${widget.momento['id']}-${DateTime.now().millisecondsSinceEpoch}',
      });
      RegistroDeRespostas.instancia.marcar(widget.momento['id'].toString(), opcaoId);
    } catch (_) {
      // Palpite não é voto de enquete: se falhar, a pessoa tenta de novo sem perder nada.
    } finally {
      if (mounted) setState(() => _palpitando = null);
    }
  }

  /// "daqui a 3 minutos" lê melhor que "03:41" para quem só passou o olho.
  static String _porExtenso(Duration d) {
    if (d.inSeconds <= 0) return 'abrindo agora';
    if (d.inMinutes < 1) return 'daqui a menos de um minuto';
    if (d.inMinutes == 1) return 'daqui a um minuto';
    return 'daqui a ${d.inMinutes} minutos';
  }

  static String _formatado(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// A antena que pisca — o sinal de que tem coisa vindo.
class _Antena extends StatefulWidget {
  const _Antena();
  @override
  State<_Antena> createState() => _AntenaState();
}

class _AntenaState extends State<_Antena> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .4, end: 1).animate(_c),
        child: const Icon(Symbols.campaign, fill: 1, size: 12, color: _magenta),
      );
}
