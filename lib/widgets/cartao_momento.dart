import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../estado_respostas.dart';
import '../tema.dart';
import 'assinatura_patrocinio.dart';
import 'identidade_quadro.dart';
import 'pulso.dart';

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
    // A resposta pode ter saído da faixa, em outra aba. Esta tela fica montada o app
    // inteiro e não recarregaria sozinha — o registro avisa.
    RegistroDeRespostas.instancia.addListener(_registroMudou);
    _conferirSeJaRespondi();
  }

  void _registroMudou() {
    final id = widget.momento['id']?.toString();
    if (_resultado != null || !RegistroDeRespostas.instancia.respondeu(id)) return;
    // Já respondeu em outro lugar: busca o resultado para fechar o ciclo aqui também.
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
      RegistroDeRespostas.instancia.marcarVindoDoServidor(id, r['minhaOpcaoId']?.toString());
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
    RegistroDeRespostas.instancia.removeListener(_registroMudou);
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
      RegistroDeRespostas.instancia.marcar(widget.momento['id'].toString(), opcaoId);
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

    // A identidade do quadro, quando ele tem uma. A maioria não tem — e é por isso que
    // os poucos que têm são reconhecidos de longe.
    final quadro = IdentidadeQuadro.de(m['identidade']);
    final destaque = quadro?.cor ?? BandFMColors.orange;

    final fim = DateTime.tryParse(m['terminaEm']?.toString() ?? '');
    final inicio = DateTime.tryParse(m['inicioEm']?.toString() ?? '');
    // Fração do tempo já consumida, para a barra. Sem `inicioEm` a duração padrão de
    // três minutos é boa o suficiente — a barra é orientação, não cronômetro oficial.
    final duracao = (fim != null && inicio != null)
        ? fim.difference(inicio)
        : const Duration(minutes: 3);
    final decorrido = duracao.inMilliseconds <= 0
        ? 1.0
        : 1 - (_restante.inMilliseconds / duracao.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Superfície escura sólida, sem borda colorida e sem gradiente.
        //
        // O bloco laranja inteiro pesava: a cor da marca ocupando um terço da tela
        // vira parede, e as opções em cima dela ficavam num marrom sujo. A tentativa
        // seguinte — fundo escuro com borda laranja — resolveu o contraste mas trouxe
        // outro problema: moldura colorida em volta de conteúdo é linguagem de
        // 2015. Spotify e TikTok não desenham molduras; separam por elevação e deixam
        // a tipografia mandar.
        //
        // Aqui o Momento é dono da tela pelo tamanho da pergunta e pelo espaço em
        // volta dela. O laranja fica onde rende: o rótulo, a opção escolhida e a barra
        // do tempo. Três toques, não uma parede.
        color: BandFMColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24, offset: Offset(0, 10), spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contexto e tempo na mesma linha: quem pergunta à esquerda, quanto
                // resta à direita. O ícone de microfone dentro de um círculo escuro
                // parecia um botão que não fazia nada — virou o pulso, que é estado.
                Row(children: [
                  // Quadro com identidade mostra o próprio ícone; o resto mostra o
                  // pulso. O ícone é o que a pessoa aprende a reconhecer antes de ler.
                  if (quadro?.icone != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Icon(quadro!.icone, size: 15, fill: 1, color: destaque),
                    )
                  else ...[
                    const Pulso(tamanho: 7, ritmo: RitmoPulso.momentoAtivo),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      (contexto ?? 'A rádio quer saber').toUpperCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        letterSpacing: 1.3, color: destaque,
                      ),
                    ),
                  ),
                  Text(
                    _restante.inSeconds > 0
                        ? '${_restante.inMinutes}:${(_restante.inSeconds % 60).toString().padLeft(2, '0')}'
                        : 'encerrando',
                    style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                      color: BandFMColors.textTertiary, fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                Text(
                  m['titulo']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 23, fontWeight: FontWeight.w800, height: 1.18,
                    letterSpacing: -.5, color: Colors.white,
                  ),
                ),
                if (m['texto'] != null) ...[
                  const SizedBox(height: 7),
                  Text(m['texto'].toString(),
                      style: const TextStyle(
                          fontSize: 13.5, color: BandFMColors.textSecondary, height: 1.4)),
                ],

                if (opcoes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  // A reação é horizontal e compacta. Um "Amei / Gostei / Passa"
                  // empilhado em três blocões vira formulário: pede leitura, decisão e
                  // rolagem para uma resposta que devia custar meio segundo.
                  //
                  // Rótulo de música é outro caso — não cabe em pílula. Aí cada opção
                  // ocupa a linha inteira, com o emoji ao lado do texto, nunca acima.
                  if (_cabeEmPilula(opcoes))
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: opcoes.map((o) => _pilula(o)).toList(),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: opcoes
                          .map((o) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _linhaLarga(o),
                              ))
                          .toList(),
                    ),
                ],

                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_erro!,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFFF9A95))),
                ],

                // Qualquer Momento pode ser patrocinado, não só o Fofocômetro. A
                // assinatura fica no rodapé do cartão — abaixo da resposta, porque
                // quem paga assina o Momento, não substitui a pergunta.
                if (AssinaturaPatrocinio.talvez(m['patrocinio']) != null) ...[
                  const SizedBox(height: 16),
                  AssinaturaPatrocinio.talvez(m['patrocinio'])!,
                ],
              ],
            ),
          ),

          // O tempo como barra, e não como "Restam 9min 37s" com ícone de cronômetro.
          // Some do caminho e se lê de relance — que é tudo o que a informação precisa.
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(19),
            ),
            child: Stack(children: [
              Container(height: 3, color: Colors.white.withValues(alpha: .08)),
              FractionallySizedBox(
                widthFactor: (1 - decorrido).clamp(0.0, 1.0),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [destaque, destaque.withValues(alpha: .55)],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
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
          // Sobre a superfície escura, a opção acende em laranja quando escolhida e
          // repousa num branco baixíssimo quando não. Antes era marrom sobre laranja:
          // duas cores quentes brigando, e nenhuma das duas legível.
          // Sem contorno em repouso: chip é superfície, não moldura. Ao escolher, o
          // laranja preenche e o texto fica preto — o mesmo contraste do botão de play.
          //
          // Contraste em duas frentes, e não só subindo o preenchimento.
          //
          // Passou de 9% para 14% e ainda lia baixo no aparelho — captura de tela mente
          // sobre contraste, o julgamento vale é no vidro. Em vez de empurrar o branco
          // para 25%, o que faria o chip virar um segundo cartão dentro do primeiro, o
          // preenchimento vai a 20% e ganha um contorno claro. A borda define a forma
          // sem somar peso à mancha — dá aresta em vez de volume.
          //
          // Ao escolher, o laranja entra translúcido com o contorno aceso — e não
          // chapado. Laranja sólido num chip pequeno vira um bloco de tinta que salta
          // fora de escala do resto da tela; a mesma cor a 18% com borda diz "foi esta"
          // com a mesma clareza, e continua parecendo parte do cartão.
          decoration: BoxDecoration(
            color: aceso
                ? BandFMColors.orange.withValues(alpha: .2)
                : Colors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(BandFMRadii.pill),
            border: Border.all(
              color: aceso
                  ? BandFMColors.orange.withValues(alpha: .9)
                  : Colors.white.withValues(alpha: .22),
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
                fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.1,
                color: Colors.white,
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
            color: aceso
                ? BandFMColors.orange.withValues(alpha: .2)
                : Colors.white.withValues(alpha: .2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: aceso
                  ? BandFMColors.orange.withValues(alpha: .9)
                  : Colors.white.withValues(alpha: .22),
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
                  fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.25,
                  color: Colors.white,
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
