import 'package:flutter/material.dart';
import '../tema.dart';

/// "Um oferecimento de X."
///
/// A assinatura de quem paga. Nasceu dentro do Fofocômetro e saiu de lá porque
/// patrocínio nunca foi exclusividade de um quadro: o programa tem patrocinador, o
/// Momento tem patrocinador, e a marca precisa aparecer igual nos dois — se cada tela
/// desenhar a sua, a mesma marca vira três coisas diferentes no mesmo app.
///
/// **Uma assinatura por tela.** Enquanto há Momento patrocinado no ar, é ele quem
/// assina; no resto do tempo, quem assina é o programa. A regra existe porque dois
/// logos disputando a mesma tela não valem o dobro — não valem nada, porque ninguém
/// olha para nenhum dos dois. O específico e caro (minutos, com hora marcada) ganha do
/// permanente e barato (horas, todo dia).
class AssinaturaPatrocinio extends StatelessWidget {
  final Map<String, dynamic> patrocinio;

  /// `discreta` é a versão do cabeçalho do programa: sem caixa, alinhada à esquerda.
  /// O programa fica no ar por horas — uma caixa cheia ali cansaria em dez minutos.
  final bool discreta;

  const AssinaturaPatrocinio(this.patrocinio, {super.key, this.discreta = false});

  /// Devolve `null` quando não há patrocínio, para a tela poder escrever
  /// `AssinaturaPatrocinio.talvez(x) ?? const SizedBox.shrink()` sem espalhar `if`.
  static Widget? talvez(Object? patrocinio, {bool discreta = false}) {
    if (patrocinio is! Map) return null;
    final p = patrocinio.cast<String, dynamic>();
    if ((p['nome']?.toString() ?? '').isEmpty) return null;
    return AssinaturaPatrocinio(p, discreta: discreta);
  }

  @override
  Widget build(BuildContext context) {
    final logo = patrocinio['logoUrl']?.toString();
    final marca = (logo != null && logo.isNotEmpty)
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: discreta ? 15 : 19, maxWidth: discreta ? 76 : 94),
            child: Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _nome()),
          )
        : _nome();

    if (discreta) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Um oferecimento',
            style: TextStyle(fontSize: 10, color: BandFMColors.textTertiary)),
        const SizedBox(width: 7),
        marca,
      ]);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(BandFMRadii.md),
      ),
      child: Row(children: [
        const Expanded(
          child: Text('Um oferecimento',
              style: TextStyle(fontSize: 10.5, color: BandFMColors.textTertiary)),
        ),
        const SizedBox(width: 12),
        marca,
      ]),
    );
  }

  Widget _nome() => Text(
        patrocinio['nome']?.toString() ?? '',
        style: TextStyle(
            fontSize: discreta ? 11.5 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
            color: discreta ? BandFMColors.textSecondary : Colors.white),
      );
}
