import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../tema.dart';

/// O Momento na tela do ouvinte.
///
/// Regra do MVP: **toda interação se resolve com um único toque**. A pessoa pode estar
/// dirigindo, cozinhando ou com o celular numa mão só — não pode precisar ler muito,
/// preencher campo nem navegar por telas.
///
/// E é um convite, nunca uma obrigação: dá para ignorar e continuar ouvindo.
class CartaoMomento extends StatefulWidget {
  final Map<String, dynamic> momento;
  final VoidCallback aoResponder;
  const CartaoMomento({super.key, required this.momento, required this.aoResponder});

  @override
  State<CartaoMomento> createState() => _CartaoMomentoState();
}

class _CartaoMomentoState extends State<CartaoMomento> {
  bool _enviando = false;
  Map<String, dynamic>? _resultado;
  String? _mensagem;
  String? _erro;
  Timer? _relogio;
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();
    _atualizarRelogio();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _atualizarRelogio());
  }

  @override
  void didUpdateWidget(CartaoMomento anterior) {
    super.didUpdateWidget(anterior);
    // Momento novo: limpa o resultado do anterior.
    if (anterior.momento['id'] != widget.momento['id']) {
      setState(() {
        _resultado = null;
        _mensagem = null;
        _erro = null;
      });
    }
  }

  void _atualizarRelogio() {
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
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final r = await Api.enviar('/momentos/${widget.momento['id']}/responder', {
        if (opcaoId != null) 'opcaoId': opcaoId,
        // Em rede ruim o app reenvia sem saber se a primeira tentativa chegou.
        // A chave garante que reenviar não vira voto duplicado.
        'chaveIdempotencia': '${widget.momento['id']}-${DateTime.now().millisecondsSinceEpoch}',
      });
      setState(() {
        _resultado = r['resultado'] as Map<String, dynamic>?;
        _mensagem = r['mensagem']?.toString();
      });
      widget.aoResponder();
    } on ErroApi catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.momento;
    final opcoes = (m['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final patrocinado = m['patrocinada'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: Tema.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Tema.laranja.withValues(alpha: .45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Contexto: quem está perguntando e por quê.
              Expanded(
                child: Text(
                  patrocinado ? 'MOMENTO PATROCINADO' : 'AGORA',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                    color: patrocinado ? Tema.texto2 : Tema.laranja,
                  ),
                ),
              ),
              if (_restante.inSeconds > 0 && _resultado == null)
                Text(
                  '${_restante.inMinutes.toString().padLeft(2, '0')}:'
                  '${(_restante.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Tema.texto2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Espaco.sm),

          // A pergunta: o conteúdo principal.
          Text(
            m['titulo']?.toString() ?? '',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25),
          ),
          if (m['texto'] != null) ...[
            const SizedBox(height: 6),
            Text(m['texto'].toString(), style: const TextStyle(color: Tema.texto2, fontSize: 14)),
          ],

          const SizedBox(height: Espaco.md),

          if (_resultado != null)
            _Resultado(resultado: _resultado!, mensagem: _mensagem)
          else if (opcoes.isEmpty)
            // Aviso: nem todo Momento pede interação.
            const SizedBox.shrink()
          else
            ...opcoes.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: Espaco.sm),
                  child: _Opcao(
                    rotulo: o['rotulo']?.toString() ?? '',
                    emoji: o['emoji']?.toString(),
                    habilitado: !_enviando,
                    aoTocar: () => _responder(o['id']?.toString()),
                  ),
                )),

          if (_erro != null) ...[
            const SizedBox(height: Espaco.sm),
            Text(_erro!, style: const TextStyle(color: Color(0xFFFF9A95), fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  final String rotulo;
  final String? emoji;
  final bool habilitado;
  final VoidCallback aoTocar;
  const _Opcao({required this.rotulo, this.emoji, required this.habilitado, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: habilitado ? aoTocar : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          // Alvo de toque generoso: a pessoa pode estar dirigindo.
          padding: const EdgeInsets.symmetric(horizontal: Espaco.md, vertical: 15),
          decoration: BoxDecoration(
            color: Tema.superficieAlta,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Tema.borda),
          ),
          child: Row(
            children: [
              if (emoji != null && emoji!.isNotEmpty) ...[
                Text(emoji!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: Espaco.sm),
              ],
              Expanded(
                child: Text(rotulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O fechamento.
///
/// Quando a rádio pede participação e não mostra o que aconteceu, a interação parece
/// vazia. Mostrar o resultado coletivo é o que cria reciprocidade — e o que faz o
/// ouvinte perceber que outras pessoas viveram aquilo junto com ele.
class _Resultado extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final String? mensagem;
  const _Resultado({required this.resultado, this.mensagem});

  @override
  Widget build(BuildContext context) {
    final opcoes = (resultado['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final total = (resultado['total'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mensagem != null) ...[
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Tema.laranja),
              const SizedBox(width: 6),
              Text(mensagem!, style: const TextStyle(color: Tema.laranja, fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: Espaco.md),
        ],
        ...opcoes.map((o) {
          final pct = (o['percentual'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: Espaco.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(height: 48, color: Tema.superficieAlta),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    widthFactor: pct / 100,
                    child: Container(height: 48, color: Tema.laranja.withValues(alpha: .28)),
                  ),
                  SizedBox(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
                      child: Row(
                        children: [
                          if (o['emoji'] != null) ...[
                            Text(o['emoji'].toString()),
                            const SizedBox(width: Espaco.sm),
                          ],
                          Expanded(child: Text(o['rotulo']?.toString() ?? '')),
                          Text('$pct%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        Text('$total ${total == 1 ? 'participação' : 'participações'}',
            style: const TextStyle(color: Tema.texto3, fontSize: 12.5)),
      ],
    );
  }
}
