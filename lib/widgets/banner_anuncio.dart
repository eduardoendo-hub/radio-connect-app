import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';

/// O banner do No Ar.
///
/// **Publicidade que não fere a experiência** é a regra do capítulo do inventário, e
/// aqui ela é estrutura, não boa vontade:
///
///   · O servidor recusa servir banner enquanto há Momento no ar. Este widget nem
///     precisa saber disso — ele pede, e não vem nada.
///   · Sem inventário, o espaço **desaparece**. Um retângulo cinza escrito "publicidade"
///     é pior que anúncio nenhum: ocupa a tela e não paga nada.
///   · A palavra "publicidade" fica visível e legível. Anúncio disfarçado de conteúdo
///     rende um clique e perde a confiança para sempre.
///
/// A impressão é criada pelo servidor no momento da decisão; daqui sai só a
/// confirmação de que o banner realmente apareceu na tela. Essa diferença é o que
/// separa "servi" de "foi visto" no extrato do fim do mês.
class BannerAnuncio extends StatefulWidget {
  final String posicao;
  const BannerAnuncio({super.key, this.posicao = 'no_ar_banner'});

  @override
  State<BannerAnuncio> createState() => _BannerAnuncioState();
}

class _BannerAnuncioState extends State<BannerAnuncio> {
  Map<String, dynamic>? _anuncio;
  bool _buscou = false;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    try {
      final r = await Api.obter('/anuncios?posicao=${widget.posicao}');
      if (!mounted) return;
      final a = r['anuncio'] as Map<String, dynamic>?;
      setState(() { _anuncio = a; _buscou = true; });
      // Confirmar a visibilidade é o que transforma uma decisão em impressão contável.
      if (a != null) {
        Api.enviar('/anuncios/${a['impressaoId']}/confirmar', {'visivel': true})
            .catchError((_) => <String, dynamic>{});
      }
    } catch (_) {
      if (mounted) setState(() => _buscou = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Enquanto não sabemos, nada. Um esqueleto piscando aqui seria uma promessa de
    // anúncio que talvez não venha.
    if (!_buscou || _anuncio == null) return const SizedBox.shrink();

    final a = _anuncio!;
    final url = a['url']?.toString() ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('PUBLICIDADE',
            style: TextStyle(
                fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 1.2,
                color: BandFMColors.textTertiary.withValues(alpha: .8))),
        const Spacer(),
        Text(a['anunciante']?.toString() ?? '',
            style: TextStyle(
                fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: .5,
                color: BandFMColors.textTertiary.withValues(alpha: .8))),
      ]),
      const SizedBox(height: 6),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Api.enviar('/anuncios/${a['impressaoId']}/confirmar', {'clicado': true})
                .catchError((_) => <String, dynamic>{});
          },
          borderRadius: BorderRadius.circular(BandFMRadii.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(BandFMRadii.md),
            child: AspectRatio(
              aspectRatio: 900 / 240,
              child: Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    ]);
  }
}

/// O pré-roll: o anúncio que toca antes do stream abrir.
///
/// Fica numa camada sobre a tela, com o tempo correndo e sem botão de pular — nove
/// segundos é curto o bastante para não virar castigo, e o servidor garante que não se
/// repete antes do intervalo configurado.
///
/// **Se o áudio falhar, a rádio entra assim mesmo.** Anúncio que impede a pessoa de
/// ouvir rádio destrói o produto para salvar uma impressão.
class SobreposicaoPreRoll extends StatelessWidget {
  final String anunciante;
  final int restante;
  const SobreposicaoPreRoll({super.key, required this.anunciante, required this.restante});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BandFMColors.surfaceRaised,
        borderRadius: BorderRadius.circular(BandFMRadii.md),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(children: [
        const Icon(Symbols.campaign, fill: 1, size: 18, color: BandFMColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Publicidade · $anunciante',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            const Text('A Band FM começa em seguida',
                style: TextStyle(fontSize: 11.5, color: BandFMColors.textTertiary)),
          ]),
        ),
        Text('${restante}s',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: BandFMColors.orange)),
      ]),
    );
  }
}
