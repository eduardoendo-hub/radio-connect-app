import 'package:flutter_test/flutter_test.dart';
import 'package:radio_connect/tema.dart';

void main() {
  test('a paleta da emissora segue o design system', () {
    // Laranja Band FM — cor de marca do tenant.
    expect(BandFMColors.orange.toARGB32(), 0xFFF6821F);
    // O vermelho do NO AR é reservado: significa "acontecendo agora" e mais nada.
    expect(BandFMColors.live.toARGB32(), 0xFFFF3B30);
    expect(BandFMColors.liveDot.toARGB32(), 0xFFFF1F14);
  });

  test('o texto terciário não foi escurecido além do aprovado', () {
    // #949494 é o mínimo que passa WCAG AA sobre o fundo. Escurecer quebra contraste.
    expect(BandFMColors.textTertiary.toARGB32(), 0xFF949494);
  });

  test('o alvo de toque mínimo é 44', () {
    // Vale mais aqui que em qualquer app: a pessoa pode estar dirigindo.
    expect(BandFMSpacing.minTouchTarget, 44.0);
  });
}
