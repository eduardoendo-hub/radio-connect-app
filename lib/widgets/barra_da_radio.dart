import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../estado_no_ar.dart';
import '../tema.dart';
import 'pulso.dart';

/// A barra da rádio: logo à esquerda, estado à direita, em todas as abas.
///
/// **Por que ela existe.**
///
/// O produto é white-label. A pessoa precisa dizer "essa é a minha rádio", não "esse
/// app de rádio" — e até aqui a marca da emissora só aparecia na aba No Ar. Nas outras
/// três, o app perdia ao mesmo tempo a identidade de quem fala e a informação de que a
/// transmissão está acontecendo agora.
///
/// **Por que é magra.**
///
/// Cada aba já tem cabeçalho próprio: o título em Momentos, o perfil em Sua Rádio, o
/// status de atendimento no Chat. Uma barra alta por cima disso viraria duas barras e
/// comeria a tela vertical, que em aparelho de 360 px é o recurso mais escasso que
/// existe. Quarenta pixels dão conta de uma marca e de um estado.
///
/// **Por que o pulso e não um texto.**
///
/// "AO VIVO" escrito é rótulo; o ponto batendo é estado. E o ritmo carrega informação
/// de verdade — acelera quando há Momento no ar, do mesmo jeito que o pulso da marca no
/// Studio. Quem usa o app todo dia aprende a ler isso sem nem olhar direito.
class BarraDaRadio extends StatelessWidget {
  final EstadoNoAr estado;
  const BarraDaRadio({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: estado,
      builder: (context, _) => Container(
        padding: const EdgeInsets.fromLTRB(BandFMSpacing.screenPadding, 8, BandFMSpacing.screenPadding, 8),
        decoration: const BoxDecoration(
          color: BandFMColors.bg,
          border: Border(bottom: BorderSide(color: BandFMColors.line)),
        ),
        child: Row(children: [
          Image.asset('assets/logo-emissora.webp', height: 26),
          const Spacer(),
          if (estado.semRede)
            const Row(children: [
              Icon(Symbols.cloud_off, size: 13, color: BandFMColors.textTertiary),
              SizedBox(width: 5),
              Text('sem conexão',
                  style: TextStyle(fontSize: 11, color: BandFMColors.textTertiary)),
            ])
          else
            EtiquetaNoAr(
              ritmo: estado.momento != null
                  ? RitmoPulso.momentoAtivo
                  : estado.aoVivo
                      ? RitmoPulso.noAr
                      : RitmoPulso.foraDoAr,
            ),
        ]),
      ),
    );
  }
}
