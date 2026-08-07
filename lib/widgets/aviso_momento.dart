import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../estado_no_ar.dart';
import '../tema.dart';

/// O Momento se anuncia, em qualquer aba.
///
/// **Por que não é um pop-up.**
///
/// A tentação é abrir um modal: garante que a pessoa viu. Mas o capítulo do produto é
/// explícito — o Momento *nunca bloqueia o player nem exige resposta; é convite, não
/// obrigação*. Um modal faz o oposto das três coisas: cobre a tela, precisa ser
/// dispensado, e transforma participação em interrupção.
///
/// Tem custo concreto, não só filosófico:
///   · quem está escrevendo no chat perde o teclado e às vezes o texto;
///   · quem está lendo o resultado de outro Momento é arrancado dali;
///   · um modal que aparece sozinho, várias vezes por hora, ensina a pessoa a fechar
///     sem ler — e aí o Momento seguinte já nasce ignorado.
///
/// A faixa resolve o mesmo problema sem nenhum desses efeitos: entra deslizando por
/// cima do mini-player, fica visível de qualquer aba, e **permite responder ali mesmo**
/// quando as opções são curtas. Some sozinha quando a pessoa responde ou quando o
/// Momento encerra — sem pedir um toque só para desaparecer.
///
/// Na tela No Ar ela não aparece: lá o Momento já é o assunto principal, e anunciar o
/// que está bem na frente da pessoa é ruído.
class AvisoMomento extends StatefulWidget {
  final EstadoNoAr estado;

  /// Levar para a aba Momentos quando a pessoa toca no texto.
  final VoidCallback aoAbrir;

  const AvisoMomento({super.key, required this.estado, required this.aoAbrir});

  @override
  State<AvisoMomento> createState() => _AvisoMomentoState();
}

class _AvisoMomentoState extends State<AvisoMomento> {
  /// Momentos que esta pessoa já respondeu ou dispensou nesta sessão. Guardado aqui,
  /// e não no servidor, porque é estado de tela: reabrir o app e ver de novo um
  /// Momento que ainda está no ar é o comportamento certo.
  final _resolvidos = <String>{};
  String? _enviando;
  String? _confirmado;

  Future<void> _responder(String momentoId, String? opcaoId) async {
    setState(() => _enviando = opcaoId);
    try {
      await Api.enviar('/momentos/$momentoId/responder', {
        if (opcaoId != null) 'opcaoId': opcaoId,
        'chaveIdempotencia': '$momentoId-${DateTime.now().millisecondsSinceEpoch}',
      });
      if (!mounted) return;
      // Confirma antes de sumir. Responder e a faixa evaporar no mesmo instante deixa
      // a dúvida de se o toque valeu.
      setState(() => _confirmado = momentoId);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        setState(() {
          _resolvidos.add(momentoId);
          _confirmado = null;
        });
      }
      widget.estado.atualizar();
    } catch (e) {
      if (mounted) {
        final msg = e is ErroApi ? e.mensagem : 'Não deu para registrar agora.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: BandFMColors.surfaceRaised),
        );
        // Voto duplicado também é resolução: a pessoa já participou, a faixa sai.
        if (e is ErroApi && e.status == 409) {
          setState(() => _resolvidos.add(momentoId));
        }
      }
    } finally {
      if (mounted) setState(() => _enviando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.estado,
      builder: (context, _) {
        final m = widget.estado.momento;
        final id = m?['id']?.toString();
        final visivel = m != null && id != null && !_resolvidos.contains(id);

        return AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomCenter,
          child: visivel
              ? _faixa(m, id, confirmado: _confirmado == id)
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }

  Widget _faixa(Map<String, dynamic> m, String id, {required bool confirmado}) {
    final opcoes = (m['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    // Só cabe responder na faixa quando as opções são poucas e curtas. Nome de música
    // não cabe num chip de 40 px — nesse caso a faixa convida e a aba Momentos resolve.
    final respondeAqui = opcoes.isNotEmpty &&
        opcoes.length <= 3 &&
        opcoes.every((o) => (o['rotulo']?.toString() ?? '').length <= 12);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      decoration: BoxDecoration(
        gradient: BandFMColors.momentGradient,
        borderRadius: BorderRadius.circular(BandFMRadii.card),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        boxShadow: [
          const BoxShadow(color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 7), spreadRadius: -7),
          BoxShadow(
            color: BandFMColors.orange.withValues(alpha: .35),
            blurRadius: 34, offset: const Offset(0, 12), spreadRadius: -14,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: confirmado
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(children: [
                  Icon(Symbols.check_circle, fill: 1, size: 19, color: Colors.white),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text('Sua resposta entrou.',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ]),
              )
            : Column(mainAxisSize: MainAxisSize.min, children: [
                InkWell(
                  onTap: widget.aoAbrir,
                  borderRadius: BorderRadius.circular(BandFMRadii.card),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 11, 12, respondeAqui ? 8 : 11),
                    child: Row(children: [
                      const _PontoVivo(),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('AGORA NA BAND FM',
                                style: TextStyle(
                                    fontSize: 9.5, fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2, color: Color(0xCCFFFFFF))),
                            const SizedBox(height: 3),
                            Text(m['titulo']?.toString() ?? '',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14.5, fontWeight: FontWeight.w700,
                                    height: 1.25, color: Colors.white)),
                          ],
                        ),
                      ),
                      if (!respondeAqui) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .26),
                            borderRadius: BorderRadius.circular(BandFMRadii.pill),
                          ),
                          child: const Text('Participar',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ],
                    ]),
                  ),
                ),

                // Responder sem sair de onde se está: é o que separa esta faixa de uma
                // notificação. A pessoa não precisa ir a lugar nenhum para participar.
                if (respondeAqui)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                    child: Row(
                      children: opcoes.asMap().entries.map((e) {
                        final o = e.value;
                        final oid = o['id']?.toString();
                        final aceso = _enviando == oid;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: e.key < opcoes.length - 1 ? 7 : 0),
                            child: InkWell(
                              onTap: _enviando != null ? null : () => _responder(id, oid),
                              borderRadius: BorderRadius.circular(BandFMRadii.pill),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 38),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: aceso
                                      ? Colors.white.withValues(alpha: .3)
                                      : Colors.black.withValues(alpha: .26),
                                  borderRadius: BorderRadius.circular(BandFMRadii.pill),
                                  border: Border.all(
                                    color: aceso ? Colors.white : const Color(0x1FFFFFFF),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if ((o['emoji']?.toString() ?? '').isNotEmpty) ...[
                                      Text(o['emoji'].toString(),
                                          style: const TextStyle(fontSize: 15)),
                                      const SizedBox(width: 6),
                                    ],
                                    Flexible(
                                      child: Text(o['rotulo']?.toString() ?? '',
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ]),
      ),
    );
  }
}

/// O ponto que pulsa. Discreto: comunica vida sem pedir atenção.
class _PontoVivo extends StatefulWidget {
  const _PontoVivo();
  @override
  State<_PontoVivo> createState() => _PontoVivoState();
}

class _PontoVivoState extends State<_PontoVivo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .45, end: 1).animate(
          CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        ),
        child: const SizedBox(
          width: 8, height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      );
}
