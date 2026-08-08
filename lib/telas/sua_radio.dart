import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../tema.dart';
import '../widgets/comuns.dart';
import '../widgets/escada_conexao.dart';

/// 08 · Sua Rádio.
///
/// **Não é um perfil.** É o relacionamento do ouvinte com aquela emissora — a memória
/// da relação, não os dados da pessoa.
///
/// O Índice de Conexão aparece em **linguagem, nunca como número frio**: "Muito forte",
/// não "82 pontos". Sem ranking público e sem gamificação infantil.
///
/// **Estado atual: números simulados.** O backend já grava os eventos e tem o modelo
/// de snapshot; o cálculo do Índice entra em seguida.
class TelaSuaRadio extends StatelessWidget {
  final String? nome;
  const TelaSuaRadio({super.key, this.nome});

  @override
  Widget build(BuildContext context) {
    final primeiroNome = (nome ?? 'Ouvinte').split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BandFMSpacing.screenPadding, 16, BandFMSpacing.screenPadding, BandFMSpacing.x5),
      children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: BandFMColors.momentGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                primeiroNome.characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(primeiroNome,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.3)),
              const SizedBox(height: 2),
              const Text('Ouvinte desde março de 2026',
                  style: TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
            ]),
          ),
          const Icon(Symbols.settings, size: 22, color: BandFMColors.textTertiary),
        ]),

        const SizedBox(height: BandFMSpacing.x5),
        // A escada substitui a barra solta: uma barra diz "quanto", a escada diz
        // "onde você está e para onde isso vai" — que é o que o capítulo pede.
        const EscadaConexao(
          nivel: 3,
          porque: [
            'voltou em quatro dias desta semana',
            'participou de três Momentos',
            'conversou com a rádio',
          ],
        ),

        const SizedBox(height: BandFMSpacing.x3),
        Row(children: [
          Expanded(child: _numero('3h20', 'de escuta nesta semana')),
          const SizedBox(width: 10),
          Expanded(child: _numero('12', 'Momentos no mês')),
        ]),

        const SizedBox(height: BandFMSpacing.x5),
        const TituloBloco('Suas promoções'),
        LinhaCartao(
          icone: const Arte(icone: Symbols.local_activity, tamanho: 44, cor: Color(0xFF1F4D2B)),
          titulo: 'Baladão Band FM',
          apoio: 'Participando · resultado às 11h',
          aDireita: const Icon(Symbols.chevron_right, size: 18, color: BandFMColors.textTertiary),
        ),
        const SizedBox(height: 8),
        const LinhaCartao(
          opacidade: .65,
          icone: Arte(icone: Symbols.redeem, tamanho: 44),
          titulo: 'Kit Band FM',
          apoio: 'Encerrada · não foi dessa vez',
        ),
      ],
    );
  }

  Widget _numero(String valor, String rotulo) => Cartao(
        padding: const EdgeInsets.all(BandFMSpacing.x4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 4),
          Text(rotulo,
              style: const TextStyle(fontSize: 12, color: BandFMColors.textTertiary, height: 1.3)),
        ]),
      );
}
