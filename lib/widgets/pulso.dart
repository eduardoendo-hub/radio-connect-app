import 'package:flutter/material.dart';
import '../tema.dart';

/// O pulso do NO AR.
///
/// `scale(1) → 1.35 → 1`, curva `cubic-bezier(.22,.61,.36,1)`.
///
/// **O ritmo comunica estado**, não é decoração:
///   4,0 s → fora do ar
///   2,4 s → no ar
///   1,1 s → com Momento ativo
///
/// Respeita movimento reduzido: quem pediu menos animação recebe um ponto estático.
enum RitmoPulso { foraDoAr, noAr, momentoAtivo }

const _duracoes = {
  RitmoPulso.foraDoAr: Duration(milliseconds: 4000),
  RitmoPulso.noAr: Duration(milliseconds: 2400),
  RitmoPulso.momentoAtivo: Duration(milliseconds: 1100),
};

class Pulso extends StatefulWidget {
  final double tamanho;
  final RitmoPulso ritmo;
  const Pulso({super.key, this.tamanho = 7, this.ritmo = RitmoPulso.noAr});

  @override
  State<Pulso> createState() => _PulsoState();
}

class _PulsoState extends State<Pulso> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _duracoes[widget.ritmo],
  )..repeat();

  @override
  void didUpdateWidget(Pulso anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.ritmo != widget.ritmo) {
      _c.duration = _duracoes[widget.ritmo];
      _c
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semAnimacao = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ponto = Container(
      width: widget.tamanho,
      height: widget.tamanho,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: BandFMColors.liveDot),
    );
    if (semAnimacao) return ponto;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Sobe até 1,35 na primeira metade e volta — o batimento, não um piscar.
        final t = _c.value < .5 ? _c.value * 2 : (1 - _c.value) * 2;
        final escala = 1 + 0.35 * Curves.easeOutCubic.transform(t);
        return Transform.scale(scale: escala, child: child);
      },
      child: ponto,
    );
  }
}

/// A etiqueta `● NO AR · 96,1` do cabeçalho.
class EtiquetaNoAr extends StatelessWidget {
  final RitmoPulso ritmo;
  final String frequencia;
  const EtiquetaNoAr({super.key, this.ritmo = RitmoPulso.noAr, this.frequencia = '96,1'});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Pulso(ritmo: ritmo, tamanho: 7),
        const SizedBox(width: 7),
        Text(
          'NO AR · $frequencia',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
            color: BandFMColors.live,
          ),
        ),
      ],
    );
  }
}

/// O equalizador da linha de audiência.
///
/// Quatro barras de 3 px, de 4 a 12 px de altura, 0,9 s alternando, com atrasos
/// de 0, 0,15, 0,3 e 0,45 s. É o detalhe que faz a tela respirar sem pedir atenção.
class Equalizador extends StatefulWidget {
  final Color cor;
  const Equalizador({super.key, this.cor = BandFMColors.orange});

  @override
  State<Equalizador> createState() => _EqualizadorState();
}

class _EqualizadorState extends State<Equalizador> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semAnimacao = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    const atrasos = [0.0, 0.166, 0.333, 0.5];

    return SizedBox(
      width: 18,
      height: 12,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (i) {
            final fase = semAnimacao ? 0.6 : ((_c.value + atrasos[i]) % 1.0);
            final v = semAnimacao ? fase : (fase < .5 ? fase * 2 : (1 - fase) * 2);
            return Container(
              width: 3,
              height: 4 + 8 * Curves.easeInOut.transform(v),
              decoration: BoxDecoration(
                color: widget.cor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
      ),
    );
  }
}
