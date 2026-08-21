import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../tema.dart';
import '../estado_no_ar.dart';

/// A escada de conexão com a rádio.
///
/// O capítulo do Índice define cinco níveis — Descobrindo, Ouvinte presente,
/// Participante, Muito conectado, Embaixador — e diz que a pessoa deve conseguir
/// acompanhar a própria evolução: onde está, o que a trouxe até aqui, o que vem
/// depois.
///
/// **O que este desenho recusa, por instrução do capítulo:**
///   · número. "Índice: 72,4" vira contabilidade; "Muito conectado" vira relação.
///   · ranking. Não existe comparação com outras pessoas, em lugar nenhum.
///   · contagem regressiva para o próximo nível. "Faltam 180 pontos" transforma
///     convite em cobrança — a frase é "falta pouco", e só.
///   · ameaça de perda. A conexão pode diminuir, mas isso nunca vira aviso de
///     ansiedade: *"Sentimos sua falta"*, jamais *"sua conexão vai cair"*.
///
/// A trilha existe para dar **direção**, não meta. Por isso os níveis à frente
/// aparecem apagados mas legíveis: a pessoa vê que há caminho, sem ser empurrada.
class EscadaConexao extends StatelessWidget {
  /// Índice do nível atual, de 0 a 4.
  final int nivel;

  /// O que fez a conexão crescer — em fatos, não em pontos.
  final List<String> porque;

  /// Os nomes dos degraus, vindos do servidor.
  ///
  /// **A linguagem pertence à emissora.** A régua é a mesma para todas as rádios; os
  /// nomes e os limiares são de cada uma, configurados no Studio. Uma rádio jovem chama
  /// o topo de "Da família", outra de "Embaixador", e nenhuma das duas devia depender de
  /// um deploy nosso para isso.
  ///
  /// Vazio cai nos nomes de fábrica — o que acontece quando a resposta é antiga ou o
  /// servidor está velho, e nesses casos uma escada com nomes genéricos é muito melhor
  /// que uma escada sem degrau nenhum.
  final List<String> degraus;

  /// A frase que define cada degrau, na voz da rádio.
  ///
  /// **O nome sozinho não explica o degrau.** "Chega junto" é bonito e não diz o que a
  /// pessoa fez para chegar ali nem o que ela é agora — e o Índice inteiro depende de a
  /// evolução parecer justa, o que exige que ela seja compreendida.
  ///
  /// Vazia, ou sem frase para este degrau, a linha simplesmente não aparece. É melhor
  /// que a rádio não diga nada do que dizer a frase de outra emissora.
  final List<String?> frases;

  const EscadaConexao({
    super.key,
    required this.nivel,
    this.porque = const [],
    this.degraus = const [],
    this.frases = const [],
  });

  /// Estrutura genérica do capítulo. **A linguagem pertence à emissora**: cada rádio
  /// renomeia conforme a própria personalidade, e por isso isto vive numa lista e não
  /// espalhado pelo código.
  static const niveis = <(String, IconData)>[
    ('Descobrindo', Symbols.explore),
    ('Ouvinte presente', Symbols.sensors),
    ('Participante', Symbols.favorite),
    ('Muito conectado', Symbols.local_fire_department),
    ('Embaixador', Symbols.star),
  ];

  /// Os degraus a desenhar: os da emissora quando vieram, os de fábrica quando não.
  ///
  /// O ícone continua sendo nosso, e continua na ordem: ele carrega a progressão visual —
  /// da bússola à estrela — e não é coisa que se configure sem desenhar de novo a escada.
  List<(String, IconData)> get _degraus {
    if (degraus.length != niveis.length) return niveis;
    return [for (var i = 0; i < niveis.length; i++) (degraus[i], niveis[i].$2)];
  }

  /// A frase deste degrau, se a rádio escreveu uma.
  String? get _frase {
    if (nivel < 0 || nivel >= frases.length) return null;
    final f = frases[nivel];
    return (f == null || f.isEmpty) ? null : f;
  }

  @override
  Widget build(BuildContext context) {
    final niveis = _degraus;
    final atual = nivel.clamp(0, niveis.length - 1);
    final ultimo = atual == niveis.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BandFMSpacing.x4),
      decoration: BoxDecoration(
        color: BandFMColors.surface,
        borderRadius: BorderRadius.circular(BandFMRadii.card),
        border: Border.all(color: BandFMColors.orange.withValues(alpha: .28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            EstadoNoAr.nome.isEmpty
                ? 'SUA CONEXÃO COM A RÁDIO'
                : 'SUA CONEXÃO COM A ${EstadoNoAr.nome.toUpperCase()}',
            style: const TextStyle(
                fontSize: 9.5, fontWeight: FontWeight.w800,
                letterSpacing: 1.2, color: BandFMColors.orange)),
        const SizedBox(height: 10),
        Text(niveis[atual].$1,
            style: const TextStyle(
                fontSize: 25, fontWeight: FontWeight.w800,
                letterSpacing: -.6, color: Colors.white)),

        if (_frase != null) ...[
          const SizedBox(height: 6),
          Text(_frase!,
              style: const TextStyle(
                  fontSize: 14, height: 1.4, color: BandFMColors.textSecondary)),
        ],

        const SizedBox(height: 18),
        _trilha(atual),
        const SizedBox(height: 16),

        if (porque.isNotEmpty) ...[
          const Text('Ficou mais forte porque você',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700,
                  color: BandFMColors.textSecondary)),
          const SizedBox(height: 7),
          // Fatos, e não pontuação: é isto que faz a evolução parecer justa. A pessoa
          // entende por que subiu, em vez de aceitar um número que apareceu sozinho.
          ...porque.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 9),
                    child: SizedBox(
                      width: 4, height: 4,
                      child: DecoratedBox(decoration: BoxDecoration(
                          color: BandFMColors.orange, shape: BoxShape.circle)),
                    ),
                  ),
                  Expanded(
                    child: Text(f,
                        style: const TextStyle(
                            fontSize: 13.5, height: 1.4,
                            color: BandFMColors.textSecondary)),
                  ),
                ]),
              )),
          const SizedBox(height: 4),
        ],

        // Direção, não meta. Sem contagem regressiva e sem prazo.
        //
        // No topo não há para onde apontar, e a frase que ficava aqui — "você é de casa"
        // — saiu: ela dizia o que o degrau significa, e isso agora é da rádio, não nossa.
        if (!ultimo)
          Text('Falta pouco para ${niveis[atual + 1].$1}.',
              style: const TextStyle(
                  fontSize: 13, height: 1.4, color: BandFMColors.textTertiary)),
      ]),
    );
  }

  /// A trilha: um traço contínuo com cinco marcos.
  ///
  /// Os já vencidos ficam acesos, o atual ganha o anel, e os de frente permanecem
  /// visíveis em cinza — some-los esconderia o caminho, e acendê-los mentiria.
  Widget _trilha(int atual) {
    return LayoutBuilder(builder: (context, limites) {
      final passo = limites.maxWidth / (niveis.length - 1);
      // Só a bolinha e o traço: os nomes dos cinco níveis lado a lado virariam uma
      // fileira de texto minúsculo ilegível num aparelho de 360 px. O nome do nível
      // atual já está grande acima da trilha, que é onde ele importa.
      return SizedBox(
        height: 26,
        child: Stack(children: [
          Positioned(
            left: 0, right: 0, top: 11,
            child: Container(height: 2, color: Colors.white.withValues(alpha: .1)),
          ),
          Positioned(
            left: 0, top: 11,
            child: Container(
              height: 2,
              width: passo * atual,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFF6821F), Color(0xFFFFB05C)]),
              ),
            ),
          ),
          ...List.generate(niveis.length, (i) {
            final vencido = i <= atual;
            final aqui = i == atual;
            return Positioned(
              left: (passo * i) - (aqui ? 12 : 8),
              top: aqui ? 0 : 4,
              child: Container(
                width: aqui ? 24 : 16,
                height: aqui ? 24 : 16,
                decoration: BoxDecoration(
                  color: vencido ? BandFMColors.orange : BandFMColors.surfaceRaised,
                  shape: BoxShape.circle,
                  border: aqui
                      ? Border.all(color: BandFMColors.orange.withValues(alpha: .35), width: 4)
                      : null,
                ),
                child: aqui
                    ? const Icon(Symbols.check, size: 13, weight: 700,
                        color: BandFMColors.textOnBrand)
                    : null,
              ),
            );
          }),
        ]),
      );
    });
  }
}
