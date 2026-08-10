import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';

/// Os dados de quem ouve.
///
/// **A rádio só pede isto por causa das promoções**, e a tela diz isso em voz alta. Um
/// aplicativo de rádio que pede CPF sem explicar por quê é um aplicativo que a pessoa
/// fecha — e ela tem razão. Concorrer a prêmio tem regulamento, tem maioridade e tem
/// prêmio para entregar; ouvir rádio não tem nada disso e continua não pedindo nada.
///
/// O CPF se escreve uma vez. Depois some atrás de uma máscara, porque a pessoa não
/// precisa reler o próprio CPF na tela: precisa saber que a rádio já tem.
class TelaSeusDados extends StatefulWidget {
  /// Quando vem da promoção, a tela explica o que falta e volta sozinha ao terminar.
  final String? porque;
  const TelaSeusDados({super.key, this.porque});

  @override
  State<TelaSeusDados> createState() => _TelaSeusDadosState();
}

class _TelaSeusDadosState extends State<TelaSeusDados> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _cidade = TextEditingController();
  final _cpf = TextEditingController();
  final _nascimento = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  bool _temCpf = false;
  String? _cpfMascarado;
  String? _telefone;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    for (final c in [_nome, _email, _cidade, _cpf, _nascimento]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final r = await Api.obter('/perfil');
      final p = (r['perfil'] as Map).cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        _nome.text = p['nome']?.toString() ?? '';
        _email.text = p['email']?.toString() ?? '';
        _cidade.text = p['cidade']?.toString() ?? '';
        _telefone = p['telefone']?.toString();
        _temCpf = p['temCpf'] == true;
        _cpfMascarado = p['cpf']?.toString();
        final n = p['dataNascimento']?.toString();
        if (n != null && n.length == 10) {
          _nascimento.text = '${n.substring(8)}/${n.substring(5, 7)}/${n.substring(0, 4)}';
        }
        _carregando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() { _salvando = true; _erro = null; });
    try {
      final nascimento = _nascimento.text.trim();
      await Api.enviar('/perfil', {
        if (_nome.text.trim().isNotEmpty) 'nome': _nome.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        if (_cidade.text.trim().isNotEmpty) 'cidade': _cidade.text.trim(),
        if (!_temCpf && _cpf.text.trim().isNotEmpty) 'cpf': _cpf.text.trim(),
        // "02/03/1985" na tela, "1985-03-02" no fio. Ninguém digita ano primeiro.
        if (nascimento.length == 10)
          'dataNascimento':
              '${nascimento.substring(6)}-${nascimento.substring(3, 5)}-${nascimento.substring(0, 2)}',
      }, metodo: 'PATCH');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ErroApi ? e.mensagem : 'Não deu para salvar agora.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BandFMColors.bg,
      appBar: AppBar(
        backgroundColor: BandFMColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Seus dados',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: BandFMColors.orange))
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  BandFMSpacing.screenPadding, 8, BandFMSpacing.screenPadding, 40),
              children: [
                // Por que a rádio está pedindo. Sempre, não só quando vem da promoção.
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: BandFMColors.orange.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(BandFMRadii.md),
                    border: Border.all(color: BandFMColors.orange.withValues(alpha: .25)),
                  ),
                  child: Text(
                    widget.porque ??
                        'A rádio precisa destes dados para você concorrer às promoções. '
                            'Sorteio tem regulamento, tem idade mínima e tem prêmio para entregar.',
                    style: const TextStyle(
                        fontSize: 13, height: 1.45, color: BandFMColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 22),

                _campoTelefone(),
                _campo('Nome completo', _nome, teclado: TextInputType.name),
                _campo('E-mail', _email, teclado: TextInputType.emailAddress),
                _campo('Cidade', _cidade),
                _campoNascimento(),
                _campoCpf(),

                if (_erro != null) ...[
                  const SizedBox(height: 14),
                  Text(_erro!, style: const TextStyle(fontSize: 13.5, color: Color(0xFFFF9A95))),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  style: FilledButton.styleFrom(
                    backgroundColor: BandFMColors.orange,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BandFMRadii.pill)),
                  ),
                  child: Text(_salvando ? 'Salvando…' : 'Salvar',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),

                const SizedBox(height: 34),
                _apagar(),
              ],
            ),
    );
  }

  Widget _campo(String rotulo, TextEditingController controle,
          {TextInputType? teclado, List<TextInputFormatter>? formato, String? dica}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rotulo.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 1.2, color: BandFMColors.textTertiary)),
          const SizedBox(height: 7),
          TextField(
            controller: controle,
            keyboardType: teclado,
            inputFormatters: formato,
            style: const TextStyle(fontSize: 15.5, color: Colors.white),
            decoration: InputDecoration(
              hintText: dica,
              hintStyle: const TextStyle(color: BandFMColors.textTertiary, fontSize: 15),
              filled: true,
              fillColor: BandFMColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(BandFMRadii.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ]),
      );

  Widget _campoNascimento() => _campo(
        'Data de nascimento', _nascimento,
        teclado: TextInputType.number,
        dica: 'dd/mm/aaaa',
        formato: [FilteringTextInputFormatter.digitsOnly, _MascaraData()],
      );

  /// O telefone é a conta, não um dado do cadastro.
  ///
  /// É por ele que a pessoa entra — o código chega nele — e é ele que identifica o
  /// ouvinte na emissora. Deixar trocar aqui seria deixar trocar a fechadura pelo lado
  /// de dentro: digitar o número de outra pessoa e virar ela, ou digitar errado e
  /// perder o próprio acesso na próxima entrada. Trocar de número existe, mas é um
  /// caminho com código no número novo — não um campo de formulário.
  ///
  /// Vem primeiro na tela de propósito: é a âncora do resto.
  Widget _campoTelefone() {
    if (_telefone == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('TELEFONE',
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800,
                letterSpacing: 1.2, color: BandFMColors.textTertiary)),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: BandFMColors.surface,
            borderRadius: BorderRadius.circular(BandFMRadii.md),
          ),
          child: Row(children: [
            Text(_telefone!,
                style: const TextStyle(fontSize: 15.5, color: BandFMColors.textSecondary)),
            const Spacer(),
            const Icon(Symbols.lock, size: 16, color: BandFMColors.textTertiary),
          ]),
        ),
        const SizedBox(height: 6),
        const Text('É por ele que você entra no aplicativo. Para trocar, fale com a rádio.',
            style: TextStyle(fontSize: 11.5, color: BandFMColors.textTertiary)),
      ]),
    );
  }

  /// O CPF se escreve uma vez.
  ///
  /// Depois vira máscara e um cadeado. Não é rigidez: CPF não muda na vida de ninguém,
  /// e deixar trocar abriria o caminho mais óbvio de concorrer duas vezes — concorro,
  /// troco o CPF, concorro de novo.
  Widget _campoCpf() {
    if (_temCpf) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('CPF',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 1.2, color: BandFMColors.textTertiary)),
          const SizedBox(height: 7),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: BandFMColors.surface,
              borderRadius: BorderRadius.circular(BandFMRadii.md),
            ),
            child: Row(children: [
              Text(_cpfMascarado ?? '',
                  style: const TextStyle(fontSize: 15.5, color: BandFMColors.textSecondary)),
              const Spacer(),
              const Icon(Symbols.lock, size: 16, color: BandFMColors.textTertiary),
            ]),
          ),
          const SizedBox(height: 6),
          const Text('Se estiver errado, fale com a rádio pelo chat.',
              style: TextStyle(fontSize: 11.5, color: BandFMColors.textTertiary)),
        ]),
      );
    }
    return _campo('CPF', _cpf,
        teclado: TextInputType.number,
        dica: '000.000.000-00',
        formato: [FilteringTextInputFormatter.digitsOnly, _MascaraCpf()]);
  }

  /// O caminho de volta.
  ///
  /// Se a rádio pede CPF, precisa existir o botão que apaga — e ele apaga de verdade,
  /// com as participações junto. Fica no fim da tela, discreto e sem cor de alarme: é um
  /// direito, não uma ameaça.
  Widget _apagar() => Center(
        child: TextButton(
          onPressed: () async {
            final confirmou = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                backgroundColor: BandFMColors.surface,
                title: const Text('Apagar seus dados?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                content: const Text(
                  'Some tudo: seu cadastro e as promoções em que você entrou. '
                  'Não dá para desfazer, e você sai do aplicativo.',
                  style: TextStyle(fontSize: 14, height: 1.45, color: BandFMColors.textSecondary),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                  TextButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Apagar', style: TextStyle(color: Color(0xFFFF9A95))),
                  ),
                ],
              ),
            );
            if (confirmou != true || !mounted) return;
            try {
              await Api.enviar('/perfil', {}, metodo: 'DELETE');
              if (!mounted) return;
              await Api.sair();
              if (!mounted) return;
              Navigator.of(context).popUntil((r) => r.isFirst);
            } catch (_) {
              if (mounted) setState(() => _erro = 'Não deu para apagar agora.');
            }
          },
          child: const Text('Apagar meus dados',
              style: TextStyle(fontSize: 13, color: BandFMColors.textTertiary)),
        ),
      );
}

/// "02031985" vira "02/03/1985" enquanto se digita.
class _MascaraData extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antes, TextEditingValue depois) {
    final d = depois.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length && i < 8; i++) {
      if (i == 2 || i == 4) b.write('/');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

/// "11144477735" vira "111.444.777-35" enquanto se digita.
class _MascaraCpf extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue antes, TextEditingValue depois) {
    final d = depois.text.replaceAll(RegExp(r'\D'), '');
    final b = StringBuffer();
    for (var i = 0; i < d.length && i < 11; i++) {
      if (i == 3 || i == 6) b.write('.');
      if (i == 9) b.write('-');
      b.write(d[i]);
    }
    final t = b.toString();
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}
