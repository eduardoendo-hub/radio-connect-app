import 'package:flutter/material.dart';

/// A identidade da emissora.
///
/// O app é **white-label total**: o ouvinte vê Band FM, nunca Radio Connect. Estas cores
/// são o padrão de fábrica da Band FM, amostradas dos pixels do deck da proposta.
///
/// Em produção elas vêm do servidor, na camada `tema` da configuração do tenant — é isso
/// que permite trocar a cara de uma rádio sem passar pela loja. Aqui ficam como valor
/// inicial, usado enquanto o app ainda não recebeu a configuração.
class Tema {
  static const laranja = Color(0xFFF6821F); // primária Band FM
  static const laranjaForte = Color(0xFFD96D13);

  /// Fundo neutro, sem o viés esverdeado do Studio. É de propósito: aqui a cor da
  /// rádio precisa dominar.
  static const fundo = Color(0xFF0B0B0C);
  static const superficie = Color(0xFF151517);
  static const superficieAlta = Color(0xFF1E1E21);
  static const borda = Color(0xFF2A2A2E);

  /// Reservado. Significa "acontecendo agora" e mais nada — nunca erro, nunca exclusão.
  static const aoVivo = Color(0xFFE3271E);

  static const texto = Color(0xFFFFFFFF);
  static const texto2 = Color(0xFF9A9AA0);
  static const texto3 = Color(0xFF63636B);

  static ThemeData montar() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: fundo,
      colorScheme: base.colorScheme.copyWith(
        primary: laranja,
        surface: superficie,
        onPrimary: Colors.white,
      ),
      textTheme: base.textTheme.apply(bodyColor: texto, displayColor: texto),
    );
  }
}

/// Espaçamentos — poucos valores, usados com consistência.
class Espaco {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 34.0;
}
