import 'package:flutter/foundation.dart';

/// O que esta pessoa já respondeu, nesta sessão.
///
/// **Por que isto existe.**
///
/// A resposta a um Momento pode sair de três lugares: o cartão no No Ar, o cartão na
/// aba Momentos, e a faixa que aparece por cima do mini-player em qualquer outra tela.
/// As três telas ficam montadas ao mesmo tempo dentro do `IndexedStack` — elas não são
/// destruídas ao trocar de aba, e por isso não recarregam nada quando voltam.
///
/// O resultado, antes disto: a pessoa respondia pela faixa enquanto lia o chat, voltava
/// para o No Ar e encontrava a mesma pergunta em aberto, convidando a votar de novo. O
/// servidor recusaria o voto repetido, mas o estrago já estava feito — o app tinha
/// esquecido o que ela acabou de fazer.
///
/// Um registro em memória resolve sem uma requisição a mais: quem responde marca aqui,
/// e todas as telas escutam. O servidor continua sendo a verdade — é dele que vem o
/// `respondi` quando o app abre —, mas dentro da sessão a propagação é imediata.
///
/// Não persiste em disco de propósito: reabrir o app e reconsultar o servidor é o
/// comportamento certo, porque a pessoa pode ter votado de outro aparelho.
class RegistroDeRespostas extends ChangeNotifier {
  RegistroDeRespostas._();
  static final instancia = RegistroDeRespostas._();

  final _porMomento = <String, String?>{};

  bool respondeu(String? momentoId) =>
      momentoId != null && _porMomento.containsKey(momentoId);

  String? opcaoDe(String? momentoId) =>
      momentoId == null ? null : _porMomento[momentoId];

  /// `opcaoId` pode ser nulo: há Momentos de reação simples, sem opção escolhida.
  void marcar(String momentoId, String? opcaoId) {
    if (_porMomento.containsKey(momentoId) && _porMomento[momentoId] == opcaoId) return;
    _porMomento[momentoId] = opcaoId;
    notifyListeners();
  }

  /// Usado quando o servidor conta que a pessoa já tinha respondido antes de abrir o
  /// app — a informação vale tanto quanto a de um toque agora.
  void marcarVindoDoServidor(String momentoId, String? opcaoId) => marcar(momentoId, opcaoId);
}
