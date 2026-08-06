import 'package:flutter/material.dart';
import '../tema.dart';

/// Peças que se repetem em várias telas. Ficam juntas para o design system ter um
/// lugar só — trocar o raio de um cartão não pode virar caça ao tesouro.

/// Cartão padrão: superfície `#181818`, raio 18, linha de 1 px quase invisível.
class Cartao extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? aoTocar;
  final Color? fundo;
  final BoxBorder? borda;
  final double raio;

  const Cartao({
    super.key,
    required this.child,
    this.padding,
    this.aoTocar,
    this.fundo,
    this.borda,
    this.raio = BandFMRadii.card,
  });

  @override
  Widget build(BuildContext context) {
    final corpo = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(BandFMSpacing.x4),
      decoration: BoxDecoration(
        color: fundo ?? BandFMColors.surface,
        borderRadius: BorderRadius.circular(raio),
        border: borda ?? Border.all(color: BandFMColors.line),
      ),
      child: child,
    );
    if (aoTocar == null) return corpo;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(raio),
        child: corpo,
      ),
    );
  }
}

/// Linha de cartão com ícone quadrado à esquerda — usada em Momentos, promoções
/// e no "tocando agora".
class LinhaCartao extends StatelessWidget {
  final Widget icone;
  final String titulo;
  final String? apoio;
  final Widget? aDireita;
  final VoidCallback? aoTocar;
  final double opacidade;

  const LinhaCartao({
    super.key,
    required this.icone,
    required this.titulo,
    this.apoio,
    this.aDireita,
    this.aoTocar,
    this.opacidade = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacidade,
      child: Cartao(
        aoTocar: aoTocar,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            icone,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -.15)),
                  if (apoio != null) ...[
                    const SizedBox(height: 3),
                    Text(apoio!,
                        style: const TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary, height: 1.3)),
                  ],
                ],
              ),
            ),
            if (aDireita != null) ...[const SizedBox(width: 8), aDireita!],
          ],
        ),
      ),
    );
  }
}

/// Quadrado de arte 44×44 ou 56×56, raio 10.
class Arte extends StatelessWidget {
  final IconData icone;
  final double tamanho;
  final Gradient? gradiente;
  final Color? cor;
  const Arte({super.key, required this.icone, this.tamanho = 44, this.gradiente, this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        gradient: gradiente,
        color: gradiente == null ? (cor ?? BandFMColors.surfaceRaised) : null,
        borderRadius: BorderRadius.circular(BandFMRadii.art),
      ),
      child: Icon(icone, size: tamanho * .45, color: Colors.white),
    );
  }
}

/// Rótulo de seção em maiúsculas — `TOCANDO AGORA`, `PROMOÇÃO NO AR`.
class RotuloSecao extends StatelessWidget {
  final String texto;
  final Color cor;
  const RotuloSecao(this.texto, {super.key, this.cor = BandFMColors.orange});

  @override
  Widget build(BuildContext context) => Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.32,
          color: cor,
        ),
      );
}

/// Título de bloco dentro da tela — "Antes, hoje", "Suas promoções".
class TituloBloco extends StatelessWidget {
  final String texto;
  const TituloBloco(this.texto, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(texto,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.3)),
      );
}
