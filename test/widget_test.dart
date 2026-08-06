import 'package:flutter_test/flutter_test.dart';
import 'package:radio_connect/tema.dart';

void main() {
  test('a paleta da emissora está definida', () {
    // O vermelho é reservado: significa "acontecendo agora" e mais nada.
    expect(Tema.aoVivo.toARGB32(), 0xFFE3271E);
    // Laranja Band FM, amostrado dos pixels do deck da proposta.
    expect(Tema.laranja.toARGB32(), 0xFFF6821F);
  });

  test('o fundo do app é neutro, sem o viés verde do Studio', () {
    // São públicos opostos: aqui a cor da rádio precisa dominar.
    expect(Tema.fundo.toARGB32(), 0xFF0B0B0C);
  });
}
