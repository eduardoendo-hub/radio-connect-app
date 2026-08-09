import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';
import '../widgets/assinatura_patrocinio.dart';

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
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ErroApi ? e.mensagem : 'Não deu para inscrever agora.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = {...widget.promocao, ...?_completa};
    final imagem = p['imagemUrl']?.toString();
    final regras = p['regras']?.toString();
    final sorteio = DateTime.tryParse(p['sorteioEm']?.toString() ?? '');
    final total = (p['total'] as num?)?.toInt();

    return Scaffold(
      backgroundColor: BandFMColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: imagem != null && imagem.isNotEmpty ? 260 : 0,
          pinned: true,
          backgroundColor: BandFMColors.bg,
          leading: IconButton(
            icon: const Icon(Symbols.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
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
              if (sorteio != null) _linha(Symbols.event, 'Sorteio', _quando(sorteio)),
              if (total != null && total > 0)
                _linha(Symbols.group, 'Já estão concorrendo',
                    '$total ${total == 1 ? 'ouvinte' : 'ouvintes'}'),

              const SizedBox(height: 22),
              _acao(sorteio),
              if (_erro != null) ...[
                const SizedBox(height: 10),
                Text(_erro!, style: const TextStyle(fontSize: 13.5, color: Color(0xFFFF9A95))),
              ],

              if (AssinaturaPatrocinio.talvez(p['patrocinio']) != null) ...[
                const SizedBox(height: 20),
                AssinaturaPatrocinio.talvez(p['patrocinio'])!,
              ],

              if (regras != null && regras.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('REGULAMENTO',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800,
                        letterSpacing: 1.3, color: BandFMColors.textTertiary)),
                const SizedBox(height: 9),
                Text(regras,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.6, color: BandFMColors.textTertiary)),
              ],
            ]),
          ),
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

  Widget _acao(DateTime? sorteio) {
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
                    ? 'Deixe o rádio ligado: o nome sai ${_quando(sorteio)}, ao vivo.'
                    : 'O resultado sai ao vivo, com o locutor.',
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: BandFMColors.textSecondary),
              ),
            ]),
          ),
        ]),
      );
    }

    return FilledButton(
      onPressed: _enviando ? null : _participar,
      style: FilledButton.styleFrom(
        backgroundColor: BandFMColors.orange,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BandFMRadii.pill)),
      ),
      child: Text(_enviando ? 'Inscrevendo…' : 'Quero participar',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }

  static const _dias = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];

  String _quando(DateTime d) {
    final hoje = DateTime.now();
    final mesmoDia = d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
    final hora = d.minute == 0 ? '${d.hour}h' : '${d.hour}h${d.minute.toString().padLeft(2, '0')}';
    return mesmoDia ? 'hoje às $hora' : '${_dias[d.weekday - 1]} às $hora';
  }
}
