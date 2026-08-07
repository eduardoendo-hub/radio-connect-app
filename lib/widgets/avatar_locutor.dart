import 'package:flutter/material.dart';
import '../tema.dart';

/// O rosto do locutor.
///
/// Enquanto as fotos oficiais não chegam, cada pessoa ganha um avatar ilustrado —
/// silhueta sobre um fundo em duas cores, desenhado na hora a partir do nome.
///
/// **Por que ilustração e não uma foto qualquer:** são pessoas reais num produto
/// comercial. Uma silhueta não finge ser ninguém; uma foto tirada da internet finge, e
/// ainda por cima sem licença. A ilustração ocupa o lugar certo, com dignidade, até a
/// emissora mandar as fotos aprovadas — e o dia em que mandarem, `imagemUrl` entra e
/// nada mais muda.
///
/// O desenho é **determinístico**: o mesmo nome gera sempre a mesma cor e a mesma
/// silhueta. Isso importa mais do que parece — o ouvinte reconhece "o roxo é o Robson"
/// depois de dois dias, e um avatar que muda de cor a cada carregamento destruiria esse
/// reconhecimento.
class AvatarLocutor extends StatelessWidget {
  final String nome;
  final String? imagemUrl;
  final double tamanho;

  /// O anel da cor do fundo, que separa avatares sobrepostos. Sem ele, dois rostos
  /// encostados viram uma mancha só.
  final Color? anel;

  const AvatarLocutor({
    super.key,
    required this.nome,
    this.imagemUrl,
    this.tamanho = 30,
    this.anel,
  });

  /// Paleta quente, da família da marca. Nenhum cinza: rosto apagado parece conta
  /// desativada.
  static const _paletas = <List<Color>>[
    [Color(0xFFF6821F), Color(0xFF9A4A05)], // laranja da casa
    [Color(0xFFE3271E), Color(0xFF8A1410)], // vermelho no ar
    [Color(0xFF6E56CF), Color(0xFF3A2A78)], // roxo
    [Color(0xFF22A06B), Color(0xFF11543A)], // verde
    [Color(0xFF1E4FD8), Color(0xFF0F2A78)], // azul
    [Color(0xFFD6336C), Color(0xFF7A1C3D)], // magenta
    [Color(0xFF0E8A9E), Color(0xFF064652)], // teal
    [Color(0xFFB8860B), Color(0xFF6B4E06)], // âmbar
  ];

  /// Hash simples, escrito à mão e por isso estável entre versões do app.
  ///
  /// O multiplicador primo importa: somar os códigos das letras fazia "Tadeu Correa",
  /// "Milena Barros" e "Maicon Sales" caírem todos na mesma cor, porque nomes de
  /// tamanho parecido somam parecido. Com o `31 *` a distribuição abre.
  int get _semente {
    var s = 0;
    for (final c in nome.trim().toLowerCase().codeUnits) {
      s = (s * 31 + c) % 1000003;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final limpo = nome.trim();
    final cores = _paletas[_semente % _paletas.length];
    // A silhueta é uma só. A primeira versão tinha quatro — cabelo curto, longo, boné,
    // barba — e a 32 px nenhuma delas se lia: viravam riscos aleatórios sobre a
    // cabeça. Um desenho limpo e igual para todos, com a cor fazendo a distinção, é
    // mais elegante e muito mais legível no tamanho em que a coisa é realmente vista.
    final avatar = Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cores,
        ),
        shape: BoxShape.circle,
        border: anel == null ? null : Border.all(color: anel!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagemUrl != null && imagemUrl!.isNotEmpty
          ? Image.network(
              imagemUrl!,
              fit: BoxFit.cover,
              // Centro, e não um deslocamento esperto.
              //
              // A primeira versão puxava o enquadramento para cima, supondo que a foto
              // viesse em retrato com o rosto no terço superior. Errado: as fotos são
              // preparadas quadradas e já centradas no rosto — deslocar por cima disso
              // só revelava a borda de baixo do arquivo. Quem decide o corte é quem
              // prepara a imagem, e o app respeita.
              alignment: Alignment.center,
              // Enquanto a foto não chega, a silhueta ocupa o lugar — e não um quadrado
              // cinza piscando.
              loadingBuilder: (_, filho, progresso) =>
                  progresso == null ? filho : const _Silhueta(),
              errorBuilder: (_, __, ___) => const _Silhueta(),
            )
          : const _Silhueta(),
    );

    // O nome vai junto para o leitor de tela: silhueta não se lê em voz alta.
    return Semantics(label: limpo.isEmpty ? 'Locutor' : limpo, child: avatar);
  }
}

/// A silhueta, desenhada e não empacotada.
///
/// Vetor puro custa zero byte de download e fica nítido em qualquer densidade de tela —
/// importante num app que precisa rodar em Android antigo sem pesar.
class _Silhueta extends StatelessWidget {
  const _Silhueta();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _PintorSilhueta(), size: Size.infinite);
}

class _PintorSilhueta extends CustomPainter {
  const _PintorSilhueta();

  @override
  void paint(Canvas canvas, Size size) {
    final l = size.width;
    // Branco translúcido em vez de branco puro: a silhueta pertence ao fundo, não
    // flutua sobre ele.
    final tinta = Paint()..color = Colors.white.withValues(alpha: .88);

    // Ombros: um arco largo que nasce fora do círculo, para não deixar canto vazio
    // nas laterais quando o avatar é recortado em círculo.
    final ombros = Path()
      ..moveTo(l * .04, l * 1.02)
      ..cubicTo(l * .06, l * .70, l * .28, l * .62, l * .5, l * .62)
      ..cubicTo(l * .72, l * .62, l * .94, l * .70, l * .96, l * 1.02)
      ..close();
    canvas.drawPath(ombros, tinta);

    // Cabeça: um pouco acima do centro, com folga entre ela e os ombros — é essa
    // folga que faz a forma ser lida como pessoa e não como cogumelo.
    canvas.drawCircle(Offset(l * .5, l * .38), l * .175, tinta);
  }

  @override
  bool shouldRepaint(covariant _PintorSilhueta antigo) => false;
}

/// A equipe do programa, em avatares levemente sobrepostos.
///
/// A sobreposição não é enfeite: lê como "essas pessoas estão juntas no ar", enquanto
/// avatares separados leem como uma lista de nomes.
class EquipeNoAr extends StatelessWidget {
  final List<Map<String, dynamic>> locutores;
  final double tamanho;
  const EquipeNoAr({super.key, required this.locutores, this.tamanho = 30});

  @override
  Widget build(BuildContext context) {
    if (locutores.isEmpty) return const SizedBox.shrink();
    final passo = tamanho * .7;
    return SizedBox(
      height: tamanho,
      width: tamanho + (locutores.length - 1) * passo,
      child: Stack(
        children: List.generate(locutores.length, (i) {
          final l = locutores[i];
          return Positioned(
            left: i * passo,
            child: AvatarLocutor(
              nome: l['nome']?.toString() ?? '',
              imagemUrl: l['imagemUrl']?.toString(),
              tamanho: tamanho,
              anel: BandFMColors.bg,
            ),
          );
        }),
      ),
    );
  }
}
