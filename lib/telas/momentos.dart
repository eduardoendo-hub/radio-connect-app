import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../estado_no_ar.dart';
import '../estado_respostas.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/pulso.dart';
import '../widgets/cartao_fofocometro.dart';

/// 06 · Momentos.
///
/// O Momento ativo e os recentes do dia. **Não é feed infinito** — o que passou vai
/// para analytics, não para a tela. Por isso o corte é o dia, sem paginação para trás.
class TelaMomentos extends StatefulWidget {
  final EstadoNoAr estado;
  const TelaMomentos({super.key, required this.estado});

  @override
  State<TelaMomentos> createState() => _TelaMomentosState();
}

class _TelaMomentosState extends State<TelaMomentos> {
  List<Map<String, dynamic>> _lista = [];
  bool _carregando = true;
  String? _respondendo;
  String? _ultimoAtivo;
  /// Qual Fofocômetro está aberto. Um por vez: dois textos longos abertos ao mesmo
  /// tempo transformam a lista num feed, que é justamente o que ela não é.
  String? _fofocaAberta;
  final _revelacoes = <String, Map<String, dynamic>>{};

  @override
  void initState() {
    super.initState();
    _carregar();
    // As abas vivem dentro de um IndexedStack: esta tela é montada uma vez e fica viva
    // o app inteiro. Sem escutar o No Ar, um Momento publicado pelo produtor só
    // aparecia se a pessoa fechasse e abrisse o app — que é exatamente o oposto do
    // produto. O No Ar já consulta o servidor sozinho; aqui só reagimos à mudança,
    // sem tráfego novo.
    _ultimoAtivo = widget.estado.momento?['id']?.toString();
    widget.estado.addListener(_quandoONoArMuda);
    // O tempo que resta precisa andar na tela. Um segundo, e só quando há algo no ar.
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _lista.any((m) => m['estado'] == 'ATIVO')) setState(() {});
    });
    RegistroDeRespostas.instancia.addListener(_registroMudou);
    // Rede de segurança a cada 30 s: o gatilho principal é a mudança do No Ar, mas
    // votos que chegam, Momentos que encerram e resultados que a produção publica não
    // mudam o Momento ativo — e sem isso a lista ficaria velha na mão de quem só
    // está olhando.
    _recarga = Timer.periodic(const Duration(seconds: 30), (_) => _carregar());
  }

  Timer? _relogio;
  Timer? _recarga;

  void _quandoONoArMuda() {
    final agoraAtivo = widget.estado.momento?['id']?.toString();
    if (agoraAtivo == _ultimoAtivo) return;
    _ultimoAtivo = agoraAtivo;
    _carregar();
  }

  void _registroMudou() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    RegistroDeRespostas.instancia.removeListener(_registroMudou);
    _relogio?.cancel();
    _recarga?.cancel();
    widget.estado.removeListener(_quandoONoArMuda);
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final r = await Api.obter('/momentos');
      if (!mounted) return;
      setState(() {
        _lista = ((r['momentos'] as List?) ?? []).cast<Map<String, dynamic>>();
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _reagir(String momentoId, String? opcaoId) async {
    setState(() => _respondendo = opcaoId);
    try {
      await Api.enviar('/momentos/$momentoId/responder', {
        if (opcaoId != null) 'opcaoId': opcaoId,
        'chaveIdempotencia': '$momentoId-${DateTime.now().millisecondsSinceEpoch}',
      });
      RegistroDeRespostas.instancia.marcar(momentoId, opcaoId);
      await _carregar();
      widget.estado.atualizar();
    } on ErroApi catch (e) {
      if (mounted) {
        // Mensagem em português, sem termo técnico — "Este Momento acabou de terminar."
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.mensagem),
          backgroundColor: BandFMColors.surfaceRaised,
        ));
      }
    } finally {
      if (mounted) setState(() => _respondendo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: BandFMColors.orange));
    }

    final agora = DateTime.now();
    final ativo = _lista.firstWhere(
      (m) => m['estado'] == 'ATIVO' &&
          (DateTime.tryParse(m['fimEm']?.toString() ?? '')?.isAfter(agora) ?? false),
      orElse: () => {},
    );
    final passados = _lista.where((m) => m['id'] != ativo['id']).toList();

    return RefreshIndicator(
      color: BandFMColors.orange,
      backgroundColor: BandFMColors.surface,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            BandFMSpacing.screenPadding, 16, BandFMSpacing.screenPadding, BandFMSpacing.x5),
        children: [
          const Text('Momentos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: BandFMSpacing.x4),

          if (ativo.isNotEmpty)
            // O Fofocômetro ativo aparece com o mesmo cartão do No Ar: o relógio é o
            // produto, e ele não pode virar uma linha de lista enquanto corre.
            (ativo['tipo'] == 'FOFOCOMETRO'
                ? CartaoFofocometro(key: ValueKey(ativo['id']), momento: _paraCartao(ativo))
                : _cartaoAtivo(ativo))
          else
            _semAtivo(),

          if (passados.isNotEmpty) ...[
            const SizedBox(height: BandFMSpacing.x5),
            const TituloBloco('Antes, hoje'),
            ...passados.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: m['tipo'] == 'FOFOCOMETRO'
                      ? _linhaFofoca(m)
                      : _linhaPassado(m),
                )),
          ],
        ],
      ),
    );
  }

  Widget _cartaoAtivo(Map<String, dynamic> m) {
    final opcoes = (m['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final fim = DateTime.tryParse(m['fimEm']?.toString() ?? '');
    final restante = fim == null ? Duration.zero : fim.difference(DateTime.now());
    // O voto pode ter saído daqui, do No Ar ou da faixa em outra aba — para esta tela
    // dá no mesmo. O registro responde na hora; o servidor confirma na próxima carga.
    final idM = m['id']?.toString();
    final minha = RegistroDeRespostas.instancia.opcaoDe(idM) ?? m['minhaOpcaoId']?.toString();
    final jaVotou = minha != null ||
        m['respondi'] == true ||
        RegistroDeRespostas.instancia.respondeu(idM);

    return Cartao(
      borda: Border.all(color: BandFMColors.orange.withValues(alpha: .45)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Pulso(tamanho: 6, ritmo: RitmoPulso.momentoAtivo),
          const SizedBox(width: 7),
          const Text('AGORA',
              style: TextStyle(
                  fontSize: 10.5, fontWeight: FontWeight.w800,
                  letterSpacing: 1.3, color: BandFMColors.orange)),
          const Spacer(),
          if (restante.inSeconds > 0)
            Text('${restante.inMinutes}min ${(restante.inSeconds % 60).toString().padLeft(2, '0')}s',
                style: const TextStyle(fontSize: 12, color: BandFMColors.textTertiary)),
        ]),
        const SizedBox(height: 12),
        Text(m['titulo']?.toString() ?? '',
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -.3)),
        const SizedBox(height: BandFMSpacing.x4),

        // Reações de um toque. **Sempre com rótulo textual junto do emoji** —
        // exigência de acessibilidade: emoji sozinho não é lido por leitor de tela.
        //
        // Depois de votar as opções continuam na tela, mas só a escolhida fica acesa.
        // Trocar tudo por um "obrigado" apagaria o que a pessoa acabou de fazer; ela
        // precisa ver a própria resposta ali, e continuar esperando o resultado junto
        // com todo mundo.
        Row(
          children: opcoes.asMap().entries.map((e) {
            final o = e.value;
            final id = o['id']?.toString();
            final escolhida = jaVotou ? id == minha : _respondendo == id;
            final apagada = jaVotou && !escolhida;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: e.key < opcoes.length - 1 ? 8 : 0),
                child: Opacity(
                  opacity: apagada ? .4 : 1,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: (jaVotou || _respondendo != null)
                          ? null
                          : () => _reagir(m['id'].toString(), id),
                      borderRadius: BorderRadius.circular(BandFMRadii.md),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: BandFMSpacing.minTouchTarget),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        // Mesmo contraste do cartão do No Ar: preenchimento a 20% de
                        // branco e um contorno claro. Superfície sem aresta some no
                        // cartão, por mais clara que seja.
                        decoration: BoxDecoration(
                          color: escolhida
                              ? BandFMColors.orange.withValues(alpha: .2)
                              : Colors.white.withValues(alpha: .2),
                          borderRadius: BorderRadius.circular(BandFMRadii.md),
                          border: Border.all(
                            color: escolhida
                                ? BandFMColors.orange.withValues(alpha: .9)
                                : Colors.white.withValues(alpha: .22),
                          ),
                        ),
                        child: Column(children: [
                          Text(o['emoji']?.toString() ?? '·', style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 5),
                          Text(o['rotulo']?.toString() ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w600,
                                  color: escolhida
                                      ? BandFMColors.orange
                                      : BandFMColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (jaVotou) ...[
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Symbols.check_circle, fill: 1, size: 15, color: BandFMColors.orange),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Você já participou. O resultado sai quando o Momento encerrar.',
                style: const TextStyle(
                    fontSize: 12.5, color: BandFMColors.textSecondary, height: 1.3),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  /// A lista de Momentos e o Estado No Ar falam dialetos diferentes: um manda `fimEm`,
  /// o outro `terminaEm`, e a fofoca vem em `config` num e em `fofoca` no outro. O
  /// cartão só conhece o dialeto do No Ar — traduzir aqui é mais barato do que ensinar
  /// os dois formatos a ele.
  Map<String, dynamic> _paraCartao(Map<String, dynamic> m) => {
        ...m,
        'terminaEm': m['fimEm'],
        'fofoca': m['config'] ?? m['fofoca'],
      };

  /// O Fofocômetro na lista: entra fechado e abre ao toque.
  ///
  /// Fechado por padrão porque a lista existe para varrer o que aconteceu — abrir tudo
  /// de uma vez viraria um mural de texto. Quem quiser ler, toca.
  Widget _linhaFofoca(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    final aberta = _fofocaAberta == id;
    final revelacao = _revelacoes[id];
    final cfg = (m['config'] as Map?)?.cast<String, dynamic>();
    final revelou = DateTime.tryParse(cfg?['revelarEm']?.toString() ?? '')
            ?.isBefore(DateTime.now()) ??
        false;

    return Cartao(
      padding: EdgeInsets.zero,
      aoTocar: !revelou
          ? null
          : () async {
              setState(() => _fofocaAberta = aberta ? null : id);
              if (!aberta && revelacao == null) {
                try {
                  final r = await Api.obter('/momentos/$id/revelacao');
                  if (mounted) {
                    setState(() => _revelacoes[id] =
                        (r['revelacao'] as Map).cast<String, dynamic>());
                  }
                } catch (_) {
                  // Sem revelação não abre nada — melhor do que um vazio sem explicação.
                  if (mounted) setState(() => _fofocaAberta = null);
                }
              }
            },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Ícone maior e na cor do formato: na lista o Fofocômetro precisa se
            // distinguir de longe das enquetes, e a marca dele é a cor mais o tamanho.
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFE8437B), Color(0xFF8E1D46)],
                ),
                borderRadius: BorderRadius.circular(BandFMRadii.md),
              ),
              child: const Icon(Symbols.campaign, fill: 1, size: 27, color: Colors.white),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // O nome do formato ganha caixa própria, com fundo e borda.
                //
                // Solto, ele era só mais uma linha de texto colada no título — os dois
                // liam como um bloco só. Numa etiqueta fechada ele vira selo: a pessoa
                // reconhece o formato antes de ler a frase, que é o ponto.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8437B).withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(BandFMRadii.pill),
                    border: Border.all(color: const Color(0xFFE8437B).withValues(alpha: .38)),
                  ),
                  child: const Text('FOFOCÔMETRO',
                      style: TextStyle(
                          fontSize: 8.5, fontWeight: FontWeight.w800,
                          letterSpacing: 1.2, color: Color(0xFFE8437B))),
                ),
                const SizedBox(height: 7),
                Text(m['titulo']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.3)),
                if (!revelou) ...[
                  const SizedBox(height: 4),
                  const Text('Ainda não abriu',
                      style: TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
                ] else if (!aberta) ...[
                  const SizedBox(height: 4),
                  const Text('Toque para ler',
                      style: TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
                ],
              ]),
            ),
            if (revelou) ...[
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: aberta ? .5 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Icon(Symbols.expand_more, size: 22, color: Color(0xFFE8437B)),
              ),
            ],
          ]),
        ),
        if (aberta && revelacao != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 1, color: BandFMColors.line),
              const SizedBox(height: 12),
              if ((revelacao['imagemUrl']?.toString() ?? '').isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(BandFMRadii.md),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(revelacao['imagemUrl'].toString(), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                  ),
                ),
                const SizedBox(height: 11),
              ],
              Text(revelacao['texto']?.toString() ?? '',
                  style: const TextStyle(fontSize: 14.5, height: 1.5)),
            ]),
          ),
      ]),
    );
  }

  Widget _semAtivo() => Cartao(
        child: Row(children: [
          const Icon(Symbols.how_to_vote, color: BandFMColors.textTertiary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Nenhum Momento agora. Fica ligado que já já tem novidade.',
                style: TextStyle(fontSize: 14, color: BandFMColors.textSecondary, height: 1.35)),
          ),
        ]),
      );

  Widget _linhaPassado(Map<String, dynamic> m) {
    final opcoes = (m['opcoes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final total = opcoes.fold<int>(0, (s, o) => s + ((o['votos'] as num?)?.toInt() ?? 0));
    final vencedora = opcoes.isEmpty
        ? null
        : ([...opcoes]..sort((a, b) => (b['votos'] as num).compareTo(a['votos'] as num))).first;
    final pct = (vencedora != null && total > 0)
        ? ((vencedora['votos'] as num) / total * 100).round()
        : 0;
    final encerrado = m['estado'] != 'ATIVO';

    final minhaId = m['minhaOpcaoId']?.toString();
    final minha = minhaId == null
        ? null
        : opcoes.firstWhere((o) => o['id']?.toString() == minhaId, orElse: () => const {});
    final acertou = minha != null && vencedora != null && minha['id'] == vencedora['id'];

    return LinhaCartao(
      // Um Momento de que a pessoa participou não desbota junto com os outros: é
      // memória dela, não histórico da rádio.
      opacidade: encerrado && minhaId == null ? .65 : 1,
      icone: Arte(
        icone: m['tipo'] == 'AVISO' ? Symbols.campaign : Symbols.how_to_vote,
        tamanho: 44,
      ),
      titulo: m['titulo']?.toString() ?? '',
      apoio: vencedora != null && total > 0
          ? '${vencedora['rotulo']} venceu com $pct%'
          : (encerrado ? 'Encerrado' : 'No ar'),
      // "Você votou em Ana Castela" — e um selo quando a escolha dela foi a vencedora.
      // É o fechamento que faz a participação valer: sem isso o voto some no nada.
      rodape: minha == null || minha.isEmpty
          ? null
          : Row(children: [
              Icon(acertou ? Symbols.trophy : Symbols.check_circle,
                  fill: 1, size: 13,
                  color: acertou ? BandFMColors.orange : BandFMColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  acertou
                      ? 'Você votou em ${minha['rotulo']} — e ela ganhou'
                      : 'Você votou em ${minha['rotulo']}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: acertou ? BandFMColors.orange : BandFMColors.textTertiary,
                    fontWeight: acertou ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ]),
      aDireita: const Icon(Symbols.chevron_right, size: 18, color: BandFMColors.textTertiary),
    );
  }
}
