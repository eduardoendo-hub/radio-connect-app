import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';

/// 03 · O Momento no No Ar.
///
/// A interação assume a área principal. Gradiente laranja, sombra quente, e a
/// hierarquia do capítulo: **contexto → pergunta → opções → tempo**.
///
/// Regras que não se negociam:
///   · **Um Momento por vez**
///   · Resposta em **um único toque**
///   · Nunca bloqueia o player nem exige resposta — é convite, não obrigação
///   · Todo toque tem retorno imediato; nunca deixar o dedo sem resposta
class CartaoMomento extends StatefulWidget {
  final Map<String, dynamic> momento;
  final VoidCallback aoResponder;
  const CartaoMomento({super.key, required this.momento, required this.aoResponder});

  @override
  State<CartaoMomento> createState() => _CartaoMomentoState();
}

class _CartaoMomentoState extends State<CartaoMomento> {
  String? _escolhida;
  bool _enviando = false;
  Map<String, dynamic>? _resultado;
  String? _mensagem;
  String? _erro;
  Timer? _relogio;
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _conferirSeJaRespondi();
  }

  @override
  void didUpdateWidget(CartaoMomento anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.momento['id'] != widget.momento['id']) {
      setState(() { _resultado = null; _mensagem = null; _erro = null; _escolhida = null; });
      _conferirSeJaRespondi();
    }
  }

  /// O Estado No Ar é igual para toda a emissora — por isso é cacheável e por isso
  /// não sabe o que **esta** pessoa respondeu. Sem esta conferência, quem votou e
  /// depois voltou à tela era convidado a votar de novo, e só descobria pelo erro do
  /// servidor. Uma requisição, quando o cartão abre.
  Future<void> _conferirSeJaRespondi() async {
    final id = widget.momento['id']?.toString();
    if (id == null) return;
    try {
      final r = await Api.obter('/momentos/$id/resultado');
      if (!mounted || r['respondi'] != true) return;
      setState(() {
        _escolhida = r['minhaOpcaoId']?.toString();
        _resultado = r;
      });
    } catch (_) {
      // Falhar aqui só significa mostrar o convite: o servidor recusa o voto repetido
      // de qualquer forma, e a mensagem é clara.
    }
  }

  void _tick() {
    final fim = DateTime.tryParse(widget.momento['terminaEm']?.toString() ?? '');
    if (fim == null) return;
    final d = fim.difference(DateTime.now());
    if (mounted) setState(() => _restante = d.isNegative ? Duration.zero : d);
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _responder(String? opcaoId) async {
    if (_enviando || _resultado != null) return;
    // Retorno imediato: a opção acende antes mesmo da resposta do servidor.
    setState(() { _escolhida = opcaoId; _enviando = true; _erro = null; });
    try {
      final r = await Api.enviar('/momentos/${widget.momento['id']}/responder', {
        if (opcaoId != null) 'opcaoId': opcaoId,
        // Em rede ruim o app reenvia sem saber se a primeira chegou. A chave garante
        // que reenviar não vira voto duplicado.
        'chaveIdempotencia': '${widget.momento['id']}-${DateTime.now().millisecondsSinceEpoch}',
      });
      setState(() {
        _resultado = r['resultado'] as Map<String, dynamic>?;
        _mensagem = r['mensagem']?.toString();
      });
      widget.aoResponder();
    } on ErroApi catch (e) {
      setState(() { _erro = e.mensagem; _escolhida = null; });
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultado != null) {
      return _Resultado(resultado: _resultado!, mensagem: _mensagem, minhaOpcaoId: _escolhida);
    }

    final m = widget.momento;
    final opcoes = (m['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final contexto = m['contexto']?.toString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: BandFMColors.momentGradient,
        borderRadius: BorderRadius.circular(BandFMRadii.hero),
        // Uma borda clara de um pixel: a aresta que pega a luz. É o que separa um
        // objeto de um retângulo pintado.
        border: Border.all(color: const Color(0x2EFFFFFF)),
        boxShadow: [
          // Duas sombras, como qualquer objeto real: o contato escuro logo abaixo…
          const BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 22,
            offset: Offset(0, 9),
            spreadRadius: -9,
          ),
          // …e o brilho da própria cor espalhado bem mais longe.
          BoxShadow(
            color: BandFMColors.orange.withValues(alpha: .42),
            blurRadius: 52,
            offset: const Offset(0, 22),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Stack(children: [
        // A luz vem de cima: um véu branco que morre no meio da altura.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BandFMRadii.hero),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x24FFFFFF), Color(0x00FFFFFF)],
                  stops: [0, .45],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Contexto: quem está perguntando. Sem isso o Momento vira formulário.
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .28),
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.mic, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                contexto ?? 'A rádio quer saber',
                style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: Color(0xE6FFFFFF), letterSpacing: -.1,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          Text(
            m['titulo']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 25, fontWeight: FontWeight.w800, height: 1.15,
              letterSpacing: -.5, color: Colors.white,
            ),
          ),
          if (m['texto'] != null) ...[
            const SizedBox(height: 8),
            Text(m['texto'].toString(),
                style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF), height: 1.4)),
          ],

          if (opcoes.isNotEmpty) ...[
            const SizedBox(height: 18),
            // A reação é horizontal e compacta. Um "Amei / Gostei / Passa" empilhado
            // em três blocões vira formulário: pede leitura, decisão e rolagem para
            // uma resposta que devia custar meio segundo.
            //
            // Rótulo de música é outro caso — não cabe em pílula. Aí cada opção ocupa
            // a linha inteira, com o emoji ao lado do texto, nunca acima.
            if (_cabeEmPilula(opcoes))
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: opcoes.map((o) => _pilula(o)).toList(),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: opcoes
                    .map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _linhaLarga(o),
                        ))
                    .toList(),
              ),
          ],

          if (_erro != null) ...[
            const SizedBox(height: 12),
            Text(_erro!, style: const TextStyle(fontSize: 13, color: Colors.white)),
          ],

          const SizedBox(height: 16),
          Row(children: [
            const Icon(Symbols.timer, size: 15, color: Color(0xB3FFFFFF)),
            const SizedBox(width: 6),
            Text(
              _restante.inSeconds > 0
                  ? 'Restam ${_restante.inMinutes}min ${(_restante.inSeconds % 60).toString().padLeft(2, '0')}s'
                  : 'Encerrando…',
              style: const TextStyle(fontSize: 12.5, color: Color(0xB3FFFFFF), fontWeight: FontWeight.w600),
            ),
          ]),
            ],
          ),
        ),
      ]),
    );
  }

  /// Reação cabe em pílula; nome de música não. O corte é o tamanho do rótulo mais
  /// longo — 14 caracteres é o que atravessa a tela em duas ou três pílulas sem
  /// quebrar em telas de 360 px, que é o Android que a gente precisa atender.
  bool _cabeEmPilula(List<Map<String, dynamic>> opcoes) {
    if (opcoes.length > 4) return false;
    return opcoes.every((o) => (o['rotulo']?.toString() ?? '').length <= 14);
  }

  /// Pílula: emoji e texto lado a lado, altura de um toque, largura do conteúdo.
  Widget _pilula(Map<String, dynamic> o) {
    final id = o['id']?.toString();
    final aceso = _escolhida == id;
    final emoji = o['emoji']?.toString() ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _enviando ? null : () => _responder(id),
        borderRadius: BorderRadius.circular(BandFMRadii.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: BandFMSpacing.minTouchTarget),
          padding: EdgeInsets.fromLTRB(emoji.isEmpty ? 16 : 12, 10, 16, 10),
          decoration: BoxDecoration(
            color: aceso ? Colors.white.withValues(alpha: .24) : Colors.black.withValues(alpha: .24),
            borderRadius: BorderRadius.circular(BandFMRadii.pill),
            border: Border.all(
              color: aceso ? Colors.white : const Color(0x1FFFFFFF),
              width: aceso ? 1.5 : 1,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
            ],
            // O rótulo textual anda sempre junto do emoji: emoji sozinho não é lido
            // por leitor de tela.
            Text(
              o['rotulo']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.1,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// Linha larga: para rótulo comprido, como nome de música com artista.
  Widget _linhaLarga(Map<String, dynamic> o) {
    final id = o['id']?.toString();
    final aceso = _escolhida == id;
    final emoji = o['emoji']?.toString() ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _enviando ? null : () => _responder(id),
        borderRadius: BorderRadius.circular(BandFMRadii.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: BandFMSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: aceso ? Colors.white.withValues(alpha: .24) : Colors.black.withValues(alpha: .24),
            borderRadius: BorderRadius.circular(BandFMRadii.lg),
            border: Border.all(
              color: aceso ? Colors.white : const Color(0x1FFFFFFF),
              width: aceso ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                o['rotulo']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 04 · O resultado.
///
/// Sem fechamento a participação parece vazia. Confirmação + resultado coletivo:
/// o ouvinte vê que outras pessoas viveram aquilo junto com ele.
class _Resultado extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final String? mensagem;
  /// Qual opção foi a desta pessoa. O resultado coletivo sem a marca do próprio voto
  /// é notícia; com ela, é a memória de ter participado.
  final String? minhaOpcaoId;
  const _Resultado({required this.resultado, this.mensagem, this.minhaOpcaoId});

  @override
  Widget build(BuildContext context) {
    final opcoes = (resultado['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final total = (resultado['total'] as num?)?.toInt() ?? 0;
    final ordenadas = [...opcoes]..sort((a, b) => (b['votos'] as num).compareTo(a['votos'] as num));

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BandFMSpacing.x4),
          decoration: BoxDecoration(
            color: BandFMColors.surface,
            borderRadius: BorderRadius.circular(BandFMRadii.card),
            border: Border.all(color: BandFMColors.green.withValues(alpha: .45)),
          ),
          child: Row(children: [
            const Icon(Symbols.check_circle, fill: 1, color: BandFMColors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(mensagem ?? 'Seu voto foi registrado',
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                const Text('Sua conexão com a Band FM ficou mais forte',
                    style: TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: BandFMSpacing.x3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BandFMSpacing.x4),
          decoration: BoxDecoration(
            color: BandFMColors.surface,
            borderRadius: BorderRadius.circular(BandFMRadii.card),
            border: Border.all(color: BandFMColors.line),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ...ordenadas.asMap().entries.map((e) {
              final o = e.value;
              final pct = (o['percentual'] as num?)?.toInt() ?? 0;
              final vencedora = e.key == 0 && total > 0;
              final minha = minhaOpcaoId != null && o['id']?.toString() == minhaOpcaoId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        '${o['emoji'] ?? ''} ${o['rotulo']}'.trim(),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: vencedora || minha ? FontWeight.w700 : FontWeight.w500,
                          color: vencedora || minha
                              ? BandFMColors.textPrimary
                              : BandFMColors.textSecondary,
                        ),
                      ),
                    ),
                    if (minha) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: BandFMColors.orange.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(BandFMRadii.pill),
                        ),
                        child: const Text('seu voto',
                            style: TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w700,
                                color: BandFMColors.orange)),
                      ),
                    ],
                    Text('$pct%',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: vencedora ? BandFMColors.orange : BandFMColors.textTertiary,
                        )),
                  ]),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct / 100),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Stack(children: [
                        Container(height: 10, color: BandFMColors.surfaceRaised),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: vencedora
                                  ? const LinearGradient(colors: [Color(0xFFF6821F), Color(0xFFFFB05C)])
                                  : null,
                              color: vencedora ? null : BandFMColors.surfaceRaised,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
              );
            }),
            Text('$total ${total == 1 ? 'pessoa participou' : 'pessoas participaram'}',
                style: const TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
          ]),
        ),
      ],
    );
  }
}
