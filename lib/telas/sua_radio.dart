import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';
import '../tempo.dart';
import '../widgets/comuns.dart';
import '../widgets/escada_conexao.dart';
import 'promocao.dart';
import 'seus_dados.dart';
import '../estado_no_ar.dart';

/// 08 · Sua Rádio.
///
/// **Não é um perfil.** É o relacionamento do ouvinte com aquela emissora — a memória
/// da relação, não os dados da pessoa.
///
/// O Índice de Conexão aparece em **linguagem, nunca como número frio**: "Muito forte",
/// não "82 pontos". Sem ranking público e sem gamificação infantil.
///
/// **Tudo aqui vem do banco.** A primeira versão trazia "3h20 de escuta nesta semana" e
/// "12 Momentos no mês" escritos no código — o produto nunca mediu tempo de escuta e
/// ninguém contava Momentos. Numa tela que a pessoa lê como sendo sobre ela, número
/// inventado é a pior coisa que se pode pôr: no dia em que ela reparar que o número não
/// muda, tudo o mais aqui vira suspeito.
///
/// Tempo de escuta não voltou como zero — voltou como nada. A rádio toca no chuveiro e
/// no carro, e este aplicativo não tem como contar isso.
class TelaSuaRadio extends StatefulWidget {
  final String? nome;
  const TelaSuaRadio({super.key, this.nome});

  @override
  State<TelaSuaRadio> createState() => _TelaSuaRadioState();
}

class _TelaSuaRadioState extends State<TelaSuaRadio> {
  List<Map<String, dynamic>> _promocoes = [];
  Map<String, dynamic>? _conexao;
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
      // As duas juntas: a tela só faz sentido inteira, e são duas viagens de rede que
      // não dependem uma da outra.
      final r = await Future.wait([
        Api.obter('/promocoes'),
        Api.obter('/minha-conexao'),
      ]);
      if (!mounted) return;
      setState(() {
        _promocoes = ((r[0]['promocoes'] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _conexao = r[1];
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// "Ouvinte desde março de 2026" — a partir da data real do cadastro.
  ///
  /// Antes era texto fixo. Quem baixasse o aplicativo hoje leria que é ouvinte desde
  /// março, o que é uma frase simpática e mentirosa sobre a própria pessoa.
  String _desde() {
    final d = instante(_conexao?['desde']);
    if (d == null) {
      return EstadoNoAr.nome.isEmpty ? 'Ouvinte' : 'Ouvinte da ${EstadoNoAr.nome}';
    }
    const meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    final agora = DateTime.now();
    // Quem chegou esta semana não é "ouvinte desde agosto de 2026" — soa a piada de mau
    // gosto com quem acabou de instalar o aplicativo.
    if (agora.difference(d).inDays < 30) return 'Chegou agora — seja bem-vindo';
    return 'Ouvinte desde ${meses[d.month - 1]} de ${d.year}';
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
              Text(_desde(),
                  style: const TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
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
        // Só depois de saber. Desenhar a escada em "Descobrindo" enquanto carrega faria
        // quem é Embaixador ver a si mesmo no primeiro degrau por um segundo — e
        // informação errada sobre a própria pessoa não fica menos errada por ser breve.
        if (_conexao != null)
          EscadaConexao(
            nivel: (_conexao!['nivel'] as num?)?.toInt() ?? 0,
            porque: ((_conexao!['porque'] as List?) ?? const [])
                .map((e) => e.toString())
                .toList(),
            degraus: ((_conexao!['degraus'] as List?) ?? const [])
                .map((e) => e.toString())
                .toList(),
          )
        else
          const SizedBox(height: 128),

        // Os dois números só aparecem quando existem. Um "0" grande em negrito na tela
        // da própria relação não informa nada: acusa. Quem ainda não participou lê o
        // convite na escada acima, que é o recado certo para quem acabou de chegar.
        if (_cartoes.isNotEmpty) ...[
          const SizedBox(height: BandFMSpacing.x3),
          Row(children: [
            for (var i = 0; i < _cartoes.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _numero(_cartoes[i].$1, _cartoes[i].$2)),
            ],
          ]),
        ],

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

  int get _momentos => (_conexao?['momentosNoMes'] as num?)?.toInt() ?? 0;
  int get _promocoesContadas => (_conexao?['promocoes'] as num?)?.toInt() ?? 0;
  int get _minutos => (_conexao?['minutosNaSemana'] as num?)?.toInt() ?? 0;

  /// Os números que existem. No máximo dois, e só os que têm o que dizer.
  ///
  /// **Zero não vira cartão.** Um "0" grande em negrito na tela da própria relação não
  /// informa: acusa. Quem ainda não participou lê o convite na escada acima, que é o
  /// recado certo para quem acabou de chegar.
  ///
  /// Dois é o teto porque três cartões lado a lado num telefone viram três tiras
  /// ilegíveis — a mesma razão pela qual o quadro não aceita quatro opções.
  List<(String, String)> get _cartoes {
    final lista = <(String, String)>[];
    if (_minutos >= 60) {
      final horas = _minutos ~/ 60;
      lista.add(('${horas}h', horas == 1
          ? 'ouvida no aplicativo esta semana'
          : 'ouvidas no aplicativo esta semana'));
    }
    if (_momentos > 0) {
      lista.add(('$_momentos', _momentos == 1 ? 'Momento neste mês' : 'Momentos neste mês'));
    }
    if (_promocoesContadas > 0) {
      lista.add(('$_promocoesContadas', _promocoesContadas == 1
          ? 'promoção que você entrou'
          : 'promoções que você entrou'));
    }
    return lista.take(2).toList();
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
