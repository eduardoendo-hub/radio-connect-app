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
                  const SizedBox(height: 5),
                  Text('com ${locutor['nome']}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500, color: BandFMColors.textSecondary)),
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
  Widget _cartaoPromocao(Map<String, dynamic> p) => Cartao(
        padding: EdgeInsets.zero,
        borda: Border.all(color: BandFMColors.orange.withValues(alpha: .35)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 120,
            decoration: const BoxDecoration(
              gradient: BandFMColors.momentGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(BandFMRadii.card)),
            ),
            child: const Center(child: Icon(Symbols.local_activity, size: 40, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.all(BandFMSpacing.x4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const RotuloSecao('Promoção no ar'),
              const SizedBox(height: 8),
              Text(p['titulo']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -.4)),
              const SizedBox(height: 8),
              const Text('Participe agora. O resultado sai ao vivo, com o locutor.',
                  style: TextStyle(fontSize: 14, height: 1.45, color: BandFMColors.textSecondary)),
              const SizedBox(height: BandFMSpacing.x4),
              FilledButton(onPressed: () {}, child: const Text('Quero participar')),
              const SizedBox(height: 8),
              const Center(
                child: Text('Regras completas na próxima tela',
                    style: TextStyle(fontSize: 12, color: BandFMColors.textTertiary)),
              ),
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
