import 'package:flutter/material.dart';
import '../tema.dart';

/// O pulso.
///
/// Um elemento discreto que comunica vida. O objetivo não é criar ansiedade nem fazer a
/// tela piscar o tempo todo — é passar a sensação de que a experiência está respirando.
///
/// Discreto, elegante, contínuo. A intensidade é configurável por emissora: uma rádio
/// jovem pode ter mais movimento, uma jornalística um pulso mais sóbrio.
class Pulso extends StatefulWidget {
  final double tamanho;
  final Color cor;
  const Pulso({super.key, this.tamanho = 8, this.cor = Tema.aoVivo});

  @override
  State<Pulso> createState() => _PulsoState();
}

class _PulsoState extends State<Pulso> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_c.value);
        return SizedBox(
          width: widget.tamanho * 3,
          height: widget.tamanho * 3,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.tamanho + (widget.tamanho * 2 * t),
                height: widget.tamanho + (widget.tamanho * 2 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.cor.withValues(alpha: 0.35 * (1 - t)),
                ),
              ),
              Container(
                width: widget.tamanho,
                height: widget.tamanho,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.cor),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A etiqueta "NO AR" — presença imediata, primeiro nível da hierarquia do No Ar.
class EtiquetaNoAr extends StatelessWidget {
  const EtiquetaNoAr({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: Tema.aoVivo.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Tema.aoVivo.withValues(alpha: .35)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pulso(tamanho: 6),
          Text(
            'NO AR',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF8A84),
            ),
          ),
        ],
      ),
    );
  }
}
