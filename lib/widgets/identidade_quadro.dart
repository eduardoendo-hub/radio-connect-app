import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// A identidade visual de um quadro: a cor e o ícone que o ouvinte aprende a
/// reconhecer antes de ler o título.
///
/// **Quase nenhum quadro tem uma, e é essa a regra.** Fofocômetro e Batalha das Músicas
/// têm porque são formatos com ritual — hora marcada, vencedor, expectativa. O resto
/// usa a linguagem da emissora, e é justamente esse fundo comum que faz os dois com
/// marca saltarem. Se todo formato ganhasse cor própria, nenhum se destacaria e o app
/// viraria uma vitrine de crachás.
class IdentidadeQuadro {
  final Color cor;
  final IconData? icone;

  const IdentidadeQuadro(this.cor, this.icone);

  /// Lê o que o servidor mandou. `null` quando o quadro não tem identidade — que é o
  /// caso da maioria, e por isso a chamada tem que ser barata de escrever.
  static IdentidadeQuadro? de(Object? bruto) {
    if (bruto is! Map) return null;
    final cor = _cor(bruto['cor']?.toString());
    if (cor == null) return null;
    return IdentidadeQuadro(cor, _icones[bruto['icone']?.toString()]);
  }

  static Color? _cor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final limpo = hex.replaceFirst('#', '');
    final valor = int.tryParse(limpo, radix: 16);
    if (valor == null) return null;
    return Color(limpo.length == 6 ? 0xFF000000 | valor : valor);
  }

  /// O nome do ícone vem do banco como texto, então o mapa é a fronteira.
  ///
  /// Lista fechada de propósito: um `IconData` construído a partir de um code point
  /// arbitrário do banco compila e desenha um retângulo vazio em produção. Nome que
  /// não estiver aqui simplesmente não desenha ícone — a cor sozinha já identifica.
  static const _icones = <String, IconData>{
    'campaign': Symbols.campaign,
    'swords': Symbols.swords,
    'favorite': Symbols.favorite,
    'trophy': Symbols.trophy,
    'music_note': Symbols.music_note,
    'bolt': Symbols.bolt,
    'star': Symbols.star,
  };
}
