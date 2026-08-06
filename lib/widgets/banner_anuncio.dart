import 'package:flutter/material.dart';
import '../tema.dart';

/// Banner âncora do No Ar.
///
/// O inventário publicitário é **estrutura, não enfeite**: a receita do Radio Connect vem
/// de mídia, e a meta de R$ 5 mil por rádio depende de cerca de 6 impressões por usuário
/// por dia. Por isso este espaço existe desde o primeiro desenho de tela.
///
/// As regras que ele respeita, e que não são negociáveis:
///   · mora ABAIXO da informação principal, nunca sobreposto
///   · não aparece enquanto há um Momento ativo disputando a atenção
///   · nunca em tela cheia
///   · sempre identificado como publicidade
class BannerAnuncio extends StatelessWidget {
  /// Quando há Momento ativo, o banner some. A interação tem prioridade absoluta.
  final bool ocultar;
  const BannerAnuncio({super.key, this.ocultar = false});

  @override
  Widget build(BuildContext context) {
    if (ocultar) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      height: 66,
      decoration: BoxDecoration(
        color: Tema.superficie,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Tema.borda),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF1F6F43),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('★', style: TextStyle(fontSize: 22, color: Colors.white)),
            ),
          ),
          const SizedBox(width: Espaco.sm),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Supermercado Estrela',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Ofertas da semana até domingo',
                    style: TextStyle(fontSize: 12.5, color: Tema.texto2)),
              ],
            ),
          ),
          // Identificação obrigatória. Anúncio disfarçado de conteúdo destrói a
          // confiança que faz a mídia valer alguma coisa.
          Padding(
            padding: const EdgeInsets.only(right: Espaco.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Tema.borda),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Publicidade',
                  style: TextStyle(fontSize: 9, color: Tema.texto3, letterSpacing: .3)),
            ),
          ),
        ],
      ),
    );
  }
}
