import 'package:flutter/material.dart';
import '../api.dart';
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
class AssinaturaPatrocinio extends StatefulWidget {
  final Map<String, dynamic> patrocinio;

  /// O que estava na tela: a Edição do programa, o Momento, a promoção.
  ///
  /// É o que define **uma** impressão. Um patrocínio de três horas vale uma exposição
  /// por ouvinte naquela edição, não uma a cada repintura — senão o número deixa de
  /// significar alguma coisa e a fatura deixa de ser defensável.
  final String? posicao;
  final String? referenciaId;

  /// `discreta` é a versão do cabeçalho do programa: sem caixa, alinhada à esquerda.
  /// O programa fica no ar por horas — uma caixa cheia ali cansaria em dez minutos.
  final bool discreta;

  const AssinaturaPatrocinio(
    this.patrocinio, {
    super.key,
    this.discreta = false,
    this.posicao,
    this.referenciaId,
  });

  /// Devolve `null` quando não há patrocínio, para a tela poder escrever
  /// `AssinaturaPatrocinio.talvez(x) ?? const SizedBox.shrink()` sem espalhar `if`.
  static Widget? talvez(
    Object? patrocinio, {
    bool discreta = false,
    String? posicao,
    String? referenciaId,
  }) {
    if (patrocinio is! Map) return null;
    final p = patrocinio.cast<String, dynamic>();
    if ((p['nome']?.toString() ?? '').isEmpty) return null;
    return AssinaturaPatrocinio(
      p,
      discreta: discreta,
      posicao: posicao,
      referenciaId: referenciaId,
    );
  }

  @override
  State<AssinaturaPatrocinio> createState() => _AssinaturaPatrocinioState();
}

class _AssinaturaPatrocinioState extends State<AssinaturaPatrocinio> {
  @override
  void initState() {
    super.initState();
    _registrar();
  }

  @override
  void didUpdateWidget(AssinaturaPatrocinio antes) {
    super.didUpdateWidget(antes);
    // Trocou o que está na tela — outro Momento, outra edição —, conta de novo. É outra
    // exposição, de outra coisa.
    if (antes.referenciaId != widget.referenciaId) _registrar();
  }

  /// Avisa que a marca apareceu.
  ///
  /// Sem `await` e sem tratar erro de propósito: contar impressão é telemetria, e
  /// telemetria nunca pode atrasar nem quebrar o que a pessoa veio ver. Se falhar, o
  /// que se perde é um número — não a tela.
  ///
  /// O servidor recusa a repetida sozinho, num índice único: o aplicativo não precisa
  /// lembrar o que já contou, e assim reinstalar o app não vira impressão nova.
  void _registrar() {
    final campanhaId = widget.patrocinio['campanhaId']?.toString();
    final posicao = widget.posicao;
    final referenciaId = widget.referenciaId;
    if (campanhaId == null || posicao == null || referenciaId == null) return;

    Api.enviar('/anuncios/assinatura', {
      'campanhaId': campanhaId,
      'posicao': posicao,
      'referenciaId': referenciaId,
    }).catchError((_) => <String, dynamic>{});
  }

  Map<String, dynamic> get patrocinio => widget.patrocinio;
  bool get discreta => widget.discreta;

  @override
  Widget build(BuildContext context) {
    final logo = patrocinio['logoUrl']?.toString();
    final marca = (logo != null && logo.isNotEmpty) ? _placa(logo) : _nome();

    if (discreta) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('Um oferecimento',
            style: TextStyle(fontSize: 12, color: BandFMColors.textTertiary)),
        const SizedBox(width: 8),
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

  /// O logo sobre uma placa clara.
  ///
  /// **Sem isto, metade das marcas do Brasil some.** O logo da Ituran é azul-marinho
  /// com fundo transparente: num app de fundo quase preto, o desenho existe e ninguém
  /// vê. O da Soneda funciona por acaso — o criativo já traz o próprio roxo atrás.
  ///
  /// Recolorir a marca do anunciante não é opção; é a única coisa num contrato de mídia
  /// que não se mexe. Então a placa é nossa: o mesmo branco de sempre atrás de qualquer
  /// logo, que é o que impressão gráfica faz há um século quando a arte é escura e o
  /// papel também. Como o produto é white-label, isso não é um ajuste para a Ituran —
  /// é o que faz a próxima rádio poder vender para qualquer anunciante.
  Widget _placa(String logo) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: discreta ? 7 : 9, vertical: discreta ? 4 : 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(discreta ? 5 : 6),
        ),
        child: ConstrainedBox(
          // Discreta 20% maior: no cabeçalho do programa a assinatura fica o dia
          // inteiro, e pequena demais ela vira ruído que ninguém lê nem esquece.
          constraints: BoxConstraints(
              maxHeight: discreta ? 18 : 21, maxWidth: discreta ? 91 : 104),
          child: Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _nome()),
        ),
      );

  Widget _nome() => Text(
        patrocinio['nome']?.toString() ?? '',
        style: TextStyle(
            fontSize: discreta ? 13.5 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
            color: discreta ? BandFMColors.textSecondary : Colors.white),
      );
}
