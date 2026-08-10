import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../estado_no_ar.dart';
import '../tema.dart';
import '../tempo.dart';
import '../widgets/assinatura_patrocinio.dart';
import '../widgets/cartao_promocao.dart';
import 'promocao.dart';
import '../widgets/pulso.dart';
import '../widgets/comuns.dart';
import '../widgets/cartao_momento.dart';
import '../widgets/cartao_fofocometro.dart';
import '../widgets/avatar_locutor.dart';
import '../widgets/banner_anuncio.dart';

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
                // O cabeçalho local saiu: logo e estado agora vivem na barra da casca,
                // presente em todas as abas. Repetir aqui daria dois logos na mesma
                // tela.
                const SizedBox(height: BandFMSpacing.x4),

                // 1º NÍVEL — presença
                //
                // Nome do programa e rostos na mesma linha. Antes o nome ocupava a
                // largura toda em corpo 30 e os avatares vinham na linha de baixo, ao
                // lado do "com…" — três linhas para dizer quem está no ar, e a
                // promoção começava depois da dobra em telas pequenas.
                //
                // O nome caiu 20% e continua sendo a maior coisa da tela, que é o que
                // importa: a hierarquia é relativa, não absoluta.
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                    child: Text(
                      programa?['nome']?.toString() ?? 'Band FM',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w800, height: 1.12,
                          letterSpacing: -.6),
                    ),
                  ),
                  if (locutor != null) ...[
                    const SizedBox(width: 12),
                    EquipeNoAr(
                      locutores: (estado.estado?['equipe'] as List?)?.cast<Map<String, dynamic>>()
                          ?? [locutor],
                      tamanho: 34,
                    ),
                  ],
                ]),
                if (locutor != null) ...[
                  const SizedBox(height: 7),
                  _equipe(estado.estado?['equipe'], locutor),
                ],

                // Uma assinatura por tela.
                //
                // Se o Momento no ar tem patrocinador, é ele quem assina — e o do
                // programa se cala. Dois logos disputando a mesma tela não valem o
                // dobro: não valem nada, porque ninguém olha para nenhum dos dois. O
                // inventário específico e caro (minutos, hora marcada) ganha do
                // permanente e barato (horas, todo dia), e o do programa volta sozinho
                // assim que o Momento sai.
                if (momento?['patrocinio'] == null) ...[
                  Builder(builder: (_) {
                    final assina = AssinaturaPatrocinio.talvez(
                        estado.estado?['patrocinioDoPrograma'],
                        discreta: true);
                    if (assina == null) return const SizedBox.shrink();
                    return Padding(
                        padding: const EdgeInsets.only(top: 10), child: assina);
                  }),
                ],

                const SizedBox(height: 12),
                _audiencia(),
                const SizedBox(height: BandFMSpacing.x5),

                // 3º NÍVEL — participação. Quando existe, assume a área principal.
                if (momento != null) ...[
                  // O Fofocômetro não pede resposta, pede espera — outro cartão, outra
                  // lógica. Os dois continuam sendo Momentos para o resto do sistema.
                  if (momento['tipo'] == 'FOFOCOMETRO')
                    CartaoFofocometro(key: ValueKey(momento['id']), momento: momento)
                  else
                    CartaoMomento(
                      key: ValueKey(momento['id']),
                      momento: momento,
                      aoResponder: estado.atualizar,
                    ),
                  const SizedBox(height: BandFMSpacing.x3),
                ] else if (promocao != null) ...[
                  // A promoção só ocupa o bloco principal quando não há Momento no ar.
                  // Momento é *agora* e pede resposta em segundos; promoção é *hoje* e
                  // espera. Os dois disputando o mesmo lugar fariam a tela gritar duas
                  // vezes e a pessoa não atender nenhuma.
                  Builder(builder: (contexto) {
                    void abrir() => Navigator.of(contexto)
                        .push(MaterialPageRoute(builder: (_) => TelaPromocao(promocao: promocao)))
                        .then((_) => estado.atualizar());
                    return GestureDetector(
                      onTap: abrir,
                      child: CartaoPromocao(
                        key: ValueKey(promocao['id']),
                        promocao: promocao,
                        aoAbrir: abrir,
                      ),
                    );
                  }),
                  const SizedBox(height: BandFMSpacing.x3),
                ],

                // As outras promoções no ar.
                //
                // O bloco principal mostra uma. As demais ficavam sem lugar nenhum no
                // aplicativo — publicar a segunda fazia a primeira sumir, e promoção
                // invisível é inscrição que a rádio não recebe. Aqui elas são caminho, e
                // não vitrine: linha curta, arte pequena, toque abre a promoção inteira.
                ..._outrasPromocoes(context),

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
                //
                // Some quando há Momento — a interação tem prioridade absoluta — e
                // some também quando não há campanha para servir. O servidor decide as
                // duas coisas; aqui só se pede.
                if (momento == null) const BannerAnuncio(),
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
  /// Enquanto as fotos oficiais não chegam, cada um ganha um avatar ilustrado —
  /// determinístico, para que "o roxo é o Robson" vire reconhecimento de verdade.
  /// Ver [AvatarLocutor].
  Widget _equipe(Object? bruto, Map<String, dynamic> titular) {
    final lista = (bruto as List?)?.cast<Map<String, dynamic>>() ?? [titular];
    final nomes = lista.map((l) => l['nome']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    if (nomes.isEmpty) return const SizedBox.shrink();

    // "com Tadeu Correa, Emerson França e Pedro Luiz Ronco" — a vírgula até o
    // penúltimo, "e" antes do último. É como se fala, não como se lista.
    final texto = nomes.length == 1
        ? nomes.first
        : '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}';

    // Só o texto: os rostos subiram para a linha do nome do programa.
    return Text('com $texto',
        maxLines: 2, overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            height: 1.3, color: BandFMColors.textSecondary));
  }

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

  List<Widget> _outrasPromocoes(BuildContext context) {
    final outras = (estado.estado?['outrasPromocoes'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    if (outras.isEmpty) return const [];

    return [
      const TituloBloco('Também no ar'),
      for (final p in outras) ...[
        GestureDetector(
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => TelaPromocao(promocao: p)))
              .then((_) => estado.atualizar()),
          child: LinhaCartao(
            icone: p['imagemUrl'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(BandFMRadii.md),
                    child: Image.network(p['imagemUrl'].toString(),
                        width: 44, height: 44, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Arte(icone: Symbols.local_activity, tamanho: 44)),
                  )
                : const Arte(icone: Symbols.local_activity, tamanho: 44),
            titulo: p['titulo']?.toString() ?? '',
            apoio: instante(p['sorteioEm']) != null
                ? 'Sorteio ${quando(instante(p['sorteioEm']))}'
                : 'Promoção no ar',
            aDireita: const Icon(Symbols.chevron_right,
                size: 18, color: BandFMColors.textTertiary),
          ),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: BandFMSpacing.x2),
    ];
  }

  Widget _proximoMomento() {
    final n = estado.proxima!;
    final hora = horaCheia(instante(n['comeca']));
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


}
