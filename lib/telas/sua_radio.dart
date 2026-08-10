import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';
import '../tempo.dart';
import '../widgets/comuns.dart';
import '../widgets/escada_conexao.dart';
import 'promocao.dart';
import 'seus_dados.dart';

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
class TelaSuaRadio extends StatefulWidget {
  final String? nome;
  const TelaSuaRadio({super.key, this.nome});

  @override
  State<TelaSuaRadio> createState() => _TelaSuaRadioState();
}

class _TelaSuaRadioState extends State<TelaSuaRadio> {
  List<Map<String, dynamic>> _promocoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  /// As promoções desta pessoa.
  ///
  /// Aqui é a memória da relação, então a lista é de participações e não de promoções
  /// no ar: o que importa é o que **ela** fez. Em andamento primeiro, encerradas
  /// depois — o que ainda pode acontecer vale mais que o que já passou.
  Future<void> _carregar() async {
    try {
      final r = await Api.obter('/promocoes');
      if (!mounted) return;
      setState(() {
        _promocoes = ((r['promocoes'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primeiroNome = (widget.nome ?? 'Ouvinte').split(' ').first;

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
          // A engrenagem levava a lugar nenhum. Agora leva aos dados — que é a única
          // coisa que a pessoa tem para configurar neste aplicativo, e o lugar de onde
          // ela apaga tudo se quiser.
          IconButton(
            icon: const Icon(Symbols.settings, size: 22, color: BandFMColors.textTertiary),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TelaSeusDados()))
                .then((_) => _carregar()),
          ),
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

        // Só existe o bloco se a pessoa participou de alguma coisa. Título com vazio
        // embaixo anuncia uma falta — e nesta tela, que é a da relação, isso é o pior
        // recado possível para quem acabou de chegar.
        if (!_carregando && _promocoes.isNotEmpty) ...[
          const SizedBox(height: BandFMSpacing.x5),
          const TituloBloco('Suas promoções'),
          for (var i = 0; i < _promocoes.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _promocao(_promocoes[i]),
          ],
        ],
      ],
    );
  }

  /// Uma participação. A arte da promoção vira a miniatura — é por ela que a pessoa
  /// reconhece, não por um ícone genérico igual para todas.
  Widget _promocao(Map<String, dynamic> p) {
    final encerrada = p['encerrada'] == true;
    final venci = p['venci'] == true;
    final sorteio = instante(p['sorteioEm']);
    final arte = p['imagemUrl']?.toString();

    final contemplado = p['resultado']?.toString();

    // "Encerrada" sozinho não diz nada a quem esperou o sorteio. Dizer quem levou é o
    // mínimo de retorno para quem participou — e é o que separa uma promoção de um
    // formulário que engoliu o cadastro da pessoa.
    final apoio = venci
        ? 'Você ganhou — a rádio entra em contato'
        : contemplado != null && contemplado.isNotEmpty
            ? 'Quem levou foi $contemplado'
            : encerrada
                ? 'Encerrada · sem resultado'
                : sorteio != null
                    ? 'Concorrendo · sorteio ${quando(sorteio)}'
                    : 'Concorrendo';

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => TelaPromocao(promocao: p)))
          .then((_) => _carregar()),
      child: LinhaCartao(
        opacidade: encerrada && !venci ? .65 : 1,
        icone: arte != null && arte.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(BandFMRadii.md),
                child: Image.network(arte, width: 44, height: 44, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Arte(icone: Symbols.local_activity, tamanho: 44)),
              )
            : const Arte(icone: Symbols.local_activity, tamanho: 44),
        titulo: p['titulo']?.toString() ?? '',
        apoio: apoio,
        aDireita: const Icon(Symbols.chevron_right, size: 18, color: BandFMColors.textTertiary),
      ),
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
