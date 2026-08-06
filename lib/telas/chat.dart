import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../tema.dart';

/// 07 · Chat.
///
/// Conversa privada ouvinte ↔ rádio. **Sem comunidade e sem comentário público no
/// MVP** — o que exige moderação, políticas e denúncias fica para depois.
///
/// Linguagem de mensageiro, porque é o que o brasileiro já tem no dedo: balões com
/// canto reto do lado do remetente, horário dentro do balão, `done_all` nos enviados.
///
/// **Estado atual: conversa simulada.** O backend já tem o modelo de Conversa e
/// Mensagem, e a integração com o Chatwoot entra em seguida — as mensagens abaixo
/// existem para validar a linguagem visual antes de ligar o motor.
class TelaChat extends StatefulWidget {
  const TelaChat({super.key});

  @override
  State<TelaChat> createState() => _TelaChatState();
}

class _Mensagem {
  final String texto;
  final bool minha;
  final String hora;
  final bool audio;
  final String? duracao;
  const _Mensagem(this.texto, this.minha, this.hora, {this.audio = false, this.duracao});
}

class _TelaChatState extends State<TelaChat> {
  final _campo = TextEditingController();

  final _mensagens = <_Mensagem>[
    const _Mensagem('Bom dia! 🧡 Manda seu recado ou o pedido de música que a gente coloca no ar.',
        false, '9:01'),
    const _Mensagem('Bom dia! Alô pra turma da firma em Osasco 🙌', true, '9:04'),
    const _Mensagem('', true, '9:05', audio: true, duracao: '0:12'),
    const _Mensagem('Anotado, Maria! Seu alô sai no ar depois do intervalo. 🎶', false, '9:07'),
  ];

  void _enviar() {
    final t = _campo.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _mensagens.add(_Mensagem(t, true, TimeOfDay.now().format(context)));
      _campo.clear();
    });
  }

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _cabecalho(),
      Expanded(
        child: _PapelDePontos(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
            children: [
              _avisoPrivacidade(),
              const SizedBox(height: 14),
              ..._mensagens.map(_balao),
            ],
          ),
        ),
      ),
      _barra(),
    ]);
  }

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
              const SizedBox(width: 9),
              Text(m.duracao ?? '',
                  style: TextStyle(
                      fontSize: 12,
                      color: (m.minha ? Colors.black : Colors.white).withValues(alpha: .7))),
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
            onTap: _enviar,
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

/// Papel de parede de pontos.
///
/// `radial-gradient(rgba(255,255,255,.035) 1px, transparent 1px)` a cada 22 px —
/// textura suficiente para os balões terem sobre o que flutuar, discreta o bastante
/// para ninguém reparar. Desenhado, não empacotado como imagem.
class _PapelDePontos extends StatelessWidget {
  final Widget child;
  const _PapelDePontos({required this.child});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PintorDePontos(), child: child);
}

class _PintorDePontos extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()..color = Colors.white.withValues(alpha: .035);
    const passo = 22.0;
    for (double y = 0; y < size.height; y += passo) {
      for (double x = 0; x < size.width; x += passo) {
        canvas.drawCircle(Offset(x, y), 1, tinta);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
