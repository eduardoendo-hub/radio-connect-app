import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';

/// 01 · Entrada.
///
/// Cadastro mínimo — o suficiente para garantir voto único, Índice de Conexão e
/// participação em promoções. Nada além disso.
///
/// O conteúdo fica alinhado à base, com o degradê quente subindo do logo: a marca da
/// rádio ocupa a tela antes de qualquer campo. **White-label total** — nenhuma menção
/// ao Radio Connect ou à TechNow em canto nenhum.
class TelaEntrada extends StatefulWidget {
  final VoidCallback aoEntrar;
  const TelaEntrada({super.key, required this.aoEntrar});

  @override
  State<TelaEntrada> createState() => _TelaEntradaState();
}

class _TelaEntradaState extends State<TelaEntrada> {
  final _telefone = TextEditingController();
  final _codigo = TextEditingController();
  bool _pedindoCodigo = false;
  bool _ocupado = false;
  bool _modoDemo = false;
  String? _erro;

  @override
  void dispose() {
    _telefone.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _pedirCodigo() async {
    // Valida antes de ir ao servidor: se o campo está vazio, a pessoa precisa saber
    // disso e não receber uma mensagem genérica de dados inválidos.
    final numero = _telefone.text.replaceAll(RegExp(r'\D'), '');
    if (numero.length < 10) {
      setState(() => _erro = 'Digite seu telefone com DDD, só números.');
      return;
    }
    setState(() { _ocupado = true; _erro = null; });
    try {
      final r = await Api.enviar('/auth/codigo', {'telefone': _telefone.text});
      setState(() {
        _pedindoCodigo = true;
        _modoDemo = r['modoDemo'] == true;
        if (_modoDemo) _codigo.text = '000000';
      });
    } on ErroApi catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _entrar() async {
    if (_codigo.text.trim().length < 6) {
      setState(() => _erro = 'Digite os 6 números do código.');
      return;
    }
    setState(() { _ocupado = true; _erro = null; });
    try {
      final r = await Api.enviar('/auth/entrar', {
        'telefone': _telefone.text,
        'codigo': _codigo.text,
      });
      await Api.guardarToken(r['token'].toString());
      widget.aoEntrar();
    } on ErroApi catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BandFMColors.bg,
      body: Container(
        // O calor sobe do topo e morre no preto: a marca antes do formulário.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF57310F), Color(0xFF0A0A0A)],
            stops: [0.0, 0.58],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 46),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo-emissora.webp', width: 220, fit: BoxFit.contain),
                    const SizedBox(height: BandFMSpacing.x5),
                    const Text(
                      'Essa é a sua rádio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Entre para participar dos Momentos, falar com a\ngente e concorrer às promoções.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, height: 1.5, color: BandFMColors.textSecondary),
                    ),
                    const SizedBox(height: BandFMSpacing.x5),

                    if (!_pedindoCodigo) ...[
                      _campo(
                        controlador: _telefone,
                        dica: 'Seu telefone com DDD',
                        icone: Symbols.smartphone,
                        teclado: TextInputType.phone,
                        aoEnviar: _pedirCodigo,
                      ),
                      const SizedBox(height: BandFMSpacing.x3),
                      FilledButton(
                        onPressed: _ocupado ? null : _pedirCodigo,
                        child: Text(_ocupado ? 'Enviando…' : 'Continuar'),
                      ),
                      const SizedBox(height: 10),
                      // Segundo caminho, sem peso visual de igual — o telefone é o
                      // principal porque é o que a rádio já usa para falar com o ouvinte.
                      OutlinedButton(
                        onPressed: _ocupado ? null : () {},
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                          side: const BorderSide(color: Color(0x33FFFFFF)),
                          foregroundColor: BandFMColors.textPrimary,
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Continuar com Google'),
                      ),
                    ] else ...[
                      Text(
                        'Enviamos um código para ${_telefone.text}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: BandFMColors.textSecondary),
                      ),
                      const SizedBox(height: BandFMSpacing.x3),
                      _campo(
                        controlador: _codigo,
                        dica: '000000',
                        teclado: TextInputType.number,
                        centralizado: true,
                        aoEnviar: _entrar,
                        maxLength: 6,
                      ),
                      if (_modoDemo)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Demonstração: o código é 000000',
                              style: TextStyle(fontSize: 12, color: BandFMColors.textTertiary)),
                        ),
                      const SizedBox(height: BandFMSpacing.x3),
                      FilledButton(
                        onPressed: _ocupado ? null : _entrar,
                        child: Text(_ocupado ? 'Entrando…' : 'Entrar'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _pedindoCodigo = false),
                        child: const Text('Trocar o número',
                            style: TextStyle(color: BandFMColors.textSecondary)),
                      ),
                    ],

                    if (_erro != null) ...[
                      const SizedBox(height: BandFMSpacing.x3),
                      Text(_erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFFF9A95), fontSize: 13.5)),
                    ],

                    const SizedBox(height: BandFMSpacing.x4),
                    const Text(
                      'Só pedimos o essencial agora.\nO resto a gente pergunta depois.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: BandFMColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controlador,
    required String dica,
    IconData? icone,
    TextInputType? teclado,
    bool centralizado = false,
    int? maxLength,
    VoidCallback? aoEnviar,
  }) {
    return TextField(
      controller: controlador,
      keyboardType: teclado,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: maxLength,
      textAlign: centralizado ? TextAlign.center : TextAlign.start,
      onSubmitted: (_) => aoEnviar?.call(),
      style: TextStyle(
        fontSize: centralizado ? 22 : 15.5,
        letterSpacing: centralizado ? 8 : -.1,
        fontWeight: centralizado ? FontWeight.w700 : FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: dica,
        counterText: '',
        hintStyle: const TextStyle(color: BandFMColors.textTertiary, fontWeight: FontWeight.w400),
        prefixIcon: icone == null
            ? null
            : Icon(icone, size: 20, color: BandFMColors.textTertiary),
        filled: true,
        fillColor: BandFMColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BandFMRadii.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BandFMRadii.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BandFMRadii.lg),
          borderSide: const BorderSide(color: BandFMColors.orange, width: 1.5),
        ),
      ),
    );
  }
}
