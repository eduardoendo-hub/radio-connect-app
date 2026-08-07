import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';

/// 07 · Chat.
///
/// Conversa privada ouvinte ↔ rádio. **Sem comunidade e sem comentário público no
/// MVP** — o que exige moderação, políticas e denúncias fica para depois.
///
/// Linguagem de mensageiro, porque é o que o brasileiro já tem no dedo: balões com
/// canto reto do lado do remetente, horário dentro do balão, `done_all` nos enviados.
///
/// A conversa é real: o que a pessoa escreve aqui cai na fila da produção no Studio, e
/// a resposta do produtor volta por esta mesma tela. O Chatwoot entra depois como motor
/// de atendimento, espelhando as duas pontas — nada nesta tela muda quando isso ligar.
class TelaChat extends StatefulWidget {
  const TelaChat({super.key});

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _Mensagem {
  final String texto;
  final bool minha;
  final String hora;
  /// A duração vem junto quando o envio de áudio existir; até lá o balão mostra só
  /// a forma de onda.
  final bool audio;
  const _Mensagem(this.texto, this.minha, this.hora, {this.audio = false});
}

class _TelaChatState extends State<TelaChat> {
  final _campo = TextEditingController();
  final _rolagem = ScrollController();
  var _mensagens = <_Mensagem>[];
  bool _carregando = true;
  bool _enviando = false;
  Timer? _relogio;

  @override
  void initState() {
    super.initState();
    _carregar();
    // A resposta da produção precisa chegar sozinha: o ouvinte não vai puxar para
    // atualizar esperando um alô.
    _relogio = Timer.periodic(const Duration(seconds: 5), (_) => _carregar(silencioso: true));
  }

  String _hora(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _carregar({bool silencioso = false}) async {
    try {
      final r = await Api.obter('/conversa');
      if (!mounted) return;
      final lista = ((r['mensagens'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map((m) => _Mensagem(
                m['conteudo']?.toString() ?? '',
                m['direcao'] == 'ouvinte_para_radio',
                _hora(m['enviadaEm']?.toString() ?? ''),
                audio: m['tipo'] == 'audio',
              ))
          .toList();
      final cresceu = lista.length != _mensagens.length;
      setState(() {
        _mensagens = lista;
        _carregando = false;
      });
      if (cresceu) _aoFim();
    } catch (_) {
      if (mounted && !silencioso) setState(() => _carregando = false);
    }
  }

  void _aoFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rolagem.hasClients) {
        _rolagem.animateTo(_rolagem.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _enviar() async {
    final t = _campo.text.trim();
    if (t.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    // Aparece na hora: a mensagem é da pessoa, não do servidor. Se falhar, a recarga
    // seguinte tira — mas travar o dedo esperando a rede é pior.
    setState(() {
      _mensagens = [..._mensagens, _Mensagem(t, true, TimeOfDay.now().format(context))];
      _campo.clear();
    });
    _aoFim();
    try {
      await Api.enviar('/conversa/mensagens', {'conteudo': t});
      await _carregar(silencioso: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sua mensagem não saiu. Tente de novo.'),
          backgroundColor: BandFMColors.surfaceRaised,
        ));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _rolagem.dispose();
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _cabecalho(),
      Expanded(
        child: _PapelDeOndas(
          child: _carregando
              ? const Center(child: CircularProgressIndicator(color: BandFMColors.orange))
              : ListView(
                  controller: _rolagem,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                  children: [
                    _avisoPrivacidade(),
                    const SizedBox(height: 14),
                    if (_mensagens.isEmpty) _primeiraVez(),
                    ..._mensagens.map(_balao),
                  ],
                ),
        ),
      ),
      _barra(),
    ]);
  }

  /// Conversa vazia não pode parecer erro. O convite é o primeiro balão.
  Widget _primeiraVez() => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: const BoxDecoration(
            color: BandFMColors.surfaceRaised,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(BandFMRadii.bubble),
              topRight: Radius.circular(BandFMRadii.bubble),
              bottomLeft: Radius.circular(BandFMRadii.bubbleTail),
              bottomRight: Radius.circular(BandFMRadii.bubble),
            ),
          ),
          child: const Text(
            'Oi! 🧡 Manda seu recado ou o pedido de música que a gente coloca no ar.',
            style: TextStyle(fontSize: 14.5, height: 1.35),
          ),
        ),
      );

  Widget _cabecalho() => Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: BandFMColors.line)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: BandFMColors.momentGradient,
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(Symbols.radio, size: 21, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Band FM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -.2)),
              const SizedBox(height: 2),
              Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: BandFMColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('A produção está respondendo',
                    style: TextStyle(fontSize: 12, color: BandFMColors.green)),
              ]),
            ]),
          ),
        ]),
      );

  Widget _avisoPrivacidade() => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: BandFMColors.surface,
            borderRadius: BorderRadius.circular(BandFMRadii.md),
          ),
          child: const Text(
            'Esta conversa é só entre você e a rádio.\nNinguém mais vê suas mensagens.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, height: 1.45, color: BandFMColors.textTertiary),
          ),
        ),
      );

  Widget _balao(_Mensagem m) {
    return Align(
      alignment: m.minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 9, 10, 8),
        decoration: BoxDecoration(
          color: m.minha ? BandFMColors.orange : BandFMColors.surfaceRaised,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(BandFMRadii.bubble),
            topRight: const Radius.circular(BandFMRadii.bubble),
            // O canto reto marca o lado de quem falou — o detalhe que faz parecer
            // mensageiro de verdade.
            bottomLeft: Radius.circular(m.minha ? BandFMRadii.bubble : BandFMRadii.bubbleTail),
            bottomRight: Radius.circular(m.minha ? BandFMRadii.bubbleTail : BandFMRadii.bubble),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          if (m.audio)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Symbols.play_arrow, fill: 1, size: 22, color: m.minha ? Colors.black : Colors.white),
              const SizedBox(width: 8),
              // Forma de onda: barras de alturas variadas, sem animação.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(18, (i) {
                  final alturas = [6, 11, 8, 14, 9, 5, 12, 7, 15, 10, 6, 13, 8, 11, 5, 9, 12, 7];
                  return Container(
                    width: 2.5,
                    height: alturas[i].toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: (m.minha ? Colors.black : Colors.white).withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ])
          else
            Text(
              m.texto,
              style: TextStyle(
                fontSize: 14.5, height: 1.35,
                fontWeight: m.minha ? FontWeight.w500 : FontWeight.w400,
                color: m.minha ? Colors.black : Colors.white,
              ),
            ),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(m.hora,
                style: TextStyle(
                    fontSize: 10.5,
                    color: (m.minha ? Colors.black : Colors.white).withValues(alpha: .6))),
            if (m.minha) ...[
              const SizedBox(width: 4),
              Icon(Symbols.done_all, size: 13, color: Colors.black.withValues(alpha: .6)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _barra() => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: BandFMColors.line)),
        ),
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: BandFMColors.surfaceRaised,
                borderRadius: BorderRadius.circular(BandFMRadii.pill),
              ),
              child: Row(children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Symbols.mood, size: 21, color: BandFMColors.textTertiary),
                ),
                Expanded(
                  child: TextField(
                    controller: _campo,
                    onSubmitted: (_) => _enviar(),
                    style: const TextStyle(fontSize: 14.5),
                    decoration: const InputDecoration(
                      hintText: 'Escreva sua mensagem…',
                      hintStyle: TextStyle(color: BandFMColors.textTertiary, fontSize: 14.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                    ),
                  ),
                ),
                const Icon(Symbols.attach_file, size: 20, color: BandFMColors.textTertiary),
                const SizedBox(width: 12),
                const Icon(Symbols.photo_camera, size: 20, color: BandFMColors.textTertiary),
                const SizedBox(width: 12),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          // Áudio é essencial em rádio: a emissora pode levar a mensagem ao ar.
          GestureDetector(
            onTap: _enviando ? null : _enviar,
            child: Container(
              width: BandFMSpacing.minTouchTarget,
              height: BandFMSpacing.minTouchTarget,
              decoration: const BoxDecoration(color: BandFMColors.orange, shape: BoxShape.circle),
              child: Icon(_campo.text.trim().isEmpty ? Symbols.mic : Symbols.send,
                  fill: 1, size: 21, color: Colors.black),
            ),
          ),
        ]),
      );
}

/// O papel de parede do chat: um campo de ondas.
///
/// Preto chapado atrás dos balões deixa a conversa flutuando no vazio. A primeira
/// tentativa foram pontos — textura de mensageiro genérico, que não dizia nada sobre
/// onde a pessoa está. A segunda foram ondas paralelas, iguais e igualmente espaçadas:
/// resolveu o assunto e criou outro problema, porque linha uniforme repetida lê como
/// pauta de caderno, não como sinal.
///
/// Aqui cada onda tem **amplitude, fase e período próprios**, e o espaçamento entre
/// elas respira — aperta em algumas alturas, abre em outras. O volume nasce da
/// densidade: onde as linhas se aproximam, elas também ficam mais fortes, do mesmo
/// jeito que no fundo do Studio. É o que faz o campo parecer orgânico em vez de
/// impresso.
///
/// Continua discreto: o pico é 4% de branco. Se der para parar e "ler o desenho",
/// passou do ponto — ele existe para o preto não ser um vazio, e mais nada.
///
/// Desenhado em vetor: custa zero byte de download e fica nítido em qualquer densidade.
class _PapelDeOndas extends StatelessWidget {
  final Widget child;
  const _PapelDeOndas({required this.child});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PintorDeOndas(), child: child);
}

class _PintorDeOndas extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ruído determinístico, escrito à mão: o mesmo desenho a cada abertura do app.
    // Aleatório de verdade faria o fundo mudar a cada rolagem — e um papel de parede
    // que se move sozinho é exatamente o tipo de coisa que a pessoa nota.
    double embaralha(int i, double a, double b) {
      final v = math.sin(i * 12.9898 + 78.233) * 43758.5453;
      return a + (v - v.floor()) * (b - a);
    }

    var y = -20.0;
    var i = 0;
    while (y < size.height + 30) {
      // O espaçamento oscila devagar ao longo da altura: em algumas faixas as ondas
      // se juntam, em outras se abrem.
      final aperto = math.sin(y / 260 * 2 * math.pi);
      final espaco = 22.0 + aperto * 9.0;

      // Onde aperta, escurece menos — a densidade vira luz.
      final forca = 0.026 + (1 - (aperto + 1) / 2) * 0.016;

      final amplitude = embaralha(i, 5, 13);
      final periodo = embaralha(i + 100, 130, 320);
      final fase = embaralha(i + 200, 0, 2 * math.pi);
      final inclinacao = embaralha(i + 300, -0.05, 0.05);

      final tinta = Paint()
        ..color = Colors.white.withValues(alpha: forca)
        ..style = PaintingStyle.stroke
        ..strokeWidth = embaralha(i + 400, 0.8, 1.5);

      final caminho = Path();
      for (double x = 0; x <= size.width; x += 4) {
        final onda = y +
            x * inclinacao +
            amplitude * math.sin(x / periodo * 2 * math.pi + fase) +
            amplitude * .35 * math.sin(x / (periodo * .41) * 2 * math.pi + fase * 1.7);
        x == 0 ? caminho.moveTo(x, onda) : caminho.lineTo(x, onda);
      }
      canvas.drawPath(caminho, tinta);

      y += espaco;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
