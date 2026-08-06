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
  }

  @override
  void didUpdateWidget(CartaoMomento anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.momento['id'] != widget.momento['id']) {
      setState(() { _resultado = null; _mensagem = null; _erro = null; _escolhida = null; });
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
    if (_resultado != null) return _Resultado(resultado: _resultado!, mensagem: _mensagem);

    final m = widget.momento;
    final opcoes = (m['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final contexto = m['contexto']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: BandFMColors.momentGradient,
        borderRadius: BorderRadius.circular(BandFMRadii.hero),
        boxShadow: [
          BoxShadow(
            color: BandFMColors.orange.withValues(alpha: .5),
            blurRadius: 44,
            offset: const Offset(0, 18),
            spreadRadius: -14,
          ),
        ],
      ),
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
            // Lado a lado quando são duas: a escolha cabe num olhar e num toque.
            if (opcoes.length == 2)
              Row(children: [
                Expanded(child: _opcao(opcoes[0])),
                const SizedBox(width: 10),
                Expanded(child: _opcao(opcoes[1])),
              ])
            else
              Column(
                children: opcoes
                    .map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _opcao(o),
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
    );
  }

  Widget _opcao(Map<String, dynamic> o) {
    final id = o['id']?.toString();
    final aceso = _escolhida == id;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _enviando ? null : () => _responder(id),
        borderRadius: BorderRadius.circular(BandFMRadii.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: BandFMSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: aceso ? Colors.white.withValues(alpha: .22) : Colors.black.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(BandFMRadii.lg),
            border: Border.all(
              color: aceso ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (o['emoji'] != null && o['emoji'].toString().isNotEmpty) ...[
                Text(o['emoji'].toString(), style: const TextStyle(fontSize: 19)),
                const SizedBox(height: 6),
              ],
              Text(
                o['rotulo']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white, height: 1.25,
                ),
              ),
            ],
          ),
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
  const _Resultado({required this.resultado, this.mensagem});

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
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        '${o['emoji'] ?? ''} ${o['rotulo']}'.trim(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: vencedora ? FontWeight.w700 : FontWeight.w500,
                          color: vencedora ? BandFMColors.textPrimary : BandFMColors.textSecondary,
                        ),
                      ),
                    ),
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
