import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../tema.dart';

/// Cadastro.
///
/// É a primeira barreira que o ouvinte encontra, e por isso precisa ser a mais curta que
/// a tecnologia permite: telefone e um código, dois toques. Nome, cidade e preferências
/// vêm depois, dentro da experiência.
///
/// A base cadastrada é o ativo do produto — é exatamente o que a emissora nunca teve
/// enquanto o relacionamento morava no WhatsApp.
class TelaEntrar extends StatefulWidget {
  final VoidCallback aoEntrar;
  const TelaEntrar({super.key, required this.aoEntrar});

  @override
  State<TelaEntrar> createState() => _TelaEntrarState();
}

class _TelaEntrarState extends State<TelaEntrar> {
  final _telefone = TextEditingController();
  final _codigo = TextEditingController();
  bool _codigoEnviado = false;
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
    setState(() { _ocupado = true; _erro = null; });
    try {
      final r = await Api.enviar('/auth/codigo', {'telefone': _telefone.text});
      setState(() {
        _codigoEnviado = true;
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
      backgroundColor: Tema.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espaco.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A marca é da RÁDIO. White-label total: nenhuma menção ao
                  // Radio Connect em nenhum canto do app do ouvinte.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: Tema.laranja,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.radio, color: Colors.white, size: 34),
                    ),
                  ),
                  const SizedBox(height: Espaco.lg),
                  const Text('Band FM',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: Espaco.xs),
                  const Text(
                    'Milhões de ouvintes.\nUma rádio só sua.',
                    style: TextStyle(fontSize: 16, color: Tema.texto2, height: 1.4),
                  ),
                  const SizedBox(height: Espaco.xl),

                  if (!_codigoEnviado) ...[
                    TextField(
                      controller: _telefone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 17),
                      decoration: _campo('Seu telefone com DDD', Icons.phone_outlined),
                      onSubmitted: (_) => _pedirCodigo(),
                    ),
                    const SizedBox(height: Espaco.md),
                    _botao(_ocupado ? 'Enviando…' : 'Continuar', _ocupado ? null : _pedirCodigo),
                  ] else ...[
                    Text(
                      'Enviamos um código para ${_telefone.text}',
                      style: const TextStyle(color: Tema.texto2, fontSize: 14),
                    ),
                    const SizedBox(height: Espaco.md),
                    TextField(
                      controller: _codigo,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 6,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8),
                      textAlign: TextAlign.center,
                      decoration: _campo('000000', null).copyWith(counterText: ''),
                      onSubmitted: (_) => _entrar(),
                    ),
                    if (_modoDemo)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('Demonstração: o código é 000000',
                            style: TextStyle(fontSize: 12, color: Tema.texto3)),
                      ),
                    const SizedBox(height: Espaco.md),
                    _botao(_ocupado ? 'Entrando…' : 'Entrar', _ocupado ? null : _entrar),
                    TextButton(
                      onPressed: () => setState(() => _codigoEnviado = false),
                      child: const Text('Trocar o número', style: TextStyle(color: Tema.texto2)),
                    ),
                  ],

                  if (_erro != null) ...[
                    const SizedBox(height: Espaco.md),
                    Text(_erro!,
                        style: const TextStyle(color: Color(0xFFFF9A95), fontSize: 13.5),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _campo(String dica, IconData? icone) => InputDecoration(
        hintText: dica,
        hintStyle: const TextStyle(color: Tema.texto3),
        prefixIcon: icone != null ? Icon(icone, color: Tema.texto3, size: 20) : null,
        filled: true,
        fillColor: Tema.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: Espaco.md, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Tema.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Tema.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Tema.laranja, width: 1.5),
        ),
      );

  Widget _botao(String texto, VoidCallback? aoTocar) => SizedBox(
        height: 54,
        child: FilledButton(
          onPressed: aoTocar,
          style: FilledButton.styleFrom(
            backgroundColor: Tema.laranja,
            disabledBackgroundColor: Tema.laranja.withValues(alpha: .4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(texto,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      );
}
