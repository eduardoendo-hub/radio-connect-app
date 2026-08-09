/// Datas que vêm do servidor, do jeito que a rádio fala.
///
/// **Toda data chega em UTC.** O servidor manda ISO-8601 com `Z` — `2026-08-13T18:00Z`
/// é o sorteio das 15h de Brasília. `DateTime.parse` devolve esse instante ainda em
/// UTC, e `.hour` nele responde 18. O aplicativo mostrava três horas adiantado em todo
/// lugar: "A seguir, 12h00" para um programa das 9h, "sorteio quinta às 18h" para um
/// sorteio das 15h.
///
/// O erro não aparece em conta de diferença — `fimEm.difference(agora)` está certo em
/// qualquer fuso, e é por isso que a contagem do Momento e do Fofocômetro sempre
/// funcionaram e ninguém percebeu. Ele só aparece quando alguém lê o relógio.
///
/// Por isso a conversão mora aqui e não espalhada: quem for mostrar hora usa estas
/// funções, e não tem como esquecer o `toLocal()`.
library;

/// O instante, no fuso de quem está olhando. `null` entra, `null` sai.
DateTime? instante(Object? iso) {
  final t = DateTime.tryParse(iso?.toString() ?? '');
  return t?.toLocal();
}

/// "09h00" — o formato que a grade da rádio usa.
String horaCheia(DateTime? d) => d == null
    ? ''
    : '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';

const _dias = ['segunda', 'terça', 'quarta', 'quinta', 'sexta', 'sábado', 'domingo'];

/// "hoje às 15h", "quinta às 15h30".
///
/// Nome do dia e não data: é assim que o locutor fala no ar, e quem ouve não precisa
/// converter nada de cabeça. Passada uma semana o dia da semana deixaria de ser
/// suficiente — mas promoção com sorteio a mais de sete dias não é promoção de rádio.
String quando(DateTime? d) {
  if (d == null) return '';
  final agora = DateTime.now();
  final hora = d.minute == 0 ? '${d.hour}h' : '${d.hour}h${d.minute.toString().padLeft(2, '0')}';
  final mesmoDia = d.year == agora.year && d.month == agora.month && d.day == agora.day;
  return mesmoDia ? 'hoje às $hora' : '${_dias[d.weekday - 1]} às $hora';
}
