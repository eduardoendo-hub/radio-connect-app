import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../estado_no_ar.dart';
import '../estado_respostas.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/pulso.dart';

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
            BandFMSpacing.screenPadding, 12, BandFMSpacing.screenPadding, BandFMSpacing.x5),
        children: [
          const Text('Momentos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: BandFMSpacing.x4),

          if (ativo.isNotEmpty) _cartaoAtivo(ativo) else _semAtivo(),

          if (passados.isNotEmpty) ...[
            const SizedBox(height: BandFMSpacing.x5),
            const TituloBloco('Antes, hoje'),
            ...passados.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _linhaPassado(m),
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
