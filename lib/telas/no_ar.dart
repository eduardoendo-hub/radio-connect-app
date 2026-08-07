import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../estado_no_ar.dart';
import '../tema.dart';
import '../widgets/pulso.dart';
import '../widgets/comuns.dart';
import '../widgets/cartao_momento.dart';

/// 02 · 03 · 05 — O No Ar.
///
/// **A Home deixa de existir.** O usuário não entra num menu, entra no que está
/// acontecendo naquele instante.
///
/// A tela renderiza **por estado**, não por lista fixa de blocos:
/// normal · comMomento · promoção · transição · especial · contingência.
///
/// E nunca pode parecer parada: sem Momento, o programa, o locutor, a música, a
/// próxima atração e a evolução da conexão mantêm a tela viva. O silêncio faz parte.
class TelaNoAr extends StatelessWidget {
  final EstadoNoAr estado;
  const TelaNoAr({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: estado,
      builder: (context, _) {
        if (estado.estado == null) {
          return const Center(child: CircularProgressIndicator(color: BandFMColors.orange));
        }

        final programa = estado.programa;
        final locutor = estado.locutor;
        final momento = estado.momento;
        final promocao = estado.promocao;

        return RefreshIndicator(
          color: BandFMColors.orange,
          backgroundColor: BandFMColors.surface,
          onRefresh: estado.atualizar,
          child: Stack(children: [
            // O calor atrás do cabeçalho: a sensação de "no ar" antes de qualquer texto.
            Container(
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A2110), Color(0x000A0A0A)],
                  stops: [0.0, 0.92],
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                  BandFMSpacing.screenPadding, 8, BandFMSpacing.screenPadding, BandFMSpacing.x5),
              children: [
                _cabecalho(),
                const SizedBox(height: BandFMSpacing.x5),

                // 1º NÍVEL — presença
                Text(
                  programa?['nome']?.toString() ?? 'Band FM',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -.7),
                ),
                if (locutor != null) ...[
                  const SizedBox(height: 8),
                  _equipe(estado.estado?['equipe'], locutor),
                ],

                const SizedBox(height: 12),
                _audiencia(),
                const SizedBox(height: BandFMSpacing.x5),

                // 3º NÍVEL — participação. Quando existe, assume a área principal.
                if (momento != null) ...[
                  CartaoMomento(
                    key: ValueKey(momento['id']),
                    momento: momento,
                    aoResponder: estado.atualizar,
                  ),
                  const SizedBox(height: BandFMSpacing.x3),
                ] else if (promocao != null) ...[
                  _cartaoPromocao(promocao),
                  const SizedBox(height: BandFMSpacing.x3),
                ],

                _tocandoAgora(),
                const SizedBox(height: 10),

                // 4º NÍVEL — continuidade
                if (estado.proxima != null) ...[
                  _proximoMomento(),
                  const SizedBox(height: 10),
                ],

                _conexao(),
                const SizedBox(height: 10),

                // Inventário: espaço estrutural, reservado desde o primeiro desenho.
                // Some quando há Momento — a interação tem prioridade absoluta.
                if (momento == null) _slotBanner(),
              ],
            ),
          ]),
        );
      },
    );
  }

  /// Quem está no microfone agora.
  ///
  /// Rádio quase nunca é uma voz só, e o ouvinte reconhece as três pessoas da manhã
  /// pelo nome. Mostrar só o titular apagaria justamente o que faz aquela manhã ser
  /// aquela manhã — por isso a equipe inteira aparece, com o rosto de cada um.
  ///
  /// Enquanto as fotos oficiais não chegam, o avatar é a inicial sobre o laranja da
  /// casa. É honesto: não finge uma foto que não temos, e não deixa buraco na tela.
  Widget _equipe(Object? bruto, Map<String, dynamic> titular) {
    final lista = (bruto as List?)?.cast<Map<String, dynamic>>() ?? [titular];
    final nomes = lista.map((l) => l['nome']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    if (nomes.isEmpty) return const SizedBox.shrink();

    // "com Tadeu Correa, Emerson França e Pedro Luiz Ronco" — a vírgula até o
    // penúltimo, "e" antes do último. É como se fala, não como se lista.
    final texto = nomes.length == 1
        ? nomes.first
        : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';

    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // Os avatares se sobrepõem levemente: lê como equipe, não como lista.
      SizedBox(
        height: 30,
        width: 30 + (lista.length - 1) * 21,
        child: Stack(
          children: List.generate(lista.length, (i) {
            final l = lista[i];
            return Positioned(
              left: i * 21,
              child: _avatarLocutor(l['nome']?.toString() ?? '', l['imagemUrl']?.toString()),
            );
          }),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text('com $texto',
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w500,
                height: 1.3, color: BandFMColors.textSecondary)),
      ),
    ]);
  }

  Widget _avatarLocutor(String nome, String? imagemUrl) {
    final inicial = nome.trim().isEmpty ? '?' : nome.trim().characters.first.toUpperCase();
    return Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        gradient: imagemUrl == null ? BandFMColors.momentGradient : null,
        shape: BoxShape.circle,
        // O anel da cor do fundo é o que faz a sobreposição funcionar: sem ele os
        // rostos encostam e viram uma mancha.
        border: Border.all(color: BandFMColors.bg, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagemUrl != null
          ? Image.network(imagemUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _inicial(inicial))
          : _inicial(inicial),
    );
  }

  Widget _inicial(String letra) => Center(
        child: Text(letra,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
      );

  Widget _cabecalho() => Row(
        children: [
          Image.asset('assets/logo-emissora.webp', height: 26),
          const Spacer(),
          if (estado.semRede)
            const Row(children: [
              Icon(Symbols.cloud_off, size: 14, color: BandFMColors.textTertiary),
              SizedBox(width: 5),
              Text('sem conexão', style: TextStyle(fontSize: 11.5, color: BandFMColors.textTertiary)),
            ])
          else
            EtiquetaNoAr(
              ritmo: estado.momento != null
                  ? RitmoPulso.momentoAtivo
                  : estado.aoVivo
                      ? RitmoPulso.noAr
                      : RitmoPulso.foraDoAr,
            ),
        ],
      );

  /// "15.432 ouvintes vivendo este momento" — nunca "usuários online".
  /// A linguagem transforma métrica em pertencimento.
  Widget _audiencia() => Row(children: [
        const Equalizador(),
        const SizedBox(width: 9),
        Text(
          '${_comPonto(estado.ouvintes)} ${estado.ouvintes == 1 ? 'ouvinte vivendo' : 'ouvintes vivendo'} este momento',
          style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: BandFMColors.orange, letterSpacing: -.1),
        ),
      ]);

  static String _comPonto(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  Widget _tocandoAgora() {
    final musica = estado.musica;
    return LinhaCartao(
      icone: const Arte(icone: Symbols.music_note, tamanho: 56, gradiente: BandFMColors.momentGradient),
      titulo: musica?['titulo']?.toString() ?? 'Band FM 96,1',
      apoio: musica?['artista']?.toString() ?? 'A programação continua',
      aDireita: const Icon(Symbols.favorite, size: 20, color: BandFMColors.textTertiary),
    );
  }

  Widget _proximoMomento() {
    final n = estado.proxima!;
    final quando = DateTime.tryParse(n['comeca']?.toString() ?? '');
    final hora = quando == null
        ? ''
        : '${quando.hour.toString().padLeft(2, '0')}h${quando.minute.toString().padLeft(2, '0')}';
    return LinhaCartao(
      icone: const Arte(icone: Symbols.schedule, tamanho: 44),
      titulo: 'A seguir, $hora',
      apoio: n['nome']?.toString(),
    );
  }

  Widget _conexao() => LinhaCartao(
        icone: const Arte(icone: Symbols.trending_up, tamanho: 44),
        titulo: 'Sua conexão cresceu nesta semana',
        apoio: '3h20 de escuta · 4 Momentos',
        aDireita: const Icon(Symbols.chevron_right, size: 20, color: BandFMColors.textTertiary),
      );

  /// 05 · Estado "Promoção": ela ocupa a área principal.
  /// Promoções não são aba — vivem no No Ar, em Momentos e em Sua Rádio.
  /// A promoção deixou de ser um pôster e virou uma linha.
  ///
  /// A faixa de laranja atravessada no topo, com um ícone perdido no meio e um título
  /// de manchete embaixo, fazia a promoção gritar mais alto que o Momento no ar — que
  /// é o coração desta tela. Aqui ela cabe em três linhas ao lado de uma miniatura, e
  /// nenhuma informação se perdeu: o rótulo, o prêmio, como o resultado sai e a ação.
  ///
  /// A ação é uma pílula, não um botão de largura inteira. Botão gordo ocupando a
  /// largura da tela é o vocabulário de formulário; aqui é convite.
  Widget _cartaoPromocao(Map<String, dynamic> p) => Cartao(
        padding: const EdgeInsets.all(13),
        borda: Border.all(color: BandFMColors.orange.withValues(alpha: .26)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // A arte vira miniatura: cor e ícone bastam para dizer "promoção".
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: BandFMColors.momentGradient,
              borderRadius: BorderRadius.circular(BandFMRadii.md),
              border: Border.all(color: const Color(0x24FFFFFF)),
            ),
            child: const Icon(Symbols.local_activity, fill: 1, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PROMOÇÃO NO AR',
                  style: TextStyle(
                      fontSize: 9.5, fontWeight: FontWeight.w800,
                      letterSpacing: 1.15, color: BandFMColors.orange)),
              const SizedBox(height: 5),
              Text(p['titulo']?.toString() ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.25, letterSpacing: -.2)),
              const SizedBox(height: 3),
              const Text('O resultado sai ao vivo, com o locutor.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: BandFMColors.textTertiary)),
              const SizedBox(height: 11),
              Row(children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(BandFMRadii.pill),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 34),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: BandFMColors.orange,
                        borderRadius: BorderRadius.circular(BandFMRadii.pill),
                      ),
                      child: const Text('Quero participar',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: BandFMColors.textOnBrand)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Regras',
                    style: TextStyle(
                        fontSize: 12, color: BandFMColors.textTertiary,
                        decoration: TextDecoration.underline,
                        decorationColor: BandFMColors.textTertiary)),
              ]),
            ]),
          ),
        ]),
      );

  Widget _slotBanner() => Container(
        height: 66,
        decoration: BoxDecoration(
          color: BandFMColors.surface,
          borderRadius: BorderRadius.circular(BandFMRadii.md),
          border: Border.all(color: BandFMColors.line),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Symbols.ads_click, size: 16, color: BandFMColors.textTertiary),
          SizedBox(width: 8),
          Text('Banner contextual · patrocinado',
              style: TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
        ]),
      );
}
