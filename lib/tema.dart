// Band FM — app do ouvinte (Radio Connect, white-label).
// Stack definida em uploads/03-arquitetura: Flutter.
// Estes valores são tenant-scoped: em outra emissora, só as cores de marca mudam.
import 'package:flutter/material.dart';

class BandFMColors {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF181818);
  static const surfaceRaised = Color(0xFF242424);
  static const miniPlayer = Color(0xFF2A1A0C);
  static const line = Color(0x12FFFFFF);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB3B3B3);
  static const textTertiary = Color(0xFF949494);
  static const textOnBrand = Color(0xFF000000);

  static const orange = Color(0xFFF6821F);      // cor da emissora (tenant)
  static const orangeStrong = Color(0xFFE56D0A);
  static const green = Color(0xFF3DB528);
  // O vermelho do ao vivo é claro e levemente coral, não vermelho puro.
  //
  // A primeira versão usava #FF1F14 — saturação máxima, sem nenhum verde nem azul.
  // Num fundo quase preto isso não lê como "acontecendo agora", lê como alarme: a cor
  // grita mais alto que o próprio programa. A segunda foi longe demais na direção
  // oposta e virou coral: bonito e sem urgência nenhuma.
  //
  // Aqui é o meio-termo, e é onde tem que ficar: vermelho de sangue, escuro o bastante
  // para não gritar e saturado o bastante para significar alguma coisa.
  //
  // O ponto continua um passo mais forte que o rótulo, porque é ele que pulsa: o
  // movimento chama o olho, então a cor não precisa fazer esse trabalho sozinha.
  static const live = Color(0xFFEE4A3F);        // rótulo NO AR
  static const liveDot = Color(0xFFE0342A);     // ponto pulsante

  static const momentGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF6821F), Color(0xFFB35708)],
  );
  static const playerGradient = LinearGradient(
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
    colors: [Color(0xFFB35708), Color(0xFF3A1D05), Color(0xFF0A0A0A)],
    stops: [0.0, 0.42, 1.0],
  );
}

class BandFMRadii {
  static const sm = 8.0, md = 12.0, lg = 14.0, card = 18.0, hero = 20.0, art = 10.0;
  static const bubble = 14.0, bubbleTail = 4.0, pill = 999.0;
}

class BandFMSpacing {
  static const x1 = 4.0, x2 = 8.0, x3 = 12.0, x4 = 16.0, x5 = 24.0, x6 = 32.0;
  static const screenPadding = 18.0;
  static const minTouchTarget = 44.0;
}

/// Fonte nativa do sistema — não empacotar webfont no app.
ThemeData bandFmTheme() {
  const base = TextStyle(color: BandFMColors.textPrimary, letterSpacing: -0.15);
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BandFMColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: BandFMColors.orange,
      onPrimary: BandFMColors.textOnBrand,
      surface: BandFMColors.surface,
      error: BandFMColors.live,
    ),
    textTheme: TextTheme(
      displayLarge: base.copyWith(fontSize: 30, fontWeight: FontWeight.w800, height: 1.1),
      headlineMedium: base.copyWith(fontSize: 25, fontWeight: FontWeight.w800, height: 1.15),
      titleLarge: base.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
      titleMedium: base.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
      titleSmall: base.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      bodyLarge: base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w400, height: 1.4),
      bodySmall: base.copyWith(fontSize: 12.5, color: BandFMColors.textTertiary),
      labelSmall: base.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.32),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BandFMColors.orange,
        foregroundColor: BandFMColors.textOnBrand,
        minimumSize: const Size.fromHeight(52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
  );
}
