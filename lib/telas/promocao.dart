import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';
import '../tempo.dart';
import '../widgets/assinatura_patrocinio.dart';
import 'seus_dados.dart';

/// A promoção por inteiro.
///
/// Tela e não janela sobreposta, de propósito. Modal é para confirmar uma coisa só;
/// aqui há arte, prêmio, data de sorteio e **regulamento** — e regulamento de sorteio
/// precisa estar alcançável, não escondido atrás de um link que ninguém desenhou. Tela
/// também tem rota própria, que é o que permite compartilhar a promoção depois.
class TelaPromocao extends StatefulWidget {
  final Map<String, dynamic> promocao;
  const TelaPromocao({super.key, required this.promocao});

  @override
  State<TelaPromocao> createState() => _TelaPromocaoState();
}

class _TelaPromocaoState extends State<TelaPromocao> {
  Map<String, dynamic>? _completa;
  bool _participei = false;
  bool _venci = false;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final r = await Api.obter('/promocoes/${widget.promocao['id']}');
      if (!mounted) return;
      setState(() {
        _completa = (r['promocao'] as Map?)?.cast<String, dynamic>();
        _participei = r['participei'] == true;
        _venci = r['venci'] == true;
      });
    } catch (_) {
      // O cartão do No Ar já trouxe título, arte e chamada. Sem a chamada completa a
      // tela mostra o que tem em vez de um erro — o que falta é regulamento e total,
      // não o essencial.
    }
  }

  Future<void> _participar() async {
    if (_enviando) return;
    setState(() { _enviando = true; _erro = null; });
    try {
      await Api.enviar('/promocoes/${widget.promocao['id']}/participar', {});
      if (!mounted) return;
      setState(() => _participei = true);
      await _carregar();
    } on ErroApi catch (e) {
      if (!mounted) return;
      // **O cadastro incompleto não é erro: é um passo que falta.**
      //
      // Mostrar "faltam seus dados" e parar aí faria a pessoa procurar onde resolver —
      // e desistir no caminho. A tela dos dados abre na hora, já explicando o porquê, e
      // ao voltar a inscrição segue sozinha. Ela tocou em participar uma vez só.
      if (e.codigo == 'perfil_incompleto') {
        setState(() => _enviando = false);
        final preencheu = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => TelaSeusDados(porque: e.mensagem)),
        );
        if (preencheu == true && mounted) await _participar();
        return;
      }
      setState(() => _erro = e.mensagem);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não deu para inscrever agora.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Confere os dados antes de entrar no sorteio.
  ///
  /// É com estes dados que a rádio vai chamar a pessoa se ela ganhar, então ela precisa
  /// vê-los antes de aceitar — não depois, num e-mail de confirmação que ninguém lê. E
  /// é aqui que o "aceito o regulamento" acontece de verdade: nome, contato e regra na
  /// mesma tela, uma decisão só.
  Future<void> _confirmarEParticipar() async {
    Map<String, dynamic>? perfil;
    try {
      final r = await Api.obter('/perfil');
      perfil = (r['perfil'] as Map).cast<String, dynamic>();
      if (r['podeConcorrer'] != true) {
        if (!mounted) return;
        final preencheu = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => TelaSeusDados(porque: r['explicacao']?.toString()),
          ),
        );
        if (preencheu != true) return;
      }
    } catch (_) {
      // Sem perfil, tenta participar mesmo assim: o servidor recusa e o caminho de cima
      // abre a tela dos dados. Errar para o lado de deixar tentar é melhor que travar.
      await _participar();
      return;
    }

    if (!mounted) return;
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: BandFMColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => _folhaDeConfirmacao(c, perfil!),
    );
    if (confirmou == true) await _participar();
  }

  Widget _folhaDeConfirmacao(BuildContext c, Map<String, dynamic> perfil) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirme seus dados',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('É assim que a rádio vai te achar se você ganhar.',
                style: TextStyle(fontSize: 13.5, color: BandFMColors.textSecondary)),
            const SizedBox(height: 18),
            _dado('Nome', perfil['nome']?.toString()),
            _dado('E-mail', perfil['email']?.toString()),
            _dado('Telefone', perfil['telefone']?.toString()),
            _dado('CPF', perfil['cpf']?.toString()),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: BandFMColors.orange,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BandFMRadii.pill)),
                  ),
                  child: const Text('Confirmar e participar',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(c, false);
                  final mudou = await Navigator.of(context)
                      .push<bool>(MaterialPageRoute(builder: (_) => const TelaSeusDados()));
                  if (mudou == true && mounted) await _confirmarEParticipar();
                },
                child: const Text('Corrigir meus dados',
                    style: TextStyle(fontSize: 13, color: BandFMColors.textTertiary)),
              ),
            ),
          ]),
      );

  Widget _dado(String rotulo, String? valor) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Row(children: [
          SizedBox(
            width: 78,
            child: Text(rotulo,
                style: const TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
          ),
          Expanded(
            child: Text(valor ?? '—',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = {...widget.promocao, ...?_completa};
    final imagem = p['imagemUrl']?.toString();
    final regras = p['regras']?.toString();
    final sorteio = instante(p['sorteioEm']);
    final total = (p['total'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: BandFMColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: imagem != null && imagem.isNotEmpty ? 260 : 0,
          pinned: true,
          backgroundColor: BandFMColors.bg,
          // Voltar precisa ser desenhado, não herdado.
          //
          // A seta padrão é branca e some sobre a parte clara de uma foto qualquer — e
          // no navegador não existe o gesto de arrastar para voltar, então quem entra
          // aqui fica preso. A pastilha escura é a mesma linguagem do rótulo
          // "PROMOÇÃO NO AR" e lê sobre qualquer arte.
          // A seta vem de `Icons`, e não de `Symbols`.
          //
          // `Symbols.arrow_back` desenha vazio — o mesmo problema do ícone do quadro.
          // Já tentei fonte inteira sem tree-shaking e já tentei sem `fill`; nenhum
          // resolveu. Cheguei a corrigir isto uma vez e quebrei de novo ao reverter a
          // fonte, porque troquei os dois de volta em vez de só um.
          //
          // Fica com `Icons`, que é outra fonte, o aplicativo já carrega, e desenha.
          leadingWidth: 62,
          leading: Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38, height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
              ),
            ),
          ),
          flexibleSpace: imagem != null && imagem.isNotEmpty
              ? FlexibleSpaceBar(
                  background: Stack(fit: StackFit.expand, children: [
                    Image.network(imagem, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: BandFMColors.surface)),
                    // A mesma dobra do cartão: a foto derrete no fundo da tela em vez
                    // de terminar numa linha reta. Vale para qualquer arte que a
                    // emissora suba, inclusive a clara.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .35),
                            Colors.transparent,
                            BandFMColors.bg.withValues(alpha: .75),
                            BandFMColors.bg,
                          ],
                          stops: const [0, .35, .82, 1],
                        ),
                      ),
                    ),
                    if (p['seloUrl'] != null)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              color: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Image.network(
                                p['seloUrl'].toString(),
                                height: 40,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ]),
                )
              : null,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                BandFMSpacing.screenPadding, 4, BandFMSpacing.screenPadding, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PROMOÇÃO',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      letterSpacing: 1.3, color: BandFMColors.orange)),
              const SizedBox(height: 8),
              Text(p['titulo']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 27, fontWeight: FontWeight.w800, height: 1.15,
                      letterSpacing: -.6, color: Colors.white)),
              if (p['descricao'] != null) ...[
                const SizedBox(height: 10),
                Text(p['descricao'].toString(),
                    style: const TextStyle(
                        fontSize: 15, height: 1.45, color: BandFMColors.textSecondary)),
              ],

              const SizedBox(height: 20),
              if (sorteio != null) _linha(Symbols.event, 'Sorteio', quando(sorteio)),
              if (total != null && total > 0)
                _linha(Symbols.group, 'Já estão concorrendo',
                    '$total ${total == 1 ? 'ouvinte' : 'ouvintes'}'),

              // O regulamento vem ANTES do botão, e não num rodapé depois dele.
              //
              // Aceite que a pessoa não teve como ler não é aceite — é caixinha
              // marcada. Sorteio é promessa com regra, e a regra tem que estar na
              // frente de quem aceita, na mesma rolagem. Custa uma tela mais longa e
              // resolve o único problema que uma promoção mal feita cria de verdade.
              if (regras != null && regras.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text('REGULAMENTO',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        letterSpacing: 1.3, color: BandFMColors.textTertiary)),
                const SizedBox(height: 9),
                Text(regras,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.6, color: BandFMColors.textTertiary)),
              ],

              const SizedBox(height: 22),
              _acao(sorteio, temRegras: regras != null && regras.isNotEmpty),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, style: const TextStyle(fontSize: 13.5, color: Color(0xFFFF9A95))),
              ],

              if (AssinaturaPatrocinio.talvez(p['patrocinio']) != null) ...[
                const SizedBox(height: 20),
                AssinaturaPatrocinio.talvez(
                  p['patrocinio'],
                  posicao: 'assinatura_promocao',
                  referenciaId: p['id']?.toString(),
                )!,
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  /// O fecho.
  ///
  /// Promoção que termina em "concorrendo" nunca vira história. Aqui ela vira: ou a
  /// pessoa ganhou — e essa é a tela que ela mostra para os outros —, ou não ganhou, e
  /// o produto diz isso sem rodeio e agradece. Fingir que nada aconteceu seria pior.
  Widget _resultado(String contemplado) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _venci
            ? BandFMColors.orange.withValues(alpha: .14)
            : Colors.white.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(BandFMRadii.md),
        border: Border.all(
          color: _venci
              ? BandFMColors.orange.withValues(alpha: .45)
              : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(_venci ? Symbols.trophy : Symbols.campaign,
              size: 20, fill: 1,
              color: _venci ? BandFMColors.orange : BandFMColors.textTertiary),
          const SizedBox(width: 10),
          Text(_venci ? 'Você ganhou!' : 'Resultado',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: _venci ? Colors.white : BandFMColors.textSecondary)),
        ]),
        const SizedBox(height: 9),
        Text(
          _venci
              ? 'A rádio entra em contato pelo telefone do seu cadastro para combinar a entrega.'
              : 'Quem levou foi $contemplado. Obrigado por participar — tem mais vindo por aí.',
          style: const TextStyle(fontSize: 13.5, height: 1.45, color: BandFMColors.textSecondary),
        ),
      ]),
    );
  }

  Widget _linha(IconData icone, String rotulo, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(children: [
          Icon(icone, size: 18, color: BandFMColors.textTertiary),
          const SizedBox(width: 11),
          Text('$rotulo  ',
              style: const TextStyle(fontSize: 13.5, color: BandFMColors.textTertiary)),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ]),
      );

  Widget _acao(DateTime? sorteio, {required bool temRegras}) {
    final resultado = (_completa ?? widget.promocao)['resultado']?.toString();
    if (resultado != null && resultado.isNotEmpty) return _resultado(resultado);

    if (_participei) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: BandFMColors.orange.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(BandFMRadii.md),
          border: Border.all(color: BandFMColors.orange.withValues(alpha: .3)),
        ),
        child: Row(children: [
          const Icon(Symbols.check_circle, size: 22, fill: 1, color: BandFMColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Você está concorrendo',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 3),
              Text(
                sorteio != null
                    ? 'Deixe o rádio ligado: o nome sai ${quando(sorteio)}, ao vivo.'
                    : 'O resultado sai ao vivo, com o locutor.',
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: BandFMColors.textSecondary),
              ),
            ]),
          ),
        ]),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton(
        onPressed: _enviando ? null : _confirmarEParticipar,
        style: FilledButton.styleFrom(
          backgroundColor: BandFMColors.orange,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BandFMRadii.pill)),
        ),
        child: Text(
          _enviando ? 'Inscrevendo…' : (temRegras ? 'Aceitar e participar' : 'Quero participar'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      if (temRegras) ...[
        const SizedBox(height: 9),
        const Text(
          'Ao participar você concorda com o regulamento acima.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: BandFMColors.textTertiary),
        ),
      ],
    ]);
  }
}
