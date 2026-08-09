import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';
import '../tempo.dart';
import 'assinatura_patrocinio.dart';

/// A promoção como bloco principal da tela.
///
/// Era uma linha de lista com o mesmo peso do "A seguir". Promoção é o formato de maior
/// audiência que a rádio tem — o documento do No Ar sempre disse que ela "ocupa a área
/// principal", e a tela é que não cumpria.
///
/// **A foto não vai até a borda de baixo, e isso é decisão e não acaso.** Texto branco
/// sobre foto arbitrária é aposta: a arte que a emissora sobe amanhã pode ser clara,
/// clara no lugar errado, ou ter o rosto do artista exatamente onde ficaria o título. A
/// imagem ocupa o topo e derrete numa base escura; o texto vive na base. Funciona com
/// qualquer arte, inclusive a que ninguém revisou.
///
/// O selo da promoção fica na dobra — a faixa onde a foto já virou preto. É o que
/// permite usar selo com fundo preto, que é como quase toda rádio entrega a arte, sem
/// pedir PNG transparente a ninguém.
class CartaoPromocao extends StatefulWidget {
  final Map<String, dynamic> promocao;

  /// Chamado depois de entrar no sorteio, para a tela recarregar o estado.
  final VoidCallback? aoParticipar;

  const CartaoPromocao({super.key, required this.promocao, this.aoParticipar});

  @override
  State<CartaoPromocao> createState() => _CartaoPromocaoState();
}

class _CartaoPromocaoState extends State<CartaoPromocao> {
  bool _enviando = false;
  bool _participei = false;
  String? _erro;
  int? _total;

  @override
  void initState() {
    super.initState();
    _conferir();
  }

  /// Se esta pessoa já está concorrendo.
  ///
  /// Vem daqui e não do Estado No Ar porque o No Ar é o mesmo para toda a emissora e
  /// fica em cache — participação é de uma pessoa só. Mesma separação dos Momentos.
  Future<void> _conferir() async {
    try {
      final r = await Api.obter('/promocoes/${widget.promocao['id']}');
      if (!mounted) return;
      setState(() {
        _participei = r['participei'] == true;
        _total = (r['promocao']?['total'] as num?)?.toInt();
      });
    } catch (_) {
      // Sem resposta o cartão continua convidando. Errar para o lado do convite é
      // melhor que esconder a promoção de quem ainda não se inscreveu.
    }
  }

  Future<void> _participar() async {
    if (_enviando) return;
    setState(() { _enviando = true; _erro = null; });
    try {
      final r = await Api.enviar('/promocoes/${widget.promocao['id']}/participar', {});
      if (!mounted) return;
      setState(() {
        _participei = r['participei'] == true;
        _total = (r['total'] as num?)?.toInt();
      });
      widget.aoParticipar?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ErroApi ? e.mensagem : 'Não deu para inscrever agora.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.promocao;
    final imagem = p['imagemUrl']?.toString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BandFMColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (imagem != null && imagem.isNotEmpty) _arte(imagem),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                p['titulo']?.toString() ?? '',
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800, height: 1.18,
                    letterSpacing: -.4, color: Colors.white),
              ),
              if (p['descricao'] != null) ...[
                const SizedBox(height: 6),
                Text(p['descricao'].toString(),
                    style: const TextStyle(
                        fontSize: 13.5, color: BandFMColors.textSecondary, height: 1.4)),
              ],
              const SizedBox(height: 14),
              _acao(),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, style: const TextStyle(fontSize: 13, color: Color(0xFFFF9A95))),
              ],
              if (AssinaturaPatrocinio.talvez(p['patrocinio']) != null) ...[
                const SizedBox(height: 14),
                AssinaturaPatrocinio.talvez(p['patrocinio'])!,
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  /// A foto, com o rótulo em cima e a dobra escura embaixo.
  Widget _arte(String url) => Stack(children: [
        // 16:9 **com teto**.
        //
        // Só a proporção não basta: numa janela larga — o navegador do desktop na
        // demonstração, um tablet — a foto cresce junto com a largura e empurra o
        // título e o botão para fora da tela. A pessoa vê um pôster enorme e nenhuma
        // chamada. Acima do teto a imagem corta em vez de crescer, que é o que um
        // pôster faz quando a parede é maior.
        LayoutBuilder(
          builder: (contexto, limites) => SizedBox(
            height: math.min(limites.maxWidth * 9 / 16, 230),
            width: double.infinity,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              // Enquanto a foto não chega, a superfície do cartão ocupa o lugar dela.
              // Um buraco branco piscando no meio da tela escura é pior que esperar.
              loadingBuilder: (c, filho, progresso) =>
                  progresso == null ? filho : Container(color: BandFMColors.surface),
              errorBuilder: (_, __, ___) => Container(color: BandFMColors.surface),
            ),
          ),
        ),
        // A dobra: do transparente até a cor exata da superfície do cartão, para não
        // existir linha entre a foto e o texto.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  BandFMColors.surface.withValues(alpha: .55),
                  BandFMColors.surface,
                ],
                stops: const [0.45, 0.82, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16, top: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(BandFMRadii.pill),
            ),
            child: const Text('PROMOÇÃO NO AR',
                style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w800,
                    letterSpacing: 1.2, color: Colors.white)),
          ),
        ),
      ]);

  Widget _acao() {
    if (_participei) return _concorrendo();

    return Row(children: [
      Expanded(
        child: FilledButton(
          onPressed: _enviando ? null : _participar,
          style: FilledButton.styleFrom(
            backgroundColor: BandFMColors.orange,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(BandFMSpacing.minTouchTarget),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BandFMRadii.pill)),
          ),
          child: Text(_enviando ? 'Inscrevendo…' : 'Quero participar',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    ]);
  }

  /// Depois de inscrito o cartão **não some — muda de estado**.
  ///
  /// Sumir seria apagar o que a pessoa acabou de fazer, e é justamente aqui que mora o
  /// retorno: a inscrição dura um toque, mas "quinta, 15h, ao vivo" é o que faz ela
  /// voltar com o rádio ligado. É a mesma reciprocidade do Momento respondido.
  Widget _concorrendo() {
    final sorteio = instante(widget.promocao['sorteioEm']);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BandFMColors.orange.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(BandFMRadii.md),
        border: Border.all(color: BandFMColors.orange.withValues(alpha: .3)),
      ),
      child: Row(children: [
        const Icon(Symbols.check_circle, size: 19, fill: 1, color: BandFMColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Você está concorrendo',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text(
              sorteio != null
                  ? 'Sorteio ${quando(sorteio)} — ao vivo, com o locutor.'
                  : 'O resultado sai ao vivo, com o locutor.',
              style: const TextStyle(fontSize: 12, color: BandFMColors.textSecondary),
            ),
          ]),
        ),
        if (_total != null && _total! > 1)
          Text('${_total!}',
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: BandFMColors.textTertiary)),
      ]),
    );
  }
}
