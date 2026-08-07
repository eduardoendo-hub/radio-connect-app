import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../api.dart';
import '../tema.dart';

/// Fofocômetro — o gancho, a espera e a revelação.
///
/// Todos os outros Momentos pedem uma resposta e fecham em segundos. Este pede
/// **espera**: é o "depois do intervalo a gente conta" da rádio, que é o instrumento de
/// retenção mais antigo do meio e nunca tinha existido em tela.
///
/// Três decisões que sustentam o formato:
///
/// **A revelação não vem junto com o gancho.** O aplicativo recebe apenas o instante da
/// abertura e conta o tempo sozinho; o texto só é buscado quando o relógio zera. Se
/// viesse antes e ficasse escondido na tela, bastaria abrir a aba de rede para estragar
/// a surpresa de todo mundo — e um formato cuja graça é ninguém saber antes não
/// sobrevive a isso.
///
/// **O relógio é o protagonista.** Ele é grande, ocupa o meio do cartão e continua
/// correndo quando o app vai para segundo plano. É ele que segura.
///
/// **A revelação não some.** Depois de abrir, fica na tela e depois na aba Momentos,
/// onde entra fechada e abre ao toque. Quem chegou atrasado ainda consegue ler.
class CartaoFofocometro extends StatefulWidget {
  final Map<String, dynamic> momento;
  const CartaoFofocometro({super.key, required this.momento});

  @override
  State<CartaoFofocometro> createState() => _CartaoFofocometroState();
}

class _CartaoFofocometroState extends State<CartaoFofocometro> {
  Timer? _relogio;
  Duration _falta = Duration.zero;
  Map<String, dynamic>? _revelacao;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _tick();
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(CartaoFofocometro anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.momento['id'] != widget.momento['id']) {
      setState(() => _revelacao = null);
      _tick();
    }
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  DateTime? get _quando {
    final f = widget.momento['fofoca'] as Map<String, dynamic>?;
    return DateTime.tryParse(f?['revelarEm']?.toString() ?? '');
  }

  void _tick() {
    final q = _quando;
    if (q == null) return;
    final d = q.difference(DateTime.now());
    if (mounted) setState(() => _falta = d.isNegative ? Duration.zero : d);
    // Deu a hora: busca uma vez e para de tentar.
    if (d.isNegative && _revelacao == null && !_buscando) _revelar();
  }

  Future<void> _revelar() async {
    setState(() => _buscando = true);
    try {
      final r = await Api.obter('/momentos/${widget.momento['id']}/revelacao');
      if (mounted) setState(() => _revelacao = r['revelacao'] as Map<String, dynamic>?);
    } catch (_) {
      // Servidor ainda não considera a hora — relógios não batem ao milissegundo.
      // O próximo tique tenta de novo.
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final abriu = _revelacao != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BandFMColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // O nome do formato aparece sempre, e é ele que a pessoa aprende a
          // reconhecer: "o Fofocômetro vai abrir" vira expectativa de marca.
          Row(children: [
            const _Antena(),
            const SizedBox(width: 8),
            const Text('FOFOCÔMETRO',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    letterSpacing: 1.4, color: BandFMColors.orange)),
            const Spacer(),
            if (!abriu)
              Text(_formatado(_falta),
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700,
                      color: BandFMColors.textTertiary,
                      fontFeatures: [FontFeature.tabularFigures()])),
          ]),
          const SizedBox(height: 16),

          Text(widget.momento['titulo']?.toString() ?? '',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800,
                  height: 1.18, letterSpacing: -.6, color: Colors.white)),

          if (!abriu) ...[
            const SizedBox(height: 20),
            _contagem(),
          ] else ...[
            const SizedBox(height: 18),
            _aRevelacao(),
          ],
        ]),
      ),
    );
  }

  /// O relógio grande. É o produto, não um detalhe.
  Widget _contagem() => Center(
        child: Column(children: [
          Text(_formatado(_falta),
              style: const TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w800,
                  height: 1, letterSpacing: -1.5, color: BandFMColors.orange,
                  fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 7),
          const Text('para a gente contar',
              style: TextStyle(fontSize: 12.5, color: BandFMColors.textTertiary)),
        ]),
      );

  Widget _aRevelacao() {
    final texto = _revelacao?['texto']?.toString() ?? '';
    final img = _revelacao?['imagemUrl']?.toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (_, v, filho) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: filho),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 1, color: Colors.white.withValues(alpha: .09)),
        const SizedBox(height: 16),
        if (img != null && img.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(BandFMRadii.md),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(img, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(texto,
            style: const TextStyle(
                fontSize: 15.5, height: 1.5, color: BandFMColors.textPrimary)),
      ]),
    );
  }

  static String _formatado(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// A antena que pisca — o sinal de que tem coisa vindo.
class _Antena extends StatefulWidget {
  const _Antena();
  @override
  State<_Antena> createState() => _AntenaState();
}

class _AntenaState extends State<_Antena> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .4, end: 1).animate(_c),
        child: const Icon(Symbols.campaign, fill: 1, size: 15, color: BandFMColors.orange),
      );
}
