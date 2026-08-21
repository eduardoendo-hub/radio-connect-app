import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';

/// O Estado No Ar do lado do app.
///
/// Mantém a última foto conhecida da emissora e a mantém atualizada. Guarda o ETag: se
/// nada mudou, o servidor responde 304 e não transfere corpo nenhum — importa em rede
/// móvel ruim, onde a maior parte das consultas passa a não custar byte de dados.
///
/// NOTA DA DEMONSTRAÇÃO: aqui a atualização é por consulta curta. O servidor já expõe
/// SSE em `/no-ar/stream`, que é o desenho definitivo — uma conexão de mão única, com
/// muito menos bateria e sem repetir requisição. A troca é local a esta classe.
class EstadoNoAr extends ChangeNotifier {
  Map<String, dynamic>? _estado;
  String? _etag;
  Timer? _timer;
  bool _semRede = false;

  Map<String, dynamic>? get estado => _estado;
  bool get semRede => _semRede;

  bool get aoVivo => _estado?['aoVivo'] == true;
  /// O nome da rádio, como ela se chama.
  ///
  /// **Estava escrito "Band FM" em treze lugares do aplicativo.** O produto é
  /// white-label e o servidor sempre mandou este nome no Estado No Ar — o aplicativo é
  /// que não olhava. Numa emissora nova, cada uma daquelas telas diria o nome da rádio
  /// errada, e é o tipo de defeito que ninguém percebe até estar na frente do cliente.
  ///
  /// É `static` porque a alternativa era passar o nome por sete níveis de widget só para
  /// escrever um título. Enquanto a primeira resposta não chega, o valor é vazio e cada
  /// tela decide o que dizer no lugar — nunca o nome de outra rádio.
  static String nome = '';

  Map<String, dynamic>? get programa => _estado?['programa'] as Map<String, dynamic>?;
  Map<String, dynamic>? get locutor => _estado?['locutor'] as Map<String, dynamic>?;
  Map<String, dynamic>? get momento => _estado?['momento'] as Map<String, dynamic>?;
  Map<String, dynamic>? get promocao => _estado?['promocao'] as Map<String, dynamic>?;
  Map<String, dynamic>? get proxima => _estado?['proxima'] as Map<String, dynamic>?;
  /// Metadado da música vem do stream quando existe; no MVP pode ser nulo, e a tela
  /// cai para o nome da emissora sem parecer quebrada.
  Map<String, dynamic>? get musica => _estado?['now_playing'] as Map<String, dynamic>?;
  int get ouvintes => (_estado?['ouvintes'] as num?)?.toInt() ?? 0;

  Future<void> iniciar() async {
    await atualizar();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => atualizar());
  }

  Future<void> atualizar() async {
    try {
      final r = await Api.obter('/no-ar', etag: _etag);
      // Voltar a ter rede também é mudança de estado: precisa avisar a interface,
      // senão o aviso de "sem conexão" fica preso na tela mesmo já reconectado.
      final voltouARede = _semRede;
      _semRede = false;
      if (r['_naoMudou'] == true) {
        if (voltouARede) notifyListeners();
        return;
      }
      _estado = r;
      final daRadio = (r['emissora'] as Map?)?['nome']?.toString();
      if (daRadio != null && daRadio.isNotEmpty) nome = daRadio;
      _etag = 'W/"${r['versao']}"';
      notifyListeners();
    } on ErroApi catch (e) {
      if (e.status == 401) rethrow;
      _marcarSemRede();
    } catch (_) {
      _marcarSemRede();
    }
  }

  /// Perder a rede não pode virar tela branca. O app segue mostrando a última foto
  /// conhecida, com um aviso discreto — e o player continua tocando.
  void _marcarSemRede() {
    if (!_semRede) {
      _semRede = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
